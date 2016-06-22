#!/usr/bin/env ruby
# Yang Unit Tests
#
# Jason Young, June 2016
#
# Copyright (c) 2016 Cisco and/or its affiliates.
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

require 'rexml/document'
require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/client/netconf/netconf'

# TestNetconf- Minitest for Netconf class
class TestNetconf < CiscoTestCase

  BLUE_VRF = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>BLUE</vrf-name>
    <description>Generic external traffic</description>
    <create/>
  </vrf>
</vrfs>'

  RED_VRF = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>RED</vrf-name>
    <create/>
  </vrf>
</vrfs>'

  GREEN_VRF = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>GREEN</vrf-name>
    <create/>
  </vrf>
</vrfs>'

  BLUE_GREEN_VRF = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>BLUE</vrf-name>
    <description>Generic external traffic</description>
    <create/>
  </vrf>
  <vrf>
    <vrf-name>GREEN</vrf-name>
    <create/>
  </vrf>
</vrfs>'

  BLUE_VRF_NO_PROPERTIES = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>BLUE</vrf-name>
    <create/>
  </vrf>
</vrfs>'

  BLUE_VRF_PROPERTIES1 = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>BLUE</vrf-name>
    <create/>
    <vpn-id>
      <vpn-oui>0</vpn-oui>
      <vpn-index>0</vpn-index>
    </vpn-id>
  </vrf>
</vrfs>'

  BLUE_VRF_PROPERTIES2 = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>BLUE</vrf-name>
    <description>Generic external traffic</description>
    <create/>
    <vpn-id>
      <vpn-oui>0</vpn-oui>
      <vpn-index>0</vpn-index>
    </vpn-id>
  </vrf>
</vrfs>'

  BLUE_VRF_PROPERTIES3 = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>BLUE</vrf-name>
    <description>Generic external traffic</description>
    <create/>
    <vpn-id>
      <vpn-oui>8</vpn-oui>
      <vpn-index>9</vpn-index>
    </vpn-id>
  </vrf>
</vrfs>'

  GE0_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <interfaces>
    <interface>
      <interface-name>
        GigabitEthernet0/0/0/0
      </interface-name>
      <enable/>
      <values>
        <value>
          <srlg-index>
            10
          </srlg-index>
          <srlg-value>
            100
          </srlg-value>
          <srlg-priority>
            default
          </srlg-priority>
        </value>
        <value>
          <srlg-index>
            20
          </srlg-index>
          <srlg-value>
            200
          </srlg-value>
          <srlg-priority>
            default
          </srlg-priority>
        </value>
      </values>
      <interface-group>
        <enable/>
        <group-names>
          <group-name>
            <group-name-index>
              1
            </group-name-index>
            <group-name>
              2
            </group-name>
            <srlg-priority>
              default
            </srlg-priority>
          </group-name>
        </group-names>
      </interface-group>
    </interface>
  </interfaces>
  <enable/>
</srlg>'

  GE0_NEW_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <interfaces>
    <interface>
      <interface-name>
        GigabitEthernet0/0/0/0
      </interface-name>
      <enable/>
      <values>
        <value>
          <srlg-index>
            20
          </srlg-index>
          <srlg-value>
            200
          </srlg-value>
          <srlg-priority>
            default
          </srlg-priority>
        </value>
        <value>
          <srlg-index>
            90
          </srlg-index>
          <srlg-value>
            900
          </srlg-value>
          <srlg-priority>
            default
          </srlg-priority>
        </value>
      </values>
      <interface-group>
        <enable/>
        <group-names>
          <group-name>
            <group-name-index>
              1
            </group-name-index>
            <group-name>
              9
            </group-name>
            <srlg-priority>
              default
            </srlg-priority>
          </group-name>
        </group-names>
      </interface-group>
    </interface>
  </interfaces>
  <enable/>
</srlg>'

  GE1_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <interfaces>
    <interface>
      <interface-name>
        GigabitEthernet0/0/0/1
      </interface-name>
      <enable/>
    </interface>
  </interfaces>
  <enable/>
