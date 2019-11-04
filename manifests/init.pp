# @summary Manage FirewallD with nested IP sets
#
# This module was created as an alternative to puppet-firewalld (see
# README for background). It configures FirewallD by directly editing
# the XML configuration files.
#
# This module has no types or providers, but is intended to be blanket
# applied and configured exclusively from the ENC/Hiera.
#
# This module allows nested IP sets (currently up to 4 levels), which
# is not (yet) supported natively by FirewallD.
#
# @example
#   $ cat mymanifest.pp
#   include firewalld
#
#   $ cat hieradatadir/common.yaml
#   ---
# 
#   firewalld::log_denied: unicast
#
#   firewalld::zones:
#     control:
#       target: ACCEPT
#       sources:
#         - 10.0.10.0/24
#     monitoring:
#       sources:
#         - 10.0.20.0/24
#       services:
#         - nrpe
#       ports:
#         9100: tcp
#         9117: tcp
#     clients:
#       sources:
#         - 10.0.30.0/24
#     vpn_clients:
#       sources:
#         - 10.0.40.0/24
#   
#   firewalld::ipsets:
#     alice:
#       - 10.0.30.11
#       - 10.0.40.11
#     bob:
#       - 10.0.30.12
#       - 10.0.40.12
#     charlie:
#       - 10.0.30.13
#       - 10.0.40.13
#     dave:
#       - 10.0.30.14
#       - 10.0.40.14
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
  Stdlib::Ensure::Service   $service_ensure = 'running',
  Boolean                   $purge_config   = true,
  Boolean                   $manage_package = true,
  Boolean                   $service_enable = true,
  String                    $default_zone   = 'public',
  Hash                      $zones          = {},
  Hash                      $ipsets         = {},
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

  if $purge_config {
    # Institute config dir dictatorship.
    file { [
      '/etc/firewalld/zones',
      '/etc/firewalld/ipsets',
    ]:
      ensure  => directory,
      purge   => true,
      recurse => true,
      mode    => '0500',
      notify  => Service['firewalld'],
    }
  }

  # Set global config values.
  augeas { 'firewalld.conf':
    context => '/files/etc/firewalld/firewalld.conf',
    changes => [
      "set LogDenied $log_denied",
      "set DefaultZone $default_zone",
    ],
    notify  => Service['firewalld'],
  }

  # For each FirewallD zone defined by ENC/Hiera...
  $zones.each |$zone, $zonevalues| {
    # ...validate the provided zone data...
    if firewalld::validate_zone_data($zone, $zonevalues) {
      # ...and build the zone file
      file { "/etc/firewalld/zones/${zone}.xml":
        content => epp('firewalld/zone.xml.epp', {
          'zone'        => $zone,
          'zonevalues'  => $zonevalues,
        }),
        notify  => Service['firewalld'],
      }
    }
  }

  # If the default zone is not described by ENC/Hiera, create an empty
  # zone file.
  if ! $zones[$default_zone] {
    $zone = $default_zone
    file { "/etc/firewalld/zones/${zone}.xml":
      content => epp('firewalld/zone.xml.epp', {
        'zone'        => $zone,
        'zonevalues'  => '',
      }),
      notify  => Service['firewalld'],
    }
  }

  # Find all unique IP sets that appear in the defined zones.
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

  # Create an IP set definition file for each unique, referenced IP set.
  $needed_ipsets.each |$ipsetname| {
    file { "/etc/firewalld/ipsets/${ipsetname}.xml":
      content => epp('firewalld/ipset.xml.epp', {
        'ipsets'    => $::firewalld::ipsets,
        'ipsetname' => $ipsetname,
      }),
      notify  => Service['firewalld'],
    }
  }

}
