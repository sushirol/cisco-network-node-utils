#!/usr/bin/env ruby
# Yang Unit Tests
#
# Charles Burkett, May, 2016
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/yang'

# TestYang - Minitest for Yang class
class TestYang < CiscoTestCase

RED_VRF =
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
     <vrf>
      <vrf-name>red</vrf-name>
      <create></create>
     </vrf>
   </vrfs>'

  def setup
    super
    #clear_vrfs
  end

  def teardown
    super
    #clear_vrfs
  end

  #def clear_vrfs
    #current_vrfs = node.get_yang(PATH_VRFS)
    #if !Yang.empty?(current_vrfs)
##      puts "*** deleting configured VRFs: |#{current_vrfs}|"
      #node.delete_yang(PATH_VRFS) # remove all vrfs
    #else
##      puts "*** no VRFs current configured: |#{current_vrfs}|"
    #end
  #end


  #def test_delete_vrfs
    #assert_equal("", node.get_yang(PATH_VRFS), "There are still vrfs configured")
  #end

  def test_add_vrf
    node.get_xml(RED_VRF)  # create a single VRF
  end


=begin

RED_VRF =
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
     <vrf>
      <vrf-name>red</vrf-name>
      <create></create>
     </vrf>
   </vrfs>'

delete_RED_VRF =
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
     <vrf xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="delete">
      <vrf-name xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="delete">red</vrf-name>
      <create></create>
     </vrf>
   </vrfs>'

vrfs_config =
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
   <vrf>
    <vrf-name>red</vrf-name>
    <create></create>
   </vrf>
   <vrf>
    <vrf-name>green</vrf-name>
    <create></create>
    <description>test desc</description>
    <vpn-id>
     <vpn-oui>2</vpn-oui>
     <vpn-index>2</vpn-index>
    </vpn-id>
    <remote-route-filter-disable></remote-route-filter-disable>
   </vrf>
  </vrfs>'

login = { :target => '192.168.1.16',
  :username => 'root',
  :password => 'lab' }
filter = '<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
nc_client = Netconf::Client.connect(login)
#reply = nc_client.get_config(filter)
#reply = nc_client.get_config(nil)
#reply.config.each {|c|
#  puts c
#}
#reply = Netconf::Client.edit_config("candidate", "merge", RED_VRF)
reply = Netconf::Client.commit_changes()
#puts reply
reply = Netconf::Client.delete_config(delete_RED_VRF)
puts "Delete Errors:" if reply.errors?
reply.errors.each {|e|
  puts "Error:"
  e.each {|k,v| puts "#{k} - #{v}"}}
reply = Netconf::Client.commit_changes()
puts "Commit Errors:" if reply.errors?
reply.errors.each {|e|
  puts "Error:"
  e.each {|k,v| puts "#{k} - #{v}"}}
reply = Netconf::Client.get_config(filter)
reply.config.each {|c|
  puts c
}

a = Thread.new {
  i = 0
  while i < 5
    i = i + 1
    sleep(1)
    puts "waiting for a last minute commit!"
  end

  i = 0

  puts "LAST MINUTE COMMIT"
  Netconf::Client.commit_changes()
  puts "LAST MINUTE COMMIT FINISHED"
  while i < 15
    i = i + 1
    sleep(1)
    puts "waiting for it all to end"
  end

  Netconf::Client.commit_changes()

}.join

=end

end
