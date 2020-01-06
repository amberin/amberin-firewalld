# firewalld

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with firewalld](#setup)
    * [Beginning with firewalld](#beginning-with-firewalld)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This Puppet module is intended as an alternative to
[puppet-firewalld](https://forge.puppet.com/puppet/firewalld).
It was created because I disliked certain aspects of the latter, 
primarily the options for managing IP sets.

It has the following advantages over `puppet-firewalld`:

* It allows nesting of IP sets, something not yet supported
  by FirewallD itself.
* It allows for defining all IP sets and zone sources in a single
  ENC/Hiera scope (e.g.  `common.yaml`), promoting consistency and
  oversight. IP sets and zone sources can be defined globally, but
  will only be configured on nodes where they are actually in use.
* It purges any undefined zones and IP sets, taking more
  aggressive control over the FirewallD configuration.
* It is very fast, whereas I have found `puppet-firewalld` to
  be very slow and a bit of a resource hog.
* It expects a single hash describing all properties of each zone, 
  which in my opinion provides better oversight.

The module has the following (known) disadvantages when compared to
`puppet-firewalld`:

* It implements only the most basic features. Passthroughs, port
  forwarding, direct rules, masquerade and more are not supported
  (yet).
* Whereas `puppet-firewalld` works by issuing `firewall-cmd` commands,
  this module replaces configuration files, and thus is more prone to
  failing silently unless input is carefully validated (which I
  believe is definitely doable).
* It currently does not implement any resources or providers;
  everything is expected to be described by the ENC/Hiera.

## Setup

### Beginning with firewalld

## Usage

In your manifest, simply
```
include firewalld
```

And then, in Hiera:
```
$ cat hieradatadir/common.yaml
---
firewalld::zones:
  control:
    target: accept
    sources: 
      - 10.0.10.0/24
  monitoring:
    sources:
      - 10.0.20.0/24
    services:
      - nrpe
    ports:
      tcp:
        - 9100
        - 9117
      udp:
        - 161
  clients:
    sources:
      - 10.0.30.0/24
  vpn_clients:
    sources:
      - 10.0.40.0/24

firewalld::ipsets:
  alice:
    - 10.0.30.11
    - 10.0.40.11
  bob:
    - 10.0.30.12
    - 10.0.40.12
  charlie:
    - 10.0.30.13
    - 10.0.40.13
  dave:
    - 10.0.30.14
    - 10.0.40.14
  prod_access:
    - alice
    - bob
    - charlie
  jump_host_users:
    - prod_access
    - dave

$ cat hieradatadir/nodes/myjumphost.yml
---
firewalld::log_denied: unicast
firewalld::zones:
  clients:
    rich_rules:
      'SSH for jump host users':
        - service: ssh
        - ipset: jump_host_users
```

## Limitations

## Development
