#!/usr/bin/env ruby
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
require_relative '../lib/cisco_node_utils/vrfyang'
require 'cisco_node_utils' 

# TestRouterBgp - Minitest for RouterBgp class
class TestVrfYang < CiscoTestCase
  VRF_NAME_SIZE = 33

  def test_create
    node = Cisco::Node.instance
    #vrfs= node.getyang(command: '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}', value: '[null]')
    #puts vrfs

    node.setyang(values: '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": {"vrf" : [{"vrf-name" : "grey", "create" : null}, {"vrf-name" : "white", "create" : null}]}}')
    #node.rmyang(values: '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": {"vrf" : {"vrf-name" : "yellow"}}}')
  end

end
