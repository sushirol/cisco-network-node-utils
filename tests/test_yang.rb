#!/usr/bin/env ruby
require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/yang'

# TestRouterBgp - Minitest for RouterBgp class
class TestYang < CiscoTestCase
  def test_init
    Yang.new
  end
end
