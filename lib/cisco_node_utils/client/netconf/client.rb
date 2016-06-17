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

require_relative '../client'
require_relative 'netconf_client'

include Cisco::Logger

# Client implementation using Netconf API for IOS XR
class Cisco::Client::NETCONF < Cisco::Client
  register_client(self)

  attr_accessor :timeout

  def initialize(**kwargs)
    super(data_formats: [:xml],
          platform:     :ios_xr,
          **kwargs)

    @login = { :target => kwargs[:host],
      :username => kwargs[:username],
      :password => kwargs[:password]}

    @client = Netconf::Client.new(@login)
    begin
      @client.connect
    rescue => e
      puts "Attempted to connect and got class:#{e.class}/error:#{e}"
      raise_cisco(e)
    end
  end

  def raise_cisco(e)
    # Net::SSH::Disconnect
    # Net::SSH::AuthenticationFailed
    # Errno::EHOSTUNREACH
    # Errno::ECONNREFUSED
    begin
      raise e
    rescue Net::SSH::AuthenticationFailed => e
      raise Cisco::AuthenticationFailed, \
        'Netconf client creation failure: ' + e.message
    rescue Net::SSH::Disconnect
      raise e
    rescue Errno::EHOSTUNREACH
      raise e
    rescue Errno::ECONNREFUSED
      raise Cisco::ConnectionRefused, \
        'Netconf client creation failure: ' + e.message
    rescue Errno::ECONNRESET
      raise e
    end
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

  def set(data_format: :xml,
          context:     nil,
          values:      nil,
          **kwargs)
    begin
      reply = @client.edit_config("candidate", "merge", values)
      if reply.errors?
        fail Cisco::CliError.new( # rubocop:disable Style/RaiseArgs
                                 rejected_input: "apply of #{values}",
                                 clierror:       reply.errors_as_string)
      end
      reply = @client.commit_changes()
      if reply.errors?
        fail Cisco::CliError.new( # rubocop:disable Style/RaiseArgs
                                 rejected_input: "commit of #{values}",
                                 clierror:       reply.errors_as_string)
      end
    rescue => e
      raise_cisco(e)
    end
  end

  def get(data_format: :cli,
          command:     nil,
          context:     nil,
          value:       nil)
    begin
      reply = @client.get_config(command)
      if reply.errors?
        fail Cisco::CliError.new( # rubocop:disable Style/RaiseArgs
                                 rejected_input: command,
                                 clierror:       reply.errors_as_string)
      else
        reply.config_as_string
      end
    rescue => e
      puts e
      raise_cisco(e)
    end
  end

end
