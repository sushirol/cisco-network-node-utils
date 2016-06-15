#!/usr/bin/env ruby
#
# October 2015, Glenn F. Matthews
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

require_relative '../client'
require_relative 'netconf_client'

include Cisco::Logger

# Client implementation using Netconf API for IOS XR
class Cisco::Client::NETCONF < Cisco::Client
  register_client(self)

  attr_accessor :timeout

  def initialize(**kwargs)
    # Defaults for netconf:
    kwargs[:port] ||= '830'
    puts "NETCONF initalize"
    super(data_formats: [:xml],
          platform:     :ios_xr,
          **kwargs)
    @login = { :target => '192.168.1.16',
      :username => 'root',
      :password => 'lab'}
    @client = Netconf::Client.new(@login)
    filter = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
    reply = @client.get_config(filter)
    puts "config response from #{filter}"
    reply.errors.each do |e|
      puts "Error:"
      e.each { |k,v| puts "#{k} - #{v}" }
    end
    reply.config.each { |c| puts c }
  end

  def self.validate_args(**kwargs)
    super
    base_msg = 'Netconf client creation failure: '
    # Connection to remote system - username and password are required
    fail TypeError, base_msg + 'username must be specified' \
      if kwargs[:username].nil?
    fail TypeError, base_msg + 'password must be specified' \
      if kwargs[:password].nil?
  end

  def set_xml(data_format: :xml,
          context:     nil,
          values:      nil,
          **kwargs)
    super
    red_vrf =
      '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
         <vrf>
          <vrf-name>red</vrf-name>
          <create></create>
         </vrf>
       </vrfs>'
    reply = @connect.edit_config("candidate", "merge", red_vrf)
    puts "edit_config response errors"
    reply.errors.each do |e|
      puts "Error:"
      e.each { |k,v| puts "#{k} - #{v}" }
    end
    reply = @client.commit_changes()
    puts "commit_changes response errors"
    reply.errors.each do |e|
      puts "Error:"
      e.each { |k,v| puts "#{k} - #{v}" }
    end
  end

  def get_xml(data_format: :cli,
          command:     nil,
          context:     nil,
          value:       nil)
    super
    vrf_filter = '<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
    reply = @client.get_config(vrf_filter)
    reply.config.each { |c| puts c }
  end

end
