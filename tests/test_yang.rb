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

  GREEN_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"GREEN",
            "create": null
         }
      ]
    }}'

  BLUE_GREEN_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "create":[null],
            "description":"Generic external traffic"
         },
         {
            "vrf-name":"GREEN",
            "create":[null]
         }
      ]
  }}'

  BLUE_VRF_NO_PROPERTIES = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
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

  GE0_SRLG = '{"Cisco-IOS-XR-infra-rsi-cfg:srlg": {
    "interfaces": {
    "interface": [
      {
      "interface-name": "GigabitEthernet0/0/0/0",
      "enable": [
        null
      ],
      "values": {
        "value": [
        {
          "srlg-index": 10,
          "srlg-value": 100,
          "srlg-priority": "default"
        },
        {
          "srlg-index": 20,
          "srlg-value": 200,
          "srlg-priority": "default"
        }
        ]
      },
      "interface-group": {
        "enable": [
        null
        ],
        "group-names": {
        "group-name": [
          {
          "group-name-index": 1,
          "group-name": "2",
          "srlg-priority": "default"
          }
        ]
        }
      }
      }
    ]
    },
    "enable": [
    null
    ]
    }
  }'

  GE0_NEW_SRLG = '{"Cisco-IOS-XR-infra-rsi-cfg:srlg": {
    "interfaces": {
    "interface": [
      {
      "interface-name": "GigabitEthernet0/0/0/0",
      "enable": [
        null
      ],
      "values": {
        "value": [
        {
          "srlg-index": 90,
          "srlg-value": 900,
          "srlg-priority": "default"
        },
        {
          "srlg-index": 20,
          "srlg-value": 200,
          "srlg-priority": "default"
        }
        ]
      },
      "interface-group": {
        "enable": [
        null
        ],
        "group-names": {
        "group-name": [
          {
          "group-name-index": 1,
          "group-name": "9",
          "srlg-priority": "default"
          }
        ]
        }
      }
      }
    ]
    },
    "enable": [
    null
    ]
    }
  }'

  GE1_SRLG = '{"Cisco-IOS-XR-infra-rsi-cfg:srlg": {
    "interfaces": {
    "interface": [
      {
      "interface-name": "GigabitEthernet0/0/0/1",
      "enable": [
        null
      ]
      }
    ]
    },
    "enable": [
    null
    ]
    }
  }'

  GE0_GE1_SRLG = '{"Cisco-IOS-XR-infra-rsi-cfg:srlg": {
    "interfaces": {
    "interface": [
      {
      "interface-name": "GigabitEthernet0/0/0/0",
      "enable": [
        null
      ],
      "values": {
        "value": [
        {
          "srlg-index": 10,
          "srlg-value": 100,
          "srlg-priority": "default"
        },
        {
          "srlg-index": 20,
          "srlg-value": 200,
          "srlg-priority": "default"
        }
        ]
      },
      "interface-group": {
        "enable": [
        null
        ],
        "group-names": {
        "group-name": [
          {
          "group-name-index": 1,
          "group-name": "2",
          "srlg-priority": "default"
          }
        ]
        }
      }
      },
      {
      "interface-name": "GigabitEthernet0/0/0/1",
      "enable": [
        null
      ]
      }
    ]
    },
    "enable": [
    null
    ]
  }
  }'

  GE0_GE1_NEW_SRLG = '{"Cisco-IOS-XR-infra-rsi-cfg:srlg": {
    "interfaces": {
    "interface": [
      {
      "interface-name": "GigabitEthernet0/0/0/0",
      "enable": [
        null
      ],
      "values": {
        "value": [
        {
          "srlg-index": 90,
          "srlg-value": 900,
          "srlg-priority": "default"
        },
        {
          "srlg-index": 20,
          "srlg-value": 200,
          "srlg-priority": "default"
        }
        ]
      },
      "interface-group": {
        "enable": [
        null
        ],
        "group-names": {
        "group-name": [
          {
          "group-name-index": 1,
          "group-name": "9",
          "srlg-priority": "default"
          }
        ]
        }
      }
      },
      {
      "interface-name": "GigabitEthernet0/0/0/1",
      "enable": [
        null
      ]
      }
    ]
    },
    "enable": [
    null
    ]
  }
  }'

  NO_VRFS = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}'
  PATH_VRFS = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}'
  PATH_SRLG = '{"Cisco-IOS-XR-infra-rsi-cfg:srlg": [null]}'

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

  def clear_srlg
    current_srlg = node.get_yang(PATH_SRLG)
    if !Yang.empty?(current_srlg)
      node.delete_yang(PATH_SRLG)
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

    node.replace_yang(GREEN_VRF)  # create a single VRF
    assert(node.get_yang(PATH_VRFS).match('GREEN'), "Did not find the BLUE vrf")
    refute(node.get_yang(PATH_VRFS).match('BLUE'), "Found the BLUE vrf")
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

  def test_merge_srlg
    clear_srlg
    node.merge_yang(GE1_SRLG)
    assert(Yang.insync_for_merge(GE1_SRLG, node.get_yang(PATH_SRLG)), "Expected in-sync")

    node.merge_yang(GE0_SRLG)
    assert(Yang.insync_for_merge(GE0_SRLG, node.get_yang(PATH_SRLG)), "Expected in-sync")
    assert(Yang.insync_for_merge(GE0_GE1_SRLG, node.get_yang(PATH_SRLG)), "Expected in-sync")

    node.merge_yang(GE0_NEW_SRLG)
    assert(Yang.insync_for_merge(GE0_NEW_SRLG, node.get_yang(PATH_SRLG)), "Expected in-sync")
    assert(Yang.insync_for_merge(GE0_GE1_NEW_SRLG, node.get_yang(PATH_SRLG)), "Expected in-sync")
    refute(Yang.insync_for_merge(GE0_SRLG, node.get_yang(PATH_SRLG)), "Expected not in-sync")
    refute(Yang.insync_for_merge(GE0_GE1_SRLG, node.get_yang(PATH_SRLG)), "Expected not in-sync")
    clear_srlg
  end

  def test_errors
    # === test get_yang ===========

    # lexical error: invalid char in json text
    assert_raises(Cisco::YangError) { node.get_yang('aabbcc') }

    # parse error: object key and value must be separated by a colon
    assert_raises(Cisco::YangError) { node.get_yang('{"aabbcc"}') }

    # unknown-namespace
    assert_raises(Cisco::ClientError) { node.get_yang('{"aabbcc": "foo"}') }

    # unknown-element
    assert_raises(Cisco::ClientError) {
      node.get_yang('{"Cisco-IOS-XR-infra-rsi-cfg:aabbcc": "foo"}')
    }

    # parse error: premature EOF
    assert_raises(Cisco::YangError) { node.get_yang('{') }

    # parse error: invalid object key (must be a string)
    assert_raises(Cisco::YangError) { node.get_yang('{: "foo"}') }


    # === test merge_yang ===========

    # Request is not wellformed
    assert_raises(Cisco::ClientError) { node.merge_yang('aabbcc') }

    # unknown-element
    assert_raises(Cisco::ClientError) {
      node.merge_yang('{"Cisco-IOS-XR-infra-rsi-cfg:aabbcc": "foo"}')
    }

    # bad-element
    assert_raises(Cisco::ClientError) {
      node.merge_yang('{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": "foo"}')
    }

    # missing-element
    assert_raises(Cisco::YangError) {
      node.merge_yang('{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": {"vrf":[{}]}}')
    }


    # === test replace_yang ===========

    # unknown-namespace
    assert_raises(Cisco::ClientError) {
      node.replace_yang('{"Cisco-IOS-XR-infra-rsi-cfg:aabbcc": "foo"}')
    }

    # for some reason replace_yang does not have the same error checking
    # that merge_yang does, so this just fails quietly
    node.replace_yang('{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": }')
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

    node.merge_yang(GREEN_VRF) # create green VRF
    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Yang.insync_for_merge(GREEN_VRF, node.get_yang(PATH_VRFS)), "Expected in-sync")
  end

  def test_replace_diff
    # ensure we think that a merge is needed (in-sinc = false)
    refute(Yang.insync_for_replace(BLUE_VRF, node.get_yang(PATH_VRFS)), "Expected not in-sync")

    node.replace_yang(BLUE_VRF)  # create the blue VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace(BLUE_VRF, node.get_yang(PATH_VRFS)), "Expected in-sync")

    node.replace_yang(RED_VRF)  # create the red VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace(RED_VRF, node.get_yang(PATH_VRFS)), "Expected in-sync")

    node.replace_yang(GREEN_VRF) # create green VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace(GREEN_VRF, node.get_yang(PATH_VRFS)), "Expected in-sync")

    node.merge_yang(BLUE_VRF)

    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace(BLUE_GREEN_VRF, node.get_yang(PATH_VRFS)), "Expected in sync")
    # ensure we think that a replace is needed (in-sinc = true)
    refute(Yang.insync_for_replace(BLUE_VRF, node.get_yang(PATH_VRFS)), "Expected not in sync")
    refute(Yang.insync_for_replace(GREEN_VRF, node.get_yang(PATH_VRFS)), "Expected not in sync")

    node.replace_yang(BLUE_VRF)
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace(BLUE_VRF, node.get_yang(PATH_VRFS)), "Expected in-sync")
    # ensure we think that a replace is needed (in-sinc = true)
    refute(Yang.insync_for_replace(GREEN_VRF, node.get_yang(PATH_VRFS)), "Expected not in-sync")
    refute(Yang.insync_for_replace(BLUE_GREEN_VRF, node.get_yang(PATH_VRFS)), "Expected not in-sync")
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

def test_replace_leaves
  node.replace_yang(BLUE_VRF) # create blue vrf with description
  node.replace_yang(BLUE_VRF_PROPERTIES1) # replace blue vrf (description) by blue vrf (vpn-id)

  # ensure that new properties are replaced by old.
  assert(Yang.insync_for_replace(BLUE_VRF_PROPERTIES1, node.get_yang(PATH_VRFS)), "Expected in-sync")

  # replace description and vpn-id
  node.replace_yang(BLUE_VRF_PROPERTIES3)
  assert(Yang.insync_for_replace(BLUE_VRF_PROPERTIES3, node.get_yang(PATH_VRFS)), "Expected in-sync")
end

end
