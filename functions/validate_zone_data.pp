# Custom function for validating the contents of the hash firewalld::zones
function firewalld::validate_zone_data(String $zone, Hash $zonedata) >> Boolean {

  $func_name = "firewalld::validate_zone_data()"

  if ($zone.length > 17) {
    fail("${func_name}: Zone name is more than 17 characters long: '${zone}'")
  }

  if $zonedata["target"] {
    $target = $zonedata["target"]
    if ! ($target in [
      'default',
      'accept',
      'ACCEPT',
      'reject',
      'REJECT',
      '%%REJECT%%',
      'drop',
      'DROP'
    ]) {
      fail("${func_name}: Invalid target '${target}' defined for zone '${zone}'")
    }
  }

  if $zonedata["sources"] {
    $zonedata["sources"].each |$source| {
      # TODO: Verify that ipset sources exist, and ensure that they
      # get created on the node.
      if ! ($source.is_a(Stdlib::IP::Address) or $source =~ /^ipset:[a-z]{2,}$/) {
        fail("${func_name}: Invalid source '${source}' defined for zone '${zone}'")
      }
    }
  }

  if $zonedata["services"] {
    $zonedata["services"].each |$service| {
      if ! ($service.is_a(String) and $service =~ /^[a-z-]{2,}$/) {
        fail("${func_name}: Invalid service '${service}' defined for zone '${zone}'")
      }
    }
  }

  if $zonedata["ports"] {
    $zonedata["ports"].each |$protocol, $portnumbers| {
      if ! ($protocol.is_a(String) and $protocol =~ /^tcp$|^udp$/) {
        fail("${func_name}: Invalid protocol '${protocol}' defined for zone '${zone}'")
      }
      # TODO: Validate ports, allowing port ranges
    }
  }

  if $zonedata["rich_rules"] {
    $zonedata["rich_rules"].each |$rich_rule| {
      if ! ($rich_rule[1].is_a(Hash)) {
        fail("${func_name}: Invalid rich rule '${rich_rule[0]}' in zone '${zone}'. Rich rules must be uniquely named.")
      }
      else {
        $rich_rule[1].each |$rule_entry| {
          if $rule_entry[0] == "family" {
            $family = $rule_entry[1]
            if ! ($family.is_a(String) and $family =~ /^ipv4$|^ipv6$/) {
              fail("${func_name}: Invalid family '${family}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
            }
          } elsif $rule_entry[0] == "service" {
            $service = $rule_entry[1]
            if ! ($service.is_a(String) and $service =~ /^[a-z]{2,}$/) {
              fail("${func_name}: Invalid service '${service}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
            }
          } elsif $rule_entry[0] == "source" {
            if $rich_rule[1].has_key("ipset") {
              fail("${func_name}: Both 'source' and 'ipset' values defined in rich rule '${rich_rule[0]}' in zone '${zone}'. Please choose one!")
            }
            $source = $rule_entry[1]
            if ! $source.is_a(Stdlib::IP::Address) {
              fail("${func_name}: Invalid source '${source}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
            }
          } elsif $rule_entry[0] == "ipset" {
            if $rich_rule[1].has_key("source") {
              fail("${func_name}: Both 'source' and 'ipset' values defined in rich rule '${rich_rule[0]}' in zone '${zone}'. Please choose one!")
            }
            $ipset = $rule_entry[1]
            if ! $firewalld::ipsets.has_key($ipset) {
              fail("${func_name}: Invalid IP set '${ipset}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
            }
          } elsif $rule_entry[0] == "action" {
            $action = $rule_entry[1]
            if ! ($action in ['accept','drop','reject']) {
              fail("${func_name}: Invalid action '${action}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
            }
          } elsif $rule_entry[0] == "tcp" or $rule_entry[0] == "udp" {
            $port = $rule_entry[1]
            # TODO: Validate ports, allowing port ranges
          } else {
            fail("${func_name}: Unsupported rich rule element '${rule_entry[0]}' in rich rule '${rich_rule[0]}' in zone '${zone}'")
          }
        }
      }
    }
  }

  if $zonedata["icmp-block-inversions"] {
    $zonedata["icmp-block-inversions"].each |$icmptype| {
      if ! ($icmptype in [
        'address-unreachable',
        'bad-header',
        'communication-prohibited',
        'destination-unreachable',
        'echo-reply',
        'echo-request',
        'fragmentation-needed',
        'host-precedence-violation',
        'host-prohibited',
        'host-redirect',
        'host-unknown',
        'host-unreachable',
        'ip-header-bad',
        'neighbour-advertisement',
        'neighbour-solicitation',
        'network-prohibited',
        'network-redirect',
        'network-unknown',
        'network-unreachable',
        'no-route',
        'packet-too-big',
        'parameter-problem',
        'port-unreachable',
        'precedence-cutoff',
        'protocol-unreachable',
        'redirect',
        'required-option-missing',
        'router-advertisement',
        'router-solicitation',
        'source-quench',
        'source-route-failed',
        'time-exceeded',
        'timestamp-reply',
        'timestamp-request',
        'tos-host-redirect',
        'tos-host-unreachable',
        'tos-network-redirect',
        'tos-network-unreachable',
        'ttl-zero-during-reassembly',
        'ttl-zero-during-transit',
        'destination-unreachable',
        'unknown-header-type',
        'unknown-option',
      ]) {
        fail("${func_name}: Invalid ICMP block inversion '${icmptype}' defined for zone '${zone}'")
      }
    }
  }

  # Only define the zone on hosts where it is actually in use
  if $zonedata["target"].empty and
      $zonedata["services"].empty and
      $zonedata["ports"].empty and
      $zonedata["rich_rules"].empty {
    false
  } else {
    true
  }

}