</srlg>'

  GE0_GE1_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <interfaces>
    <interface>
      <interface-name>
        GigabitEthernet0/0/0/0
      </interface-name>
      <enable/>
      <values>
        <value>
          <srlg-index>
            10
          </srlg-index>
          <srlg-value>
            100
          </srlg-value>
          <srlg-priority>
            default
          </srlg-priority>
        </value>
        <value>
          <srlg-index>
            20
          </srlg-index>
          <srlg-value>
            200
          </srlg-value>
          <srlg-priority>
            default
          </srlg-priority>
        </value>
      </values>
      <interface-group>
        <enable/>
        <group-names>
          <group-name>
            <group-name-index>
              1
            </group-name-index>
            <group-name>
              2
            </group-name>
            <srlg-priority>
              default
            </srlg-priority>
          </group-name>
        </group-names>
      </interface-group>
    </interface>
    <interface>
      <interface-name>
        GigabitEthernet0/0/0/1
      </interface-name>
      <enable/>
    </interface>
  </interfaces>
  <enable/>
</srlg>'


  GE0_GE1_NEW_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <interfaces>
    <interface>
      <interface-name>
        GigabitEthernet0/0/0/0
      </interface-name>
      <enable/>
      <values>
        <value>
          <srlg-index>
            20
          </srlg-index>
          <srlg-value>
            200
          </srlg-value>
          <srlg-priority>
            default
          </srlg-priority>
        </value>
        <value>
          <srlg-index>
            90
          </srlg-index>
          <srlg-value>
            900
          </srlg-value>
          <srlg-priority>
            default
          </srlg-priority>
        </value>
      </values>
      <interface-group>
        <enable/>
        <group-names>
          <group-name>
            <group-name-index>
              1
            </group-name-index>
            <group-name>
              9
            </group-name>
            <srlg-priority>
              default
            </srlg-priority>
          </group-name>
        </group-names>
      </interface-group>
    </interface>
    <interface>
      <interface-name>
        GigabitEthernet0/0/0/1
      </interface-name>
      <enable/>
    </interface>
  </interfaces>
  <enable/>
