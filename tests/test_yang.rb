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
#require_relative '../lib/cisco_node_utils/bgp'

# TestYang - Minitest for Yang class
class TestYang < CiscoTestCase

  BLUE_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "description":"Generic external traffic",
            "create":[
               null
            ]
         }
      ]
    }}'

  NO_VRFS = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}'
  PATH_VRFS = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}'

  def setup
    super
    clear_vrfs
  end

  def teardown
    super
    clear_vrfs
  end

  def empty?(string)
    return !string || string.empty?
  end

  def clear_vrfs
    current_vrfs = node.get_yang(PATH_VRFS)
    if !empty?(current_vrfs)
#      puts "*** deleting configured VRFs: |#{current_vrfs}|"
      node.delete_yang(PATH_VRFS) # remove all vrfs
    else
#      puts "*** no VRFs current configured: |#{current_vrfs}|"
    end
  end

  def test_delete_vrfs
    node.merge_yang(BLUE_VRF)  # ensure at least one VRF is there
    assert(node.get_yang(PATH_VRFS).match('BLUE'), "Did not find the BLUE vrf")

    clear_vrfs
    assert_equal("", node.get_yang(PATH_VRFS), "There are still vrfs configured")
  end

  def test_add_vrf
    node.merge_yang(BLUE_VRF)  # create a single VRF
    assert(node.get_yang(PATH_VRFS).match('BLUE'), "Did not find the BLUE vrf")
  end

end
