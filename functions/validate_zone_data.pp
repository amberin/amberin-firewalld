# Custom function for validating the contents of the hash firewalld::zones
function firewalld::validate_zone_data(String $zone, Hash $zonedata) >> Boolean {

  $func_name = "firewalld::validate_zone_data()"

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

  if $zonedata["interfaces"] {
    $zonedata["interfaces"].each |$interface| {
      if ! has_key($::facts['networking']['interfaces'], $interface) {
        fail("${func_name}: Nonexistent interface '${interface}' defined for zone '${zone}'")
      }
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
      if ! ($service.is_a(String) and $service =~ /^[a-z]{2,}$/) {
        fail("${func_name}: Invalid service '${service}' defined for zone '${zone}'")
      }
    }
  }

  if $zonedata["ports"] {
    $zonedata["ports"].each |$portnumber, $protocol| {
      if ! ($portnumber.is_a(Stdlib::Port) and $protocol.is_a(String) and $protocol =~ /^tcp$|^udp$/) {
        fail("${func_name}: Invalid port '${portnumber}: ${protocol}' defined for zone '${zone}'")
      }
    }
  }

  if $zonedata["rich_rules"] {
    $zonedata["rich_rules"].each |$rich_rule| {
      if $rich_rule[1]["family"] {
        $family = $rich_rule[1]["family"]
        if ! ($family.is_a(String) and $family =~ /^ipv4$|^ipv6$/) {
          fail("${func_name}: Invalid family '${family}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
        }
      }
      if $rich_rule[1]["service"] {
        $service = $rich_rule[1]["service"]
        if ! ($service.is_a(String) and $service =~ /^[a-z]{2,}$/) {
          fail("${func_name}: Invalid service '${service}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
        }
      }
      if $rich_rule[1]["source"] {
        $source = $rich_rule[1]["source"]
        if ! $source.is_a(Stdlib::IP::Address) {
          fail("${func_name}: Invalid source '${source}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
        }
      }
      if $rich_rule[1]["ipset"] {
        $ipset = $rich_rule[1]["ipset"]
        if ! $firewalld::ipsets.has_key($ipset) {
          fail("${func_name}: Invalid IP set '${ipset}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
        }
      }
      if $rich_rule[1]["action"] {
        $action = $rich_rule[1]["action"]
        if ! ($action in ['accept','drop','reject']) {
          fail("${func_name}: Invalid action '${action}' defined in rich rule '${rich_rule[0]}' in zone '${zone}'")
        }
      }
    }
  }

  true

}
