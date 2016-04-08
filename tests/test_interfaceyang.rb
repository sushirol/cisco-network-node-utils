#!/usr/bin/env ruby
require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/interfaceyang'

# TestRouterBgp - Minitest for RouterBgp class
class TestInterfaceYang < CiscoTestCase
  def test_init
    interfaces = InterfaceYang.interfaces
    puts interfaces
    refute_empty(interfaces, 'Error: interfaces collection empty')
  end
end
