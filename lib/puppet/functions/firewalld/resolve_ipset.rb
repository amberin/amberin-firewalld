# This custom functions fetches the contents of a (possibly nested) IP
# set
Puppet::Functions.create_function(:'firewalld::resolve_ipset') do
  dispatch :resolve do
    param 'String', :ipset_name
    param 'Hash', :all_ipsets
  end

  def resolve(ipset_name, all_ipsets, forbidden = [])
    require "resolv"
    result = []
    all_ipsets[ipset_name].each do |entry|
      if not all_ipsets.key?(entry)
        # Current entry is not another IP set.
        # Let's check if it's a valid IP address.
        if not entry =~ Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex])
          fail "Invalid IP set entry '#{entry}' encountered in IP set " \
            "'#{ipset_name}'."
        else
          # Current entry is a valid IP address; add it to results.
          result << entry
        end
      else
        # Current entry is another IP set. Let's resolve it...
        # ...but first, prevent infinite recursion.
        if forbidden.include? entry
          fail "Infinite IP set nesting detected while resolving entry " \
            "'#{entry}' in IP set '#{ipset_name}'."
        else
          # We don't want to make more attempts to resolve this IP set.
          forbidden << ipset_name
          # Recursive function call:
          result << resolve(entry, all_ipsets, forbidden)
        end
      end
    end
    result.flatten.uniq
  end
end
