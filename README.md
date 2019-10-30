# firewalld

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with firewalld](#setup)
    * [What firewalld affects](#what-firewalld-affects)
    * [Setup requirements](#setup-requirements)
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
* It edits XML files directly and relies heavily on   templates, so it will break if FirewallD
  changes the look of its XMLs.
* It currently does not implement any resources or providers;
  everything is expected to be described by the ENC/`hiera`.

### Beginning with firewalld

#The very basic steps needed for a user to get the module up and running. This can include setup steps, if necessary, or it can be an example of the most basic use of the module.

## Usage

#Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

## Limitations

#In the Limitations section, list any incompatibilities, known issues, or other warnings.

## Development

#In the Development section, tell other users the ground rules for contributing to your project and how they should submit their work.