</srlg>'

  PATH_VRFS = '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
  PATH_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
  DELETE_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg" xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="delete"/>'

  def setup
    super
    clear_vrfs
    clear_srlg
  end

  def teardown
    super
    clear_vrfs
    clear_srlg
  end

  def format_vrfs_for_delete(vrfs_txt)
    vrfs_doc = REXML::Document.new(vrfs_txt)
    vrfs_doc.context[:attribute_quote] = :quote
    vrfs_doc.elements.each("vrfs/*") do |e|
      e.add_namespace("xmlns:xc", "urn:ietf:params:xml:ns:netconf:base:1.0")
      e.add_attribute("xc:operation", "delete")
    end
    formatter = REXML::Formatters::Pretty.new
    os = StringIO.new
    vrfs_doc.elements.each("vrfs") do |e|
      formatter.write(e, os)
    end
    os.string
  end

  def clear_vrfs
    current_vrfs = node.get(command: PATH_VRFS)
    delete = format_vrfs_for_delete(current_vrfs)
    reply = node.set(context: nil, values: delete)
  end

  def clear_srlg
    current_srlg = node.get(command: PATH_SRLG)
    unless current_srlg.empty? || current_srlg.nil?
      node.set(context: nil, values: DELETE_SRLG)
    end
  end

  def test_delete_vrfs
    node.set(context: nil, values: BLUE_VRF, mode: :merge)
    assert(node.get(command: PATH_VRFS).match('BLUE'), "Did not find the BLUE vrf")

    clear_vrfs
    assert_equal("", node.get(command: PATH_VRFS), "There are still vrfs configured")
  end

  def test_add_vrf
    node.set(context: nil, values: BLUE_VRF, mode: :merge)
    assert(node.get(command: PATH_VRFS).match('BLUE'), "Did not find the BLUE vrf")

    node.set(context: nil, values: GREEN_VRF, mode: :replace)
    path_vrfs = node.get(command: PATH_VRFS)
    assert(path_vrfs.match('GREEN'), "Did not find the GREEN vrf")
    refute(path_vrfs.match('BLUE'), "Found the BLUE vrf")
  end

  def test_merge_leaves
    node.set(context: nil, values: BLUE_VRF, mode: :merge)
    node.set(context: nil, values: BLUE_VRF_PROPERTIES1, mode: :merge)

    # ensure that new leaves are merged with old.
    assert(Cisco::Netconf.insync_for_merge(BLUE_VRF_PROPERTIES2, node.get(command: PATH_VRFS)), "Expected in-sync")

    # update description and vpn-id
    node.set(context: nil, values: BLUE_VRF_PROPERTIES3, mode: :merge)
    assert(Cisco::Netconf.insync_for_merge(BLUE_VRF_PROPERTIES3, node.get(command: PATH_VRFS)), "Expected in-sync")
  end

  def test_merge_srlg
    clear_srlg
    node.set(context: nil, values: GE1_SRLG, mode: :merge)
    assert(Cisco::Netconf.insync_for_merge(GE1_SRLG,
                                           node.get(command: PATH_SRLG)),
           "Expected in-sync")

    node.set(context: nil, values: GE0_SRLG, mode: :merge)
    path_srlg = node.get(command: PATH_SRLG)
    assert(Cisco::Netconf.insync_for_merge(GE0_SRLG,
                                           path_srlg),
           "Expected in-sync")
    assert(Cisco::Netconf.insync_for_merge(GE0_GE1_SRLG,
                                           path_srlg),
           "Expected in-sync")

    node.set(context: nil, values: GE0_NEW_SRLG, mode: :merge)
    path_srlg = node.get(command: PATH_SRLG)
    assert(Cisco::Netconf.insync_for_merge(GE0_NEW_SRLG,
                                           path_srlg),
           "Expected in-sync")
    assert(Cisco::Netconf.insync_for_merge(GE0_GE1_NEW_SRLG,
                                           path_srlg),
           "Expected in-sync")
    refute(Cisco::Netconf.insync_for_merge(GE0_SRLG,
                                           path_srlg),
           "Expected in-sync")
    refute(Cisco::Netconf.insync_for_merge(GE0_GE1_SRLG,
                                           path_srlg),
           "Expected in-sync")
    clear_srlg
  end

  def notest_errors
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
    refute(Cisco::Netconf.insync_for_merge(BLUE_VRF,
                                           node.get(command: PATH_VRFS)),
           "Expected not in-sync")

    node.set(context: nil, values: BLUE_VRF, mode: :merge)

    path_vrfs = node.get(command: PATH_VRFS)
    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Cisco::Netconf.insync_for_merge(BLUE_VRF,
                                           path_vrfs),
           "Expected in-sync")

    # ensure we think that the merge is needed (in-sinc = false)
    refute(Cisco::Netconf.insync_for_merge(RED_VRF,
                                           path_vrfs),
           "Expected not in-sync")

    node.set(context: nil, values: RED_VRF, mode: :merge)

    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Cisco::Netconf.insync_for_merge(RED_VRF,
                                           node.get(command: PATH_VRFS)),
           "Expected in-sync")

    node.set(context: nil, values: GREEN_VRF, mode: :merge)
    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Cisco::Netconf.insync_for_merge(GREEN_VRF,
                                           node.get(command: PATH_VRFS)),
           "Expected in-sync")
  end

  def test_replace_diff
    # ensure we think that a merge is needed (in-sinc = false)
    refute(Cisco::Netconf.insync_for_replace(BLUE_VRF,
                                             node.get(command: PATH_VRFS)), "Expected not in-sync")

    node.set(context: nil, values: BLUE_VRF, mode: :replace)  # create the blue VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Cisco::Netconf.insync_for_replace(BLUE_VRF,
                                             node.get(command: PATH_VRFS)), "Expected in-sync")

    node.set(context: nil, values: RED_VRF, mode: :replace)  # create the red VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Cisco::Netconf.insync_for_replace(RED_VRF,
                                             node.get(command: PATH_VRFS)), "Expected in-sync")

    node.set(context: nil, values: GREEN_VRF, mode: :replace) # create green VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Cisco::Netconf.insync_for_replace(GREEN_VRF,
                                             node.get(command: PATH_VRFS)), "Expected in-sync")

    node.set(context: nil, values: BLUE_VRF, mode: :merge)
    path_vrfs = node.get(command: PATH_VRFS)
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Cisco::Netconf.insync_for_replace(BLUE_GREEN_VRF,
                                             path_vrfs), "Expected in sync")
    # ensure we think that a replace is needed (in-sinc = true)
    refute(Cisco::Netconf.insync_for_replace(BLUE_VRF,
                                             path_vrfs), "Expected not in sync")
    refute(Cisco::Netconf.insync_for_replace(GREEN_VRF,
                                             path_vrfs), "Expected not in sync")

    node.set(context: nil, values: BLUE_VRF, mode: :replace)
    path_vrfs = node.get(command: PATH_VRFS)
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Cisco::Netconf.insync_for_replace(BLUE_VRF,
                                             path_vrfs), "Expected in-sync")
    # ensure we think that a replace is needed (in-sinc = true)
    refute(Cisco::Netconf.insync_for_replace(GREEN_VRF,
                                             path_vrfs), "Expected not in-sync")
    refute(Cisco::Netconf.insync_for_replace(BLUE_GREEN_VRF,
                                             path_vrfs), "Expected not in-sync")
  end

  def test_merge_leaves
    node.set(context: nil, values: BLUE_VRF, mode: :merge)
    node.set(context: nil, values: BLUE_VRF_PROPERTIES1, mode: :merge)

    # ensure that new properties are replaced by old.
    assert(Cisco::Netconf.insync_for_merge(BLUE_VRF_PROPERTIES2,
                                           node.get(command: PATH_VRFS)),
           "Expected in-sync")

    # replace description and vpn-id
    node.set(context: nil, values: BLUE_VRF_PROPERTIES3, mode: :merge)
    assert(Cisco::Netconf.insync_for_merge(BLUE_VRF_PROPERTIES3,
                                           node.get(command: PATH_VRFS)),
           "Expected in-sync")
  end

  def test_replace_leaves
    node.set(context: nil, values: BLUE_VRF, mode: :replace)
    node.set(context: nil, values: BLUE_VRF_PROPERTIES1, mode: :replace)

    # ensure that new properties are replaced by old.
    assert(Cisco::Netconf.insync_for_replace(BLUE_VRF_PROPERTIES1,
                                             node.get(command: PATH_VRFS)),
           "Expected in-sync")

    # replace description and vpn-id
    node.set(context: nil, values: BLUE_VRF_PROPERTIES3, mode: :replace)
    assert(Cisco::Netconf.insync_for_replace(BLUE_VRF_PROPERTIES3,
                                             node.get(command: PATH_VRFS)),
           "Expected in-sync")
  end

  def test_merge
    node.set(context: nil, values: BLUE_VRF, mode: :merge)
    node.set(context: nil, values: GREEN_VRF, mode: :merge)

    assert_yang_equal(BLUE_GREEN_VRF, node.get(command: PATH_VRFS))
  end

  def test_replace
    node.set(context: nil, values: BLUE_VRF, mode: :merge)
    node.set(context: nil, values: GREEN_VRF, mode: :replace)

    assert_yang_equal(GREEN_VRF, node.get(command: PATH_VRFS))
  end

  def assert_yang_equal(expected, actual)
    equal = Cisco::Netconf.insync_for_replace(expected, actual) &&
            Cisco::Netconf.insync_for_replace(actual, expected)
    assert(equal,
      "Expected: '#{expected}',\n"\
      "Actual: '#{actual}',\n"
    )
  end
end
