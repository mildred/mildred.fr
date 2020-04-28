---
title: "Namespaces in Consul/Nomad"
date: 2018-01-05
draft: false
---

A namespace is a collection of nomad jobs in the same directory. Sub-directories are sub-namespaces. When instanciated, a namespace is allocated an identifier (8 character unique ID). Before being inserted in nomad, the jobs are modified to include this namespace identifier:

- the nomad job name is prefixed by "NAMESPACE-" (the namespace identifier)
- the consul service definitions are prefixed by "NAMESPACE-" (the namespace identifier)
- the services have an additional environment variable: CONSUL_NAMESPACE_ID

sub-namespaces are also inserted in the system when their parent namespace is inserted. Each sub-namespace is given an identifier the same way. The parent namespace is instanciated with:

- an environment variable CONSUL_NAMESPACE_ID_FOR_subnsname containing the sub namespace identifier

We can imageine a complex system using namespace hierarchy like this:

- `main/` application namespace containing:
    - `web-service.nomad` (instanciated as "00000001-web-service")
    - `helper.nomad` (instanciated as "00000001-helper")
    - `smtp/` server sub namespace:
        - `exim.nomad` (instanciated as "00000002-exim")
        - `dovecot.nomad` (instanciated as "0000002-dovecot")

web-service knows how to contact exim because it can find it using the consul name "${CONSUL_NAMESPACE_ID_FOR_SMTP}-exim.service.consul"

-----

_Edit (2019-03-16): this is reflected in my [nomadspace](https://github.com/mildred/nomadspace) project._
