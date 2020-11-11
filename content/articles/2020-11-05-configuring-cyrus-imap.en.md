---
title: "Configuring Cyrus IMAP"
date: 2020-11-05
---

I decided to install Cyrus IMAP on a server and create a terraform recipe for
automatic configuration management for this installation. My goal is to have an
easily maintainable mail server, and I choose Cyrus IMAP because it is pioneer
in many modern features such as JMAP. It's quite feature complete too.

The problem I got was user management. I don't plan to use Docker but I wanted
to be able to have a web interface for user management, without sharing a db
file on the disk (what if the user management and cyrus are on different
servers?) or share a database schema (what if I want to change the database
schema, should I modify the complete infrastructure because of it. What if I
change the database provider?).

Cyrus IMAP relies on Cyrus SASL for user management. It works with two different
options:

- auxprops, built-in with Cyrus SASL or pluggable using a shared library (`.so`)
- authdaemon, externalized to a separate process but without much more choices
  of providers and only supporting logins with plain password (no hashing
  possible)

And with auxprops, without writing a plugin, the choice is quite limited:

- LDAP server
- NTLM, a Windows thing
- OTP, I suppose one time passwords, not suitable for standard passwords
- specific database file, not suitable for a networked infrastructure
- SQL, not suitable if we want to keep the database schema private or if we
  prefer SQLite (problem in a networked environment)
- Kerebos, also a very specific authentication method

After quite some thought, I decided to go with LDAP. It's quite a complex beast
but there are alternative to OpenLDAP. In particular, I found [glauth] that
provides a minimal LDAP server written in Go just for authentication. If needed,
it will be easily extensible to allow authenticating with extra sources.

Now, the question is how to configure Cyrus to work with glauth....

Step 1: Make Cyrus work and get some logs
-----------------------------------------

To make things worse, I decided to use configuration file in a non standard
location, to avoid messing with the distribution packages that I otherwise use
(so I can get security updates easily). My configuration files are in
`/etc/cyrus/cyrus.conf` and `/etc/cyrus/imapd.conf` instead of `/etc/cyrus.conf`
and `/etc/imapd.conf`.

Cyrus works by having a master process (configured with the `cyrus.conf` file)
that handle listening to sockets and spawning separate daemons for each
protocol. The first problem was that the daemons were taking the configuration
in `/etc/imapd.conf` instead of `/etc/cyrus/imapd.conf` and I was not able to
get extra logging.

The solution is to specify the configuration file location in `cyrus.conf` for
each and every daemon using the `-C` option 9that is otherwise missing from that
file):

```
START {
	# do not delete this entry!
	recover		cmd="/usr/sbin/cyrus ctl_cyrusdb -C /etc/cyrus/imapd.conf -r"
	...
}

SERVICES {
	imap		cmd="imapd -C /etc/cyrus/imapd.conf -U 30" listen="imap" prefork=0 maxchild=1
	...
}

EVENTS {
	# this is required
	checkpoint	cmd="/usr/sbin/cyrus ctl_cyrusdb -C /etc/cyrus/imapd.conf -c" period=30
	...
}
```

I also modified the `maxchild=` option from 100 to 1 for `imapd` for easier
process tracing, we'll see that later on.

I also enable debug logging in `/etc/cyrus/imapd.conf`:

```
debug: 1

# SASL_LOG_NONE  0 don't log anything
# SASL_LOG_ERR   1 log unusual errors (default)
# SASL_LOG_FAIL  2 log all authentication failures
# SASL_LOG_WARN  3 log non-fatal warnings
# SASL_LOG_NOTE  4 more verbose than LOG_WARN
# SASL_LOG_DEBUG 5 more verbose than LOG_NOTE
# SASL_LOG_TRACE 6 traces of internal protocols
# SASL_LOG_PASS  7 traces of internal protocols, including passwords
sasl_log_level: 7
```

Step 2: basic configuration and authentication testing
------------------------------------------------------

In `imapd.conf` I also configured the basic settings for authentication:

```
allowplaintext: yes
sasl_pwcheck_method: auxprop
sasl_auto_transition: yes
sasl_auxprop_plugin: ldapdb
```

And started testing with the following command on the server:

```
cyrus imtest -u jdoe@example.com -w dogood
```

I enabled the logs on cyrus and glauth and plan to improve on to get something
working. For now, I get the following logs from Cyrus:

```
cyrus/master[12535]: about to exec /usr/lib/cyrus/bin/imapd
cyrus/imap[12535]: executed
cyrus/imap[12535]: ldapdb
cyrus/imap[12535]: _sasl_plugin_load failed on sasl_canonuser_init
cyrus/imap[12535]: auxpropfunc error invalid parameter supplied
cyrus/imap[12535]: _sasl_plugin_load failed on sasl_auxprop_plug_init
cyrus/imap[12535]: ldapdb
cyrus/imap[12535]: _sasl_plugin_load failed on sasl_canonuser_init
cyrus/imap[12535]: accepted connection
cyrus/imap[12535]: SASL DIGEST-MD5 server step 1
cyrus/imap[12535]: SASL DIGEST-MD5 server step 2
cyrus/imap[12535]: SASL could not find auxprop plugin, was searching for 'ldapdb
cyrus/imap[12535]: SASL unable to canonify user and get auxprops"+y
cyrus/imap[12535]: SASL DIGEST-MD5 common mech dispose
cyrus/imap[12535]: badlogin: localhost [::1] DIGEST-MD5 [SASL(-4): no mechanism available: unable to canonify user and get auxprops]
```

I don't get what does not work, the error messages are not very specific. Let's
debug this...

Step 3: Debug the whole thing and understand what's missing
-----------------------------------------------------------

`ltrace` or `strace` did not help very much, so I resolved to debug with gdb. I
[installed the debug packages][debug] `libsasl2-2-dbgsym`,
`libsasl2-modules-dbgsym`, `libsasl2-modules-db-dbgsym` and
`libsasl2-modules-ldap-dbgsym` and started gdb:

    gdb -p $(pidof master)
    ...
    (gdb) set follow-fork-mode child

I found that the message `_sasl_plugin_load failed on sasl_auxprop_plug_init`
came from the function `sasl_canonuser_add_plugin`, so I set a breakpoint on it:

    (gdb) break sasl_canonuser_add_plugin
    Function "sasl_canonuser_add_plugin" not defined.
    Make breakpoint pending on future shared library load? (y or [n]) y
    Breakpoint 1 (sasl_canonuser_add_plugin) pending.
    (gdb) c

Now, gdb is ready to catch the issue, I started `cyrus imtest` as above and got
to debug it:

    Thread 2.1 "imapd" hit Breakpoint 1, sasl_canonuser_add_plugin (plugname=plugname@entry=0x7f6bc4a231cd "INTERNAL", 
        canonuserfunc=0x7f6bc4a139e0 <internal_canonuser_init>) at ../../lib/canonusr.c:308
    308	../../lib/canonusr.c: No such file or directory.
    (gdb) c

This first breakpoint was for a plugin named `"INTERNAL"`, not my problem so I
continued...

    Thread 2.1 "imapd" hit Breakpoint 1, sasl_canonuser_add_plugin (plugname=plugname@entry=0x7ffd87fed980 "ldapdb", canonuserfunc=0x7f6bc16b7450 <sasl_canonuser_init>)
        at ../../lib/canonusr.c:308
    308	in ../../lib/canonusr.c

There, my plugin... The `disas` command will get you the disassembled code for
that function. I didn't know I knew how to read assembler code but that's not so
hard to understand:

```
=> 0x00007f6bc4a13870 <+0>:	push   %r12
   0x00007f6bc4a13872 <+2>:	push   %rbp
   0x00007f6bc4a13873 <+3>:	push   %rbx
   0x00007f6bc4a13874 <+4>:	sub    $0x20,%rsp
   0x00007f6bc4a13878 <+8>:	mov    %fs:0x28,%rax
   0x00007f6bc4a13881 <+17>:	mov    %rax,0x18(%rsp)
   0x00007f6bc4a13886 <+22>:	xor    %eax,%eax
   0x00007f6bc4a13888 <+24>:	test   %rdi,%rdi
   0x00007f6bc4a1388b <+27>:	je     0x7f6bc4a139a8 <sasl_canonuser_add_plugin+312>
   0x00007f6bc4a13891 <+33>:	mov    %rdi,%rbx
   0x00007f6bc4a13894 <+36>:	mov    %rsi,%rbp
   0x00007f6bc4a13897 <+39>:	callq  0x7f6bc4a11130 <strlen@plt>
   0x00007f6bc4a1389c <+44>:	cmp    $0xfff,%rax
   0x00007f6bc4a138a2 <+50>:	ja     0x7f6bc4a139a8 <sasl_canonuser_add_plugin+312>
   0x00007f6bc4a138a8 <+56>:	mov    0x16689(%rip),%rax        # 0x7f6bc4a29f38
   0x00007f6bc4a138af <+63>:	lea    0x10(%rsp),%rcx
   0x00007f6bc4a138b4 <+68>:	lea    0xc(%rsp),%rdx
   0x00007f6bc4a138b9 <+73>:	mov    %rbx,%r8
   0x00007f6bc4a138bc <+76>:	mov    $0x5,%esi
   0x00007f6bc4a138c1 <+81>:	mov    (%rax),%rdi
   0x00007f6bc4a138c4 <+84>:	callq  *%rbp
   0x00007f6bc4a138c6 <+86>:	mov    %eax,%r12d
   0x00007f6bc4a138c9 <+89>:	test   %eax,%eax
   0x00007f6bc4a138cb <+91>:	jne    0x7f6bc4a13988 <sasl_canonuser_add_plugin+280>
```

