# firewalld

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with firewalld](#setup)
    * [Beginning with firewalld](#beginning-with-firewalld)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module was created because I was unhappy with certain aspects of
[puppet-firewalld](https://forge.puppet.com/puppet/firewalld),
primarily when it comes to managing IP sets.

It has the following advantages over `puppet-firewalld`:

* It allows nesting of IP sets, something which is not yet supported
  in FirewallD itself. Nesting is currently limited to a depth of
  4 levels.
* It allows for defining all IP sets in a single ENC/Hiera scope (e.g.
  `common.yaml`), ensuring consistency and providing a better
  overview. IP sets can be defined globally, but will only be configured
  on the nodes that use them.
* It purges any undefined zones and IP sets, thus taking more
  aggressive control over the FirewallD configuration.
* It is very fast, whereas I have found `puppet-firewalld` to
  be very slow and a bit of a resource hog.
* It allows complete Hiera description of a zone, including services
  and rich rules, in the same hash, which in my opinion provides
  better overview.

The module has the following (known) disadvantages when compared to
`puppet-firewalld`:

* It implements only the most basic features. Passthroughs, port
  forwarding, direct rules, masquerade and more are not supported
  (yet).
* Whereas `puppet-firewalld` works by issuing `firewall-cmd` commands,
  this module replaces configuration files, and thus is more prone to
  failing silently unless input is carefully validated (which I
  definitely believe is doable).
* It currently does not implement any resources or providers;
  everything is expected to be described by the ENC/Hiera.
* It currently contains some pretty ugly attempts at Ruby logic.

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
    target: ACCEPT
    sources: 
      - 10.0.10.0/24
  monitoring:
    sources:
      - 10.0.20.0/24
    services:
      - nrpe
    ports:
      9100: tcp
      9117: tcp
  clients:
      - 10.0.30.0/24
  vpn_clients:
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
firewalld::zones:
  clients:
    rich_rules:
      'SSH from jump_host_users':
        - service: ssh
        - ipset: jump_host_users
```

## Limitations

## Development
