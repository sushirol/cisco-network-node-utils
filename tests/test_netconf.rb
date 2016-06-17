#!/usr/bin/env ruby
#
# June 2016, Sushrut Shirole
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

require_relative 'basetest'

# Test case for Cisco::Client::NETCONF::Client class
class TestNetconf < TestCase
  @@client = nil # rubocop:disable Style/ClassVars
  @@red_vrf = \
    "<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\">\n  <vrf>\n    <vrf-name>\n      red\n    </vrf-name>\n    <create/>\n  </vrf>\n</vrfs>"
  @@blue_vrf = \
      "<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\">\n  <vrf>\n    <vrf-name>\n      blue\n    </vrf-name>\n    <create/>\n  </vrf>\n</vrfs>"
  @@root_vrf = '<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
  @@invalid = '<infra-rsi-cfg:vrfs-invalid xmlns:infra-rsi-cfg-invalid="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg-invalid"/>'

  def self.runnable_methods
    # If we're pointed to an Netconf node (as evidenced by a port num 830)
    # then these tests don't apply
    return [:all_skipped] unless (Cisco::Environment.environment[:port] == 830)
    super
  end

  def all_skipped
    skip 'Node under test does not appear to use the Netconf client'
  end

  def client
    unless @@client
      client = Cisco::Client::NETCONF.new(Cisco::Environment.environment)
      client.cache_enable = true
      client.cache_auto = true
      @@client = client # rubocop:disable Style/ClassVars
    end
    @@client
  end

  def test_auth_failure
    env = Cisco::Environment.environment.merge(password: 'wrong password')
    e = assert_raises Cisco::AuthenticationFailed do
      Cisco::Client::NETCONF.new(**env)
    end
    assert_equal('Netconf client creation failure: Authentication failed for user ' + Cisco::Environment.environment[:username] + '@' + Cisco::Environment.environment[:host],
                 e.message)
  end

  def test_connection_failure
    # Failure #1: connecting to a host that's listening for a non-Netconf protocol
    env = Cisco::Environment.environment.merge(host: '1.1.1.1')
    e = assert_raises Cisco::YangError do
      Cisco::Client::NETCONF.new(**env)
    end
    assert_match('No route to host - connect(2)',
                 e.message)
  end

  def test_set_string
    client.set(context: nil,
               values: @@red_vrf,
               mode: :replace)
    run = client.get(command: @@root_vrf)
    assert_match(@@red_vrf, run)
  end

  def test_set_invalid
    e = assert_raises Cisco::YangError do
      client.set(context: nil,
                 values:  @@invalid)
    end
    # rubocop:disable Style/TrailingWhitespace
    assert_equal('The config \'apply of <infra-rsi-cfg:vrfs-invalid xmlns:infra-rsi-cfg-invalid="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg-invalid"/>\' was rejected with error:
error-type => rpc
error-tag => malformed-message
error-severity => error
', e.message)
    ## rubocop:enable Style/TrailingWhitespace
    ## Unlike NXAPI, a Netconf config command is always atomic
    assert_empty(e.successful_input)
    assert_equal('apply of <infra-rsi-cfg:vrfs-invalid xmlns:infra-rsi-cfg-invalid="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg-invalid"/>', e.rejected_input)
  end

  def test_get_invalid
    assert_raises Cisco::YangError do
      client.get(command: @@invalid)
    end
  end

  def test_get_incomplete
    assert_raises Cisco::YangError do
      client.get(command: @@invalid)
    end
  end

  def test_get_empty
    result = client.get(command: @@blue_vrf)
    assert_empty(result)
  end

  # TODO: add structured output test cases (when supported on XR)
  def test_smart_create
    autoclient = Cisco::Client.create
    assert_equal(Cisco::Client::NETCONF, autoclient.class)
    assert(autoclient.supports?(:xml))
    refute(autoclient.supports?(:nxapi_structured))
    assert_equal(:ios_xr, autoclient.platform)
  end
end