The equivalent C code on GitHub to better understand what it means:

```c
int sasl_canonuser_add_plugin(const char *plugname,
			      sasl_canonuser_init_t *canonuserfunc) 
{
    int result, out_version;
    canonuser_plug_list_t *new_item;
    sasl_canonuser_plug_t *plug;

    if(!plugname || strlen(plugname) > (PATH_MAX - 1)) {
	sasl_seterror(NULL, 0,
		      "bad plugname passed to sasl_canonuser_add_plugin\n");
	return SASL_BADPARAM;
    }
    
    result = canonuserfunc(sasl_global_utils, SASL_CANONUSER_PLUG_VERSION,
			   &out_version, &plug, plugname);

    if(result != SASL_OK) {
	_sasl_log(NULL, SASL_LOG_ERR, "%s_canonuser_plug_init() failed in sasl_canonuser_add_plugin(): %z\n",
		  plugname, result);
	return result;
    }
    ...
}
```

Using `nexti` to jump each time to the next instruction, I found that the issue
was the `canonuserfunc` returned an error. I had jumped too far so I resumed a
new debug session and this time, I jumped into the indirect call `callq  *%rbp`
using `stepi` a few times to get to the plugin function. Dynamic loading the
plugin generates a few trampoline functions that I had to stop through.

I got into the `ldapdb_canonuser_plug_init` function:

    (gdb) si
    ldapdb_canonuser_plug_init (utils=0x55adbb27ef50, max_version=5, out_version=0x7ffd87fec8dc, plug=0x7ffd87fec8e0, plugname=0x7ffd87fed980 "ldapdb")
        at ../../plugins/ldapdb.c:565
    565	../../plugins/ldapdb.c: No such file or directory.
    (gdb) disas
    Dump of assembler code for function ldapdb_canonuser_plug_init:
    => 0x00007f6bc16b73e0 <+0>:	test   %rdx,%rdx
       0x00007f6bc16b73e3 <+3>:	je     0x7f6bc16b7430 <ldapdb_canonuser_plug_init+80>
       0x00007f6bc16b73e5 <+5>:	test   %rcx,%rcx
       0x00007f6bc16b73e8 <+8>:	je     0x7f6bc16b7430 <ldapdb_canonuser_plug_init+80>
       0x00007f6bc16b73ea <+10>:	cmp    $0x4,%esi
       0x00007f6bc16b73ed <+13>:	jle    0x7f6bc16b7420 <ldapdb_canonuser_plug_init+64>
       0x00007f6bc16b73ef <+15>:	push   %rbp
       0x00007f6bc16b73f0 <+16>:	mov    %rcx,%rbp
       0x00007f6bc16b73f3 <+19>:	push   %rbx
       0x00007f6bc16b73f4 <+20>:	mov    %rdx,%rbx
       0x00007f6bc16b73f7 <+23>:	sub    $0x8,%rsp
       0x00007f6bc16b73fb <+27>:	callq  0x7f6bc16b6d00 <ldapdb_config>
       0x00007f6bc16b7400 <+32>:	movl   $0x5,(%rbx)
       0x00007f6bc16b7406 <+38>:	lea    0x3c13(%rip),%rbx        # 0x7f6bc16bb020 <ldapdb_canonuser_plugin>
       0x00007f6bc16b740d <+45>:	mov    %rbx,0x0(%rbp)
       0x00007f6bc16b7411 <+49>:	add    $0x8,%rsp
       0x00007f6bc16b7415 <+53>:	pop    %rbx
       0x00007f6bc16b7416 <+54>:	pop    %rbp
       0x00007f6bc16b7417 <+55>:	retq   
       0x00007f6bc16b7418 <+56>:	nopl   0x0(%rax,%rax,1)
       0x00007f6bc16b7420 <+64>:	mov    $0xffffffe9,%eax
       0x00007f6bc16b7425 <+69>:	retq   
       0x00007f6bc16b7426 <+70>:	nopw   %cs:0x0(%rax,%rax,1)
       0x00007f6bc16b7430 <+80>:	mov    $0xfffffff9,%eax
       0x00007f6bc16b7435 <+85>:	retq   
    End of assembler dump.
    (gdb) bt
    #0  ldapdb_canonuser_plug_init (utils=0x55adbb27ef50, max_version=5, out_version=0x7ffd87fec8dc, plug=0x7ffd87fec8e0, plugname=0x7ffd87fed980 "ldapdb")
        at ../../plugins/ldapdb.c:565
    #1  0x00007f6bc4a138c6 in sasl_canonuser_add_plugin (plugname=plugname@entry=0x7ffd87fed980 "ldapdb", canonuserfunc=0x7f6bc16b7450 <sasl_canonuser_init>)
        at ../../lib/canonusr.c:319
    ...

