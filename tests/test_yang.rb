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

  RED_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"RED",
            "create":[
               null
            ]
         }
      ]
    }}'

    BLUE_VRF_PROPERTIES1 = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
        "vrf":[
           {
              "vrf-name":"BLUE",
              "create":[
                 null
              ],
              "vpn-id":{
                "vpn-oui":0,
                "vpn-index":0
                }
           }
        ]
      }}'

  BLUE_VRF_PROPERTIES2 = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "description":"Generic external traffic",
            "create":[
               null
            ],
            "vpn-id":{
              "vpn-oui":0,
              "vpn-index":0
              }
         }
      ]
    }}'

    BLUE_VRF_PROPERTIES3 = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
        "vrf":[
           {
              "vrf-name":"BLUE",
              "description":"Generic ext traffic",
              "create":[
                 null
              ],
              "vpn-id":{
                "vpn-oui":8,
                "vpn-index":9
                }
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

  def clear_vrfs
    current_vrfs = node.get_yang(PATH_VRFS)
    if !Yang.empty?(current_vrfs)
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

  def test_merge_diff
    # ensure we think that a merge is needed (in-sinc = false)
    refute(Yang.insync_for_merge(BLUE_VRF, node.get_yang(PATH_VRFS)), "Expected not in-sync")

    node.merge_yang(BLUE_VRF)  # create the blue VRF

    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Yang.insync_for_merge(BLUE_VRF, node.get_yang(PATH_VRFS)), "Expected in-sync")


    # ensure we think that the merge is needed (in-sinc = false)
    refute(Yang.insync_for_merge(RED_VRF, node.get_yang(PATH_VRFS)), "Expected not in-sync")

    node.merge_yang(RED_VRF)  # create the red VRF

    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Yang.insync_for_merge(RED_VRF, node.get_yang(PATH_VRFS)), "Expected in-sync")
  end

  def test_merge_leaves
    node.merge_yang(BLUE_VRF) # create blue vrf with description
    node.merge_yang(BLUE_VRF_PROPERTIES1) # merge blue vrf with vpn id to blue vrf with description

    # ensure that new leaves are merged with old.
    assert(Yang.insync_for_merge(BLUE_VRF_PROPERTIES2, node.get_yang(PATH_VRFS)), "Expected in-sync")

    # update description and vpn-id
    node.merge_yang(BLUE_VRF_PROPERTIES3)
    assert(Yang.insync_for_merge(BLUE_VRF_PROPERTIES3, node.get_yang(PATH_VRFS)), "Expected in-sync")
  end

end
