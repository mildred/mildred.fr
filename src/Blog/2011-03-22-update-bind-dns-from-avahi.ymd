--- 
title:      How to update your Bind DNS Server from Avahi
created_at: 2011-03-22 10:10:37.138277 +01:00
excerpt:
kind:       article
publish:    true
tags:
  - en
  - freedombox
  - comp
--- 

Attention: this post contains wrong information. What I discovered wasn't a way
tu publish services to a DNS server but publish local workstations to the DNS.

Following my previous post, I wondered how to update the DNS server from Avahi.
[I was not alone][post]. I found a script that could be run as a cron job that
does the job. The next step is to use Avahi notifications instead of pooling
every minute.

<!--

Now, the script (in PHP, better to rewrite in something sensible):

    #!/usr/bin/php

    <?php
    $avahidata = explode("\n",`avahi-browse -ptr _workstation._tcp`);

    $hosts="server localhost\nzone local\n";
    $pointers="server localhost\nzone 0.168.192.in-addr.arpa\n";

    $oldhosts="server localhost\nzone local\n";
    $oldpointers="server localhost\nzone 0.168.192.in-addr.arpa\n";

    for($i=0;$i<count($avahidata)-1;$i++){
        $hostInformation=explode(";",$avahidata[$i]);
        if($hostInformation[0] != "=") continue;

        $hostname=$hostInformation[6];
        $hostaddr=$hostInformation[7];
        $ptraddr=implode(".",array_reverse(explode(".",$hostaddr)));

        $hosts.="update add $hostname 2400 A $hostaddr\n";
        $pointers.="update add $ptraddr.in-addr.arpa 2400 PTR $hostname\n";

        $oldhosts.="update delete $hostname A\n";
        $oldpointers.="update delete $ptraddr.in-addr.arpa PTR\n";
    }

    $hosts.="send\n";
    $pointers.="send\n";

    $oldhosts.="send\n";
    $oldpointers.="send\n";

    echo `cat .dns_purge_hosts | nsupdate`;
    echo `cat .dns_purge_pointers | nsupdate`;

    echo `echo "$hosts" | nsupdate`;
    echo `echo "$pointers" | nsupdate`;

    file_put_contents(".dns_purge_hosts",$oldhosts);
    file_put_contents(".dns_purge_pointers",$oldpointers);

    ?>

And configure Bind to allow updates from localhost:

    acl lan { 192.168.0/24; 127.0.0.1; };

    options {
        directory "/var/named";
        pid-file "/var/run/named/named.pid";
        auth-nxdomain yes;
        datasize default;
        listen-on { any; };
        forward first;
        forwarders {
            8.8.8.8;
            8.8.4.4;
        };
    };

    zone "local" {
        type master;
        file "local.zone";
        check-names ignore;
        allow-transfer { lan; };
        allow-update { lan; };
    };

    zone "0.168.192.in-addr.arpa" {
        type master;
        file "0.168.192.in-addr.arpa.zone";
        check-names ignore;
        allow-transfer { lan; };
        allow-update { lan; };
    };

-->

Thanks to [leica][author]

edit: probably a better solution would to still use mDNS over unicast DNS (wide
area). See a post from [Lennart Poettering][lennart].

[post]: http://www.gamers-forum.com/showthread.php?t=17882
[author]: http://gamers-forum.com/member.php?u=35088
[lennart]: http://0pointer.de/blog/projects/avahi-wide-area.html