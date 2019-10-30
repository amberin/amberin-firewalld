# firewalld

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with firewalld](#setup)
    * [Beginning with firewalld](#beginning-with-firewalld)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module was created because I was unhappy with
[puppet-firewalld](https://forge.puppet.com/puppet/firewalld) in
certain regards, primarily when it comes to managing IP sets.

It has the following advantages over `puppet-firewalld`:

* It allows nesting of IP sets, something which is not yet supported
  in FirewallD itself. I have currently limited nesting to a depth of
  4 levels.
* It allows for defining all IP sets in a single ENC/hiera scope (e.g.
  `common.yaml`), ensuring consistency and providing a better
  overview. IP sets can be defined globally, but will only be configured
  on a host if it uses them.
* It purges any undefined zones and IP sets, taking more
  aggressive control over the FirewallD configuration.
* It is very lightweight, whereas I have found `puppet-firewalld` to
  be very slow and a bit of a resource hog.
* It allows complete `hiera` description of a zone, including services
  and rich rules, in the same hash, which in my opinion provides
  better overview.

The module has the following (known) disadvantages when compared to
`puppet-firewalld`:

* It implements only the most basic features. Passthroughs, port
  forwarding, direct rules, masquerade and more are not supported
  (yet).
* It edits XML files directly and relies heavily on templates, so it 
  will break if FirewallD changes the look of its XMLs.
* It currently does not implement any resources or providers;
  everything is expected to be described by the ENC/`hiera`.
* It currently contains some pretty ugly attempts at Ruby logic.
* It currently has no tests, very little validation of hiera input, 
  and hence is probably not very robust.

## Setup

### Beginning with firewalld

## Usage

In your manifest, simply
```
include firewalld
```

And then, in `hiera`:
```
$ cat hieradatadir/common.yaml
---

firewalld::log_denied: unicast

firewalld::zones:
  control:
    sources: 
      - 10.0.10.0/24
    target: ACCEPT
  monitoring:
    sources:
      - 10.0.20.0/24
    services:
      - nrpe
    ports:
      9100: tcp
      9117: tcp

firewalld::all_ipsets:
  alice:
    - 10.20.0.100.11
    - 10.20.0.110.11
  bob:
    - 10.20.0.100.12
    - 10.20.0.110.12
  charlie:
    - 10.20.0.100.13
    - 10.20.0.110.13
  dave:
    - 10.20.0.100.14
    - 10.20.0.110.14
  prod_access:
    - alice
    - bob
    - charlie
  jump_host_users:
    - dave
    - prod_access

$ cat hieradatadir/nodes/myjumphost.yml
---

firewalld::zones:
  clients:
    sources:
      - 10.0.100.0/24
      - 10.0.110.0/24
    rich_rules:
      'SSH from jump_host_users':
        - service: ssh
        - ipset: jump_host_users
```

## Limitations

## Development
