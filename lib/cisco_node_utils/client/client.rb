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

require_relative '../exceptions'
require_relative 'utils'
require_relative '../constants'
require_relative '../logger'

include Cisco::Logger

# Base class for clients of various RPC formats
class Cisco::Client
  @@clients = [] 

  def self.clients
    @@clients
  end

  # Each subclass should call this method to register itself.
  def self.register_client(client)
    @@clients << client
  end

  attr_reader :data_formats, :platform

  def initialize(address:      nil,
                 username:     nil,
                 password:     nil,
                 data_formats: [],
                 platform:     nil)
    if self.class == Cisco::Client
      fail NotImplementedError, 'Cisco::Client is an abstract class. ' \
        "Instantiate one of #{@@clients} or use Cisco::Client.create() instead"
    end
    validate_args(address, username, password)
    @address = address
    @username = username
    @password = password
    self.data_formats = data_formats
    self.platform = platform
  end

  def validate_args(address, username, password)
    unless address.nil?
      fail TypeError, 'invalid address' unless address.is_a?(String)
      fail ArgumentError, 'empty address' if address.empty?
    end
    unless username.nil?
      fail TypeError, 'invalid username' unless username.is_a?(String)
      fail ArgumentError, 'empty username' if username.empty?
    end
    unless password.nil? # rubocop:disable Style/GuardClause
      fail TypeError, 'invalid password' unless password.is_a?(String)
      fail ArgumentError, 'empty password' if password.empty?
    end
  end

  def supports?(data_format)
    data_formats.include?(data_format)
  end

  # Try to create an instance of an appropriate subclass
  def self.create(address=nil, username=nil, password=nil)
    fail 'No client implementations available!' if clients.empty?
    debug "Trying to establish client connection. clients = #{clients}"
    errors = []
    clients.each do |client_class|
      begin
        debug "Trying to connect to #{address} as #{client_class}"
        client = client_class.new(address, username, password)
        debug "#{client_class} connected successfully"
        return client
      rescue Cisco::ClientError, TypeError, ArgumentError => e
        debug "Unable to connect to #{address} as #{client_class}: #{e.message}"
        debug e.backtrace.join("\n  ")
        errors << e
      end
    end
    handle_errors(errors)
  end

  def self.handle_errors(errors)
    # ClientError means we tried to connect but failed,
    # so it's 'more significant' than input validation errors.
    client_errors = errors.select { |e| e.kind_of? Cisco::ClientError }
    if !client_errors.empty?
      # Reraise the specific error if just one
      fail client_errors[0] if client_errors.length == 1
      # Otherwise clump them together into a new error
      e_cls = client_errors[0].class
      unless client_errors.all? { |e| e.class == e_cls }
        e_cls = Cisco::ClientError
      end
      fail e_cls, ("Unable to establish any client connection:\n" +
                   errors.each(&:message).join("\n"))
    elsif errors.any? { |e| e.kind_of? ArgumentError }
      fail ArgumentError, ("Invalid arguments:\n" +
                           errors.each(&:message).join("\n"))
    elsif errors.any? { |e| e.kind_of? TypeError }
      fail TypeError, ("Invalid arguments:\n" +
                       errors.each(&:message).join("\n"))
    end
    fail Cisco::ClientError, 'No client connected, but no errors were reported?'
  end

  def to_s
    @address.to_s
  end

  def inspect
    "<#{self.class} of #{@address}>"
  end

  private

  # Set the list of data formats supported by this client.
  # If the client supports multiple formats, and a given feature or property
  # can be managed by multiple formats, the list order indicates preference.
  def data_formats=(data_formats)
    data_formats = [data_formats] unless data_formats.is_a?(Array)
    unknown = data_formats - Cisco::DATA_FORMATS
    fail ArgumentError, "unknown data formats: #{unknown}" unless unknown.empty?
    @data_formats = data_formats
  end

  # Set the platform of the node managed by this client.
  def platform=(platform)
    fail ArgumentError, "unknown platform #{platform}" \
      unless Cisco::PLATFORMS.include?(platform)
    @platform = platform
  end
end
