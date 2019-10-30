# @summary Manage FirewallD with nested IP sets
#
# This module is intended as an alternative to puppet-firewalld (see
# README for background). It updates FirewallD configuration by
# directly editing the XML configuration files.
#
# This module has no types or providers, but is intended to be blanket
# applied and configured exclusively from ENC/hiera.
#
# This module allows nested IP sets (currently up to 4 levels) which
# is not (yet) supported natively by FirewallD.
#
# @example
#   include firewalld
#
#   $ cat hieradatadir/common.yaml
#   ---
# 
#   firewalld::log_denied: unicast
#
#   firewalld::zones:
#     control:
#       source: 10.0.10.0/24
#       target: ACCEPT
#     monitoring:
#       source: 10.0.20.0/24
#       services:
#         - nrpe
#       ports:
#         9100: tcp
#         9117: tcp
#   
#   firewalld::all_ipsets:
#     alice:
#       - 10.20.0.100.11
#       - 10.20.0.110.11
#     bob:
#       - 10.20.0.100.12
#       - 10.20.0.110.12
#     charlie:
#       - 10.20.0.100.13
#       - 10.20.0.110.13
#     dave:
#       - 10.20.0.100.14
#       - 10.20.0.110.14
#     prod_access:
#       - alice
#       - bob
#       - charlie
#     jump_host_users:
#       - dave
#       - prod_access
# 
class firewalld (
  Enum['all','unicast','broadcast','multicast','off'] $log_denied = 'off',
  Enum['present','absent','latest','installed'] $package_ensure = 'installed',
  Boolean                   $manage_package = true,
  Stdlib::Ensure::Service   $service_ensure = 'running',
  Boolean                   $service_enable = true,
  String                    $default_zone   = 'public',
  Hash                      $zones          = {},
  Hash                      $all_ipsets     = {},
) {

  require ::stdlib

  service { 'firewalld':
    ensure => $service_ensure,
    enable => $service_enable,
  }

  if $manage_package {
    package { 'firewalld':
      ensure => $package_ensure,
      notify => Service['firewalld'],
    }
  }

  # Institute config dir dictatorship
  file {
    [
      '/etc/firewalld/zones',
      '/etc/firewalld/ipsets',
    ]:
    ensure  => directory,
    purge   => true,
    recurse => true,
    mode    => '0500',
    notify  => Service['firewalld'],
  }

  # Set global config values
  augeas { 'firewalld.conf':
    context => '/files/etc/firewalld/firewalld.conf',
    changes => [
      "set LogDenied $log_denied",
      "set DefaultZone $default_zone",
    ],
    notify  => Service['firewalld'],
  }

  # Create a zone file for each FirewallD zone defined by ENC/hiera
  $zones.each |$zone, $zonevalues| {
    file { "/etc/firewalld/zones/${zone}.xml":
      content => template('firewalld/zone.xml.erb'),
      notify  => Service['firewalld'],
    }
  }

  # If the default zone is not described by ENC/hiera, create an empty
  # zone file
  if ! $zones[$default_zone] {
    $zone = $default_zone
    file { "/etc/firewalld/zones/${zone}.xml":
      content => template('firewalld/zone.xml.erb'),
      notify  => Service['firewalld'],
    }
  }

  # Find all unique IP sets that are used in the defined zones
  $needed_ipsets = lookup('firewalld::zones', Hash).map |String $key, Hash $zonevalues| {
    if $zonevalues['rich_rules'] {
      $zonevalues['rich_rules'].map |String $rule, Hash $rulevalues| {
        if $rulevalues['ipset'] {
          $rulevalues['ipset']
        }
      }
    }
  # Flatten the resulting nested lists, remove duplicates and purge any empty
  # elements.
  }.flatten.unique.filter |$item| { $item =~ NotUndef }

  # Create an IP set definition file for each unique, referenced IP set
  $needed_ipsets.each |$ipsetname| {
    file { "/etc/firewalld/ipsets/${ipsetname}.xml":
      content => template('firewalld/ipset.xml.erb'),
      notify  => Service['firewalld'],
    }
  }

}