The equivalent C code:

```c
int ldapdb_canonuser_plug_init(const sasl_utils_t *utils,
                             int max_version,
                             int *out_version,
                             sasl_canonuser_plug_t **plug,
                             const char *plugname __attribute__((unused))) 
{
    int rc;

    if(!out_version || !plug) return SASL_BADPARAM;

    if(max_version < SASL_CANONUSER_PLUG_VERSION) return SASL_BADVERS;
    
    rc = ldapdb_config(utils);

    *out_version = SASL_CANONUSER_PLUG_VERSION;

    *plug = &ldapdb_canonuser_plugin;

    return rc;
}
```

Here, the problem is with `ldapdb_config(utils)` that returns an error.
Continuing into that function, I got the following code:

```c
    utils->getopt(utils->getopt_context, ldapdb, "ldapdb_uri", &p->uri, NULL);
    if(!p->uri) return SASL_BADPARAM;
```

I had forgotten the `ldapdb_uri` configuration parameter (of course, I'm just
testing and I had disabled the line in hope to get a meaningful error).

Step 4: Basic SASL configuration
--------------------------------

Let's configure it in `imapd.conf` using random values from the
[documentation](http://www.cyrusimap.org/sasl/sasl/options.html#examples):

```
allowplaintext: yes
sasl_pwcheck_method: auxprop
sasl_auto_transition: yes
sasl_auxprop_plugin: ldapdb

sasl_ldapdb_uri: ldap://glauth/dc=users,dc=local/
sasl_ldapdb_id: cyrus
sasl_ldapdb_pw: cyrus
sasl_ldapdb_mech: PLAIN
sasl_ldapdb_canon_attr: mail
```

It should work because I have the following request that is working:

    $ ldapsearch -h glauth -p 3893 -D cn=cyrus,ou=machines,dc=users,dc=local -b dc=users,dc=local -w cyrus mail=jdoe@example.com

    dn: cn=johndoe,ou=superheros,dc=users,dc=local
    # ...
    # numResponses: 2
    # numEntries: 1

Note the use of the `sasl_ldabdb_` option prefix instead of just `ldap_` as
appears in the `imapd.conf` man page. `sasl_*` options are all passed verbatim
to Cyrus SASL.

I got a little further, but there is still work to do. No more errors from the
plugin though:

```
cyrus/master[13555]: about to exec /usr/lib/cyrus/bin/imapd
cyrus/imap[13555]: executed
cyrus/imap[13555]: accepted connection
cyrus/imap[13555]: SASL DIGEST-MD5 server step 1
cyrus/imap[13555]: SASL DIGEST-MD5 server step 2
cyrus/imap[13555]: SASL unable to canonify user and get auxprops
cyrus/imap[13555]: SASL DIGEST-MD5 common mech dispose
cyrus/imap[13555]: badlogin: localhost [::1] DIGEST-MD5 [SASL(-1): generic failure: unable to canonify user and get auxprops]
```

Step 5: More debugging
----------------------

Let's enable back `maxprocs=1` in `cyrus.conf` and restart the master process.

    # gdb -p $(pidof master) -ex 'set follow-fork-mode child'
    (gdb) break ldapdb_canonuser_plug_init
    (gdb) c
    ...
    (gdb) si
    ...
    (gdb) ni
    475	in ../../plugins/ldapdb.c
    (gdb) print p->uri
    $1 = 0x558a24684ce0 "ldap://glauth/dc=users,dc=local/"

No problem with the configuration this time... Let's break somewhere else.

    (gdb) break ldapdb_canon_client
    Breakpoint 2 at 0x7ff322b66f40: ldapdb_canon_client. (2 locations)
    (gdb) break ldapdb_canon_server
    Breakpoint 3 at 0x7ff322b67010: ldapdb_canon_server. (2 locations)
    (gdb) c

No match... let's try:

    (gdb) break ldapdb_connect
    ...
    Thread 2.1 "imapd" hit Breakpoint 1, ldapdb_connect (ctx=ctx@entry=0x7f08784ba0e0 <ldapdb_ctx>, user=user@entry=0x565338fa59e1 "root", ulen=ulen@entry=4, 
        cp=cp@entry=0x7ffdb182ea80, sparams=<optimized out>) at ../../plugins/ldapdb.c:81
    81	../../plugins/ldapdb.c: No such file or directory.
    (gdb) print ctx->uri
    $1 = 0x565338f9cce0 "ldap://glauth/dc=users,dc=local/"
    (gdb) print cp->ld
    $2 = (LDAP *) 0x0

Got it, the code:

```c
static int ldapdb_connect(ldapctx *ctx, sasl_server_params_t *sparams,
	const char *user, unsigned ulen, connparm *cp)
{
    int i, rc;
    char *authzid;

    if((i=ldap_initialize(&cp->ld, ctx->uri))) {
	cp->ld = NULL;
	return i;
    }
```

And we have `ldap_initialize` that returns with `-9`, that's `LDAP_PARAM_ERROR`
as shown in [`ldap.h`](https://github.com/delphij/openldap/blob/master/include/ldap.h#L713).
Ok, the URI I specified is not correct...

After getting [some more doc](https://libldap.readthedocs.io/en/latest/libldap.html#libldap.ldap_initialize),
I rewrite the `imapd.conf` options to:

```
sasl_ldapdb_uri: ldap://glauth/dc=users,dc=local
sasl_ldapdb_id: cn=cyrus,ou=machines
sasl_ldapdb_pw: cyrus
sasl_ldapdb_mech: PLAIN
sasl_ldapdb_canon_attr: mail
```

What prompted me to change the `sasl_ldapdb_id` is the documentation:

> LDAP URI (Uniform Resource Identifier). It has the following form:
> `ldap[is]://host[:port][/dn]`. This parameter is identical to that of the
> underlying function ldap_initialize() of the library openLDAP except the
> optional dn. When this dn is provided, each parameter of a method of an
> instance of a LDAPObject which is a DN, is automatically completed by dn
> unless it already ends with dn. For example, in the code below:
>
>     >>> l = ldap_initialize('ldap:://host.test/dc=example,dc=test')
>     >>> l.simple_bind_s(user='cn=admin', password='secret')
>
> parameter user is rewritten to ‘`cn=admin,dc=example,dc=test`’ before passed
> to the underlying OpenLDAP library C function

No more luck, I get the exact same `LDAP_PARAM_ERROR`.

Let's dig into ldap itself...

    (gdb) break ldap_initialize
        Thread 2.1 "imapd" hit Breakpoint 1, ldap_initialize (ldp=ldp@entry=0x7ffe3566d780, url=0x558ea5417c30 "ldap://glauth/dc=users,dc=local") at open.c:235
    235	open.c: No such file or directory.

In [`ldap_initialize`](https://github.com/openldap/openldap/blob/OPENLDAP_REL_ENG_2_4_47/libraries/libldap/open.c#L235)
its's `ldap_set_option` that returns the error. In this function there is this
interesting piece of code:

```c
			case LDAP_URL_ERR_PARAM:	/* parameter is bad */
			case LDAP_URL_ERR_BADSCHEME:	/* URL doesn't begin with "ldap[si]://" */
			case LDAP_URL_ERR_BADENCLOSURE:	/* URL is missing trailing ">" */
			case LDAP_URL_ERR_BADURL:	/* URL is bad */
			case LDAP_URL_ERR_BADHOST:	/* host port is bad */
			case LDAP_URL_ERR_BADATTRS:	/* bad (or missing) attributes */
			case LDAP_URL_ERR_BADSCOPE:	/* scope string is invalid (or missing) */
			case LDAP_URL_ERR_BADFILTER:	/* bad or missing filter */
			case LDAP_URL_ERR_BADEXTS:	/* bad or missing extensions */
				rc = LDAP_PARAM_ERROR;
				break;
```

But before that, in `ldap_url_parselist_int`, we can see that the single url is
parsed into a list of two URLs:

    Thread 2.1 "imapd" hit Breakpoint 3, ldap_url_parselist_int (ludlist=ludlist@entry=0x7ffe3566d660, url=url@entry=0x558ea5417c30 "ldap://glauth/dc=users,dc=local", 
        sep=sep@entry=0x0, flags=flags@entry=3) at url.c:1279

    (gdb) print urls[0]
    $5 = 0x558ea542e280 "ldap://glauth/dc=users"
    (gdb) print urls[1]
    $6 = 0x558ea542e1c0 "dc=local"

This time, let's try and escape the comma in the URL in `imapd.conf`:

```
sasl_ldapdb_uri: ldap://glauth/dc=users%44dc=local
sasl_ldapdb_id: cn=cyrus,ou=machines
sasl_ldapdb_pw: cyrus
sasl_ldapdb_mech: PLAIN
sasl_ldapdb_canon_attr: mail
```

This time, `ldap_url_parselist_int` and `ldapdb_connect` succeeds... Back to
Cyrus SASL.

In `ldapdb_connect`, the function still returns with `-1` (where 0 is probably
the success code) because of `ldap_sasl_interactive_bind_s`. I needed to get the
debian version of
[`cyrus.c`](https://sources.debian.org/src/openldap/2.4.47+dfsg-3+deb10u3/libraries/libldap/cyrus.c/#L358)
to get the correct line numbers.

```c
		if ( sd == AC_SOCKET_INVALID || !ld->ld_defconn ) {
			/* not connected yet */

			rc = ldap_open_defconn( ld );

			if ( rc == 0 ) {
```

`ldap_open_defconn` returned `rc` with `-1`.

To get more debug messages, I manually changed the log level with gdb:

    (gdb) print (&ldap_int_global_options)->ldo_debug
    $16 = 255
    (gdb) set var (&ldap_int_global_options)->ldo_debug = 0xFFFFFFFF
    (gdb) print (&ldap_int_global_options)->ldo_debug
    $17 = -1

And I got a lot of log messages with the `imtest` program:

```
S: ldap_create
base64 decoding error
Authentication failed. generic failure
Security strength factor: 128
C: C01 CAPABILITY
S: ldap_url_parse_ext(ldap://glauth/dc=users%44dc=local)
S: ldap_sasl_interactive_bind: user selected: PLAIN
S: ldap_int_sasl_bind: PLAIN
S: ldap_new_connection 1 1 0
S: ldap_int_open_connection
S: ldap_connect_to_host: TCP glauth:389
S: ldap_new_socket: 15
S: ldap_prepare_socket: 15
S: ldap_connect_to_host: Trying fd5c:4791:2773:2b8:8000::2 389
S: ldap_pvt_connect: fd: 15 tm: -1 async: 0
S: attempting to connect: 
S: connect errno: 111
S: ldap_close_socket: 15
S: ldap_new_socket: 15
S: ldap_prepare_socket: 15
S: ldap_connect_to_host: Trying 127.0.0.2:389
S: ldap_pvt_connect: fd: 15 tm: -1 async: 0
S: attempting to connect: 
S: connect errno: 111
S: ldap_close_socket: 15
S: ldap_msgfree
S: A01 NO remote authentication server unavailable
```

glauth is not listening on port 389 but on port 3893. This time I found a way to
get way more info. For the meantime, let's change the LDAP port number on the
configuration.

Step 6: Failing to make Cyrus authenticate to glauth LDAP server
----------------------------------------------------------------

This time, the error log on the server is:

```
Nov 05 14:51:19 vps-e7887199 cyrus/master[16395]: about to exec /usr/lib/cyrus/bin/imapd
Nov 05 14:51:19 vps-e7887199 cyrus/imap[16395]: executed
Nov 05 14:51:19 vps-e7887199 cyrus/imap[16395]: accepted connection
Nov 05 14:51:19 vps-e7887199 cyrus/imap[16395]: SASL DIGEST-MD5 server step 1
Nov 05 14:51:19 vps-e7887199 cyrus/imap[16395]: SASL DIGEST-MD5 server step 2
Nov 05 14:51:19 vps-e7887199 cyrus/imap[16395]: SASL No worthy mechs found
Nov 05 14:51:19 vps-e7887199 cyrus/imap[16395]: SASL unable to canonify user and get auxprops
Nov 05 14:51:19 vps-e7887199 cyrus/imap[16395]: SASL DIGEST-MD5 common mech dispose
Nov 05 14:51:19 vps-e7887199 cyrus/imap[16395]: badlogin: localhost [::1] DIGEST-MD5 [SASL(-1): generic failure: unable to canonify user and get auxprops]
```

After restarting cyrus, I start gdb, run a test (`imtest`), Ctrl-C to break gdb
and update log level:

    # gdb -p $(pidof master) -ex 'set follow-fork-mode child'
    (gdb) c

    ...

    Thread 2.1 "imapd" received signal SIGINT, Interrupt.
    (gdb) set var (&ldap_int_global_options)->ldo_debug = -1
    (gdb) print (&ldap_int_global_options)->ldo_debug
    $1 = -1
    (gdb) c

The logs from OpenLDAP:

```
S: ldap_url_parse_ext(ldap://glauth:3893/dc=users%44dc=local)
S: ldap_sasl_interactive_bind: user selected: PLAIN
S: ldap_int_sasl_bind: PLAIN
S: ldap_new_connection 1 1 0
S: ldap_int_open_connection
S: ldap_connect_to_host: TCP glauth:3893
S: ldap_new_socket: 15
S: ldap_prepare_socket: 15
S: ldap_connect_to_host: Trying fd5c:4791:2773:2b8:8000::2 3893
S: ldap_pvt_connect: fd: 15 tm: -1 async: 0
S: attempting to connect: 
S: connect errno: 111
S: ldap_close_socket: 15
S: ldap_new_socket: 15
S: ldap_prepare_socket: 15
S: ldap_connect_to_host: Trying 127.0.0.2:3893
S: ldap_pvt_connect: fd: 15 tm: -1 async: 0
S: attempting to connect: 
S: connect success
S: ldap_int_sasl_open: host=glauth
S: ldap_msgfree
S: ldap_free_connection 1 1
S: ldap_send_unbind
S: ldap_free_connection: actually freed
S: A01 NO generic failure
```

Trying to decode the LDAP protocol with `tcpdump -nvvv -i lo 'port 3893'` but
protocol decode is not powerful enough to understand what's going on. Nothing
seems bad on the LDAP client side, the only error to continue debugging is:

> SASL No worthy mechs found

Could it be Cyrus that fails to authenticate to glauth because there is no
matching login mechanism ? let's try removing the `sasl_ldapdb_mech: PLAIN`
configuration line...

This time, glauth is outputting some more information (the force-bind lines
below):

```
cyrus/master[17012]: about to exec /usr/lib/cyrus/bin/imapd
cyrus/imap[17012]: executed
cyrus/imap[17012]: accepted connection
cyrus/imap[17012]: SASL DIGEST-MD5 server step 1
cyrus/imap[17012]: SASL DIGEST-MD5 server step 2
force-bind[12757]: 15:09:13.295780 Search ▶ DEBU 014 Search request as  from 127.0.0.1:56398 for (objectclass=*)
force-bind[12757]: 2020/11/05 15:09:13 handleSearchRequest error LDAP Result Code 50 "Insufficient Access Rights": Search Error: Anonymous BindDN not allowed
cyrus/imap[17012]: SASL unable to canonify user and get auxprops
cyrus/imap[17012]: SASL DIGEST-MD5 common mech dispose
cyrus/imap[17012]: badlogin: localhost [::1] DIGEST-MD5 [SASL(-13): authentication failure: unable to canonify user and get auxprops]
```

This time, the request makes its way to glauth. The message `Search Error:
Anonymous BindDN not allowed` signifies that the bind request was made with an
empty bind dn (`-D` option in `ldapsearch`). In our case, the bind dn should be
`dc=users,dc=local` and we have to configure Cyrus SASL to this.

Reading [on the topic on
ServerFault](https://serverfault.com/questions/616698/in-ldap-what-exactly-is-a-bind-dn)
I could grab that the bind dn was sort of like your user id and it should not be
empty.

I discovered that the bind dn was always empty on Cyrus SASL in [`ldabdb.c`](https://github.com/cyrusimap/cyrus-sasl/blob/cyrus-sasl-2.1.27/plugins/ldapdb.c#L117):

```c
    i = ldap_sasl_interactive_bind_s(cp->ld, NULL, ctx->mech.bv_val, NULL,
    	NULL, LDAP_SASL_QUIET, ldapdb_interact, ctx);
    if (i != LDAP_SUCCESS) {
    	sparams->utils->free(authzid);
	return i;
    }
```

The second parameter set to `NULL` is the bind db as evidenced [elsewhere in the
code](https://github.com/cyrusimap/cyrus-sasl/blob/cyrus-sasl-2.1.27/saslauthd/lak.c#L1081-L1089).
The solution is to either [change Cyrus SASL to allow the bind dn to be
configurable](https://github.com/cyrusimap/cyrus-sasl/issues/629) or [change
glauth to allow empty bind dn](https://github.com/glauth/glauth/issues/83).

Step 7: New LDAP server, LDAP client not behaving
-------------------------------------------------

After a custom build of the LDAP server, still, it does not work. There must be
something on the SASL client library that I don't understand. Both `ldapsearch`
and Cyrus SASL via `imtest` are failing.

Here is what I get with `ldapsearch` using a base dn:

```
Bind ▶ DEBU 023  "level"=6 "msg"="Bind request"  "basedn"="dc=users,dc=local" "binddn"="cn=cyrus,ou=machines,dc=users,dc=local" "src"={"IP":"127.0.0.1","Port":57894,"Zone":""}
Bind ▶ DEBU 024  "level"=6 "msg"="Bind success"  "binddn"="cn=cyrus,ou=machines,dc=users,dc=local" "src"={"IP":"127.0.0.1","Port":57894,"Zone":""}
Search ▶ DEBU 025  "level"=6 "msg"="{BaseDN:dc=users,dc=local Scope:2 DerefAliases:0 SizeLimit:0 TimeLimit:0 TypesOnly:false Filter:(mail=jdoe@example.com) Attributes:[] Controls:[]}\n"
Search ▶ DEBU 026  "level"=6 "msg"="Search request"  "basedn"=",dc=users,dc=local" "binddn"="cn=cyrus,ou=machines,dc=users,dc=local" "filter"="(mail=jdoe@example.com)" "src"={"IP":"127.0.0.1","Port":57894,"Zone":""}
Search ▶ DEBU 027  "level"=6 "msg"="AP: Search OK"  "filter"="(mail=jdoe@example.com)"
```

Here is what I get without base dn and authentication on LDAP:

```
Search ▶ DEBU 020  "level"=6 "msg"="{BaseDN: Scope:0 DerefAliases:0 SizeLimit:0 TimeLimit:0 TypesOnly:false Filter:(objectclass=*) Attributes:[supportedSASLMechanisms] Controls:[]}\n"
Search ▶ DEBU 021  "level"=6 "msg"="Search request"  "basedn"=",dc=users,dc=local" "binddn"="" "filter"="(objectclass=*)" "src"={"IP":"127.0.0.1","Port":57874,"Zone":""}
Search ▶ DEBU 022  "level"=6 "msg"="AP: Search OK"  "filter"="(objectclass=*)"
```

The difference is in the search request, the filter is `(objectclass=*)` instead
of the user email `(mail=jdoe@example.com)`. The reason why the filter is not
transmitted when there is no authentication escapes to my reason for the moment.

Step 8: Making the LDAP authentication work
-------------------------------------------

We're back to making authenticated LDAP work properly. After documenting myself,
I found that there are two ways to authenticate on LDAP: simple bind and SASL.
Probably Cyrus SASL is trying to use SASL to authenticate itself as Cyrus on
LDAP, and my LDAP server is only understanding simple bind.

SASL Bind operation is described in [RFC 4513 section 5.2](https://tools.ietf.org/html/rfc4513#section-5.2)

While looking up implementation, I found that
[RFC 4512 section 5.1](https://tools.ietf.org/html/rfc4512#section-5.1) defines
that a client is allowed to make a search on the root DSE (a search with an
empty bind dn) to find out server properties such as allowed authentication
mechanisms. Such requests are made with the `(objectClass=*)` filter, which is
the same as found on the above logs.

[glauth]: https://github.com/glauth/glauth
[debug]: https://wiki.debian.org/HowToGetABacktrace
