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

require 'net/ssh'
require 'rexml/document'

module Netconf
  class SSH
    def initialize(args)
      @args = args.clone
      @channel = nil
      @connection = nil
    end

    def open (subsystem)
      ssh_args = Hash.new
      ssh_args[:password] ||= @args[:password]
      ssh_args[:port] = @args[:port]
      ssh_args[:number_of_password_prompts] = 0
      # Debugs, yay
      # ssh_args[:verbose] = :debug

      @connection = Net::SSH.start(@args[:target],
                                   @args[:username],
                                   ssh_args)
      @channel = @connection.open_channel do |ch|
        ch.subsystem(subsystem)
      end
    end

    def close ()
      @channel.close unless @channel.nil?
      @connection.close unless @connection.nil?
      @channel = nil
      @connection = nil
    end

    def send (data)
      @channel.send_data(data)
    end

    def receive (parser)
      continue = true

      @channel.on_data do |ch, data|
        result = parser.call(data)
        # If parser returns :stop, we take that as a hint to stop
        # expecting data for this message.
        #
        # If parser returns :continue (or anything other than :stop),
        # then we presume the parser is collecting data segments
        # and looking for enough to parse a full "thing"
        continue = false if result == :stop
      end

      @channel.on_extended_data do |ch, type, data|
        continue = false
      end

      # Loop is executed until on_data or on_extended_data 
      # sets continue to false
      @connection.loop {continue}
    end
  end # class SSH

  module Format
    DEFAULT_NAMESPACE = "\"urn:ietf:params:xml:ns:netconf:base:1.0\""

    HELLO =
      "<hello xmlns=#{DEFAULT_NAMESPACE}>" +
      "  <capabilities>\n" +
      "    <capability>urn:ietf:params:netconf:base:1.1</capability>\n" +
      "  </capabilities>\n" +
      "</hello>\n" +
      "]]>]]>\n"

    def self.format_msg (body)
      "##{body.length}\n#{body}\n##\n\n"
    end

    def self.format_close_session (message_id)
      body =
        "<rpc message-id=\"#{message_id}\" xmlns=#{DEFAULT_NAMESPACE}>\n" +
        "   <close-session/>\n" +
        " </rpc>\n"
      format_msg(body)
    end

    def self.format_commit_msg (message_id)
      body =
        "<rpc message-id=\"#{message_id}\" xmlns=#{DEFAULT_NAMESPACE}>\n" +
        "  <commit/>\n" +
        "</rpc>\n"
      format_msg(body)
    end

    def self.format_get_msg (message_id, nc_filter)
      body =
        "<rpc message-id=\"#{message_id}\" xmlns=#{DEFAULT_NAMESPACE}>\n" +
        "  <get>\n" +
        "    <filter>\n" +
        "    #{nc_filter}\n" +
        "    </filter>\n" +
        "  </get>\n" +
        "</rpc>\n"
      format_msg(body)
    end

    def self.format_get_config_msg (message_id, nc_filter)
      body =
        "<rpc message-id=\"#{message_id}\" xmlns=#{DEFAULT_NAMESPACE}>\n" +
        "  <get-config>\n" +
        "    <source><running/></source>\n" +
        "    <filter>\n" +
        "      #{nc_filter}\n" +
        "    </filter>\n" +
        "  </get-config>\n" +
        "</rpc>\n"
      format_msg(body)
    end

    def self.format_get_config_all_msg (message_id)
      body =
        "<rpc message-id=\"#{message_id}\" xmlns=#{DEFAULT_NAMESPACE}>\n" +
        "  <get-config>\n" +
        "    <source><running/></source>\n" +
        "  </get-config>\n" +
        "</rpc>\n"
      format_msg(body)
    end

    def self.format_edit_config_msg_with_config_tag (message_id, default_operation, target, config)
      body =
        "<rpc message-id=\"#{message_id}\" xmlns=#{DEFAULT_NAMESPACE}>\n" +
        "  <edit-config>\n" +
        "    <target><#{target}/></target>\n" +
        "    <default-operation>#{default_operation}</default-operation>\n" +
        "      #{config}\n" +
        "  </edit-config>\n" +
        "</rpc>\n"
      format_msg(body)
    end

    def self.format_edit_config_msg (message_id, default_operation, target, config)
      format_edit_config_msg_with_config_tag(message_id, default_operation, target,
                                             "<config xmlns=#{DEFAULT_NAMESPACE}>#{config}</config>")
    end
  end

  class InternalError < StandardError
  end

  class ParseException < StandardError
  end

  class SSHNotConnected < StandardError
  end

  class Client
    public

    class RpcResponse
      private

      def initialize (rpc_reply)
        if rpc_reply.is_a?(String)
          @errors = Array.new
          @doc = REXML::Document.new(rpc_reply, ignore_whitespace_nodes: :all)
          @doc.context[:attribute_quote] = :quote
          @doc.elements.each("rpc-reply/rpc-error") do |e|
            ht = Hash.new
            e.children.each { |ec| ht[ec.name] = ec.text }
            @errors << ht
          end
        else
          @errors = Array.new
          @transport_errors = rpc_reply
        end
      end

      public
      def errors
        @errors
      end

      def errors_as_string
        s = StringIO.new
        @errors.each do |e|
          e.each do |k, v|
            s.write("#{k} => #{v}\n")
          end
        end
        s.string
      end

      def errors?
        not @errors.empty?
      end

      def response
        @doc
      end
    end

    class GetConfigResponse < RpcResponse
      private

      def initialize (rpc_reply)
        super(rpc_reply)
        if rpc_reply.is_a?(String)
          @config = Array.new
          formatter = REXML::Formatters::Pretty.new()
          @doc.elements.each("rpc-reply/data/*") do |e|
            o = StringIO.new
            formatter.write(e, o)
            @config << o.string
          end
        else
          @config = Array.new
        end
      end

      public
      def config()
        @config
      end

      def config_as_string()
        o = StringIO.new
        @config.each do |ce|
          o.write(ce)
        end
        o.string
      end
    end

    class CommitResponse < RpcResponse
      private
      def initialize(rpc_reply)
        super(rpc_reply)
      end
    end

    class EditConfigResponse < RpcResponse
      private
      def initialize(rpc_reply)
        super(rpc_reply)
      end
    end

    private

    # Implements a parser for RFC 6242 Netconf/SSH Hello
    # packets.  (Should also work for Netconf 1.0, untested
    # for that purpose).
    def hello_parser(buff)
      buffering_data = StringIO.new
      parser = lambda do |data|
        data = buffering_data.string + data
        buffering_data.reopen("")
        i = data.index(']')
        if i.nil?
          buff.write(data)
          :continue
        else
          if i != 0
            buff.write(data[0..(i-1)])
            parser.call(data[i..-1])
          else
            if data.length >= 5
              if data[0..4] == "]]>]]"
                :stop
              else
                buff.write("]")
                parser.call(data[1..-1])
              end
            else
              buffering_data.write(data)
              :continue
            end
          end
        end
      end
      parser
    end

    def chunk_start_partially_parses?(data)
      case data.length
      when 1
        data == "\n"
      when 2
        data == "\n#"
      when 3..12
        /\n#[1-9][0-9]{,9}$/m.match(data) != nil
      else
        false
      end
    end

    # Implements a parser for RFC 6242 Netconf/SSH framing.
    def netconf_1_1_parser(buff)
      state = :scanning_for_LF_HASH
      bytes_left = 0
      buffering_data = StringIO.new
      parser = lambda do |data|
        data = buffering_data.string + data
        buffering_data.reopen("")
        case state
        when :scanning_for_LF_HASH
          if data.length >= 3
            if data[0..1] != "\n#"
              fail ParseException, "expected LF HASH, but didn't get one with #{data}"
            else
              if data[2] == "#"
                state = :scanning_for_end_of_chunks
              else
                state = :scanning_for_chunk_start
              end
              parser.call(data)
            end
          else
            buffering_data.write(data)
            :continue
          end
        when :scanning_for_chunk_start
          # RFC 6242
          #  The chunk-size field is a string of decimal digits indicating the
          #  number of octets in chunk-data.  Leading zeros are prohibited, and
          #  the maximum allowed chunk-size value is 4294967295.
          #
          md = /\n#([1-9][0-9]{,9})\n/m.match(data)
          if md.nil?
            if chunk_start_partially_parses?(data)
              buffering_data.write(data)
              :continue
            else
              fail ParseException, "expected match for chunk_start, didn't get one with #{data}"
            end
          else
            # Jump to scanning_for_chunk_data state
            # Set bytes_left to value of chunk size
            state = :scanning_for_chunk_data
            bytes_left = Integer("#{md[1]}")
            if bytes_left > 4294967295
              fail ParseException, "chunk size #{bytes_left} is larger than 4294967295"
            end
            
            # Handle remaining data
            parser.call(data[md[1].length + 3..-1])
          end
        when :scanning_for_chunk_data
          if data.length >= bytes_left
            buff.write(data[0..bytes_left])

            # Handle remaining data
            state = :scanning_for_LF_HASH
            parser.call(data[bytes_left..-1])
          else
            buff.write(data[0..-1])
            bytes_left = bytes_left - data.length
            :continue
          end
        when :scanning_for_end_of_chunks
          if data.length >= 4
            md = /\n##\n/m.match(data)
            if md.nil?
              fail ParseException, "unexpected: Did not receive the end of chunks sequence LF HASH HASH LF in #{data}"
            else
              :stop
            end
          else
            buffering_data.write(data)
            :continue
          end
        else
          fail InternalError, "unexpected state: #{state}"
        end # End case
      end # End Lambda named parser
      return parser
    end

    def connect_internal
      begin
        @message_id = Integer(1)
        @ssh = SSH.new(@login)
        @ssh.open("netconf")
        @ssh.send(Format::HELLO)
        buff = StringIO.new
        # NB: Throwing the capabilities list on the floor here,
        #     since this is only for XR based netconf, and in
        #     the puppet context, this is fine
        @ssh.receive(hello_parser(buff))
      rescue => e
        # It's possible to get these exceptions (maybe more)
        #
        # Net::SSH::Disconnect
        # Net::SSH::AuthenticationFailed
        # Errno::EHOSTUNREACH
        # Errno::ECONNREFUSED
        @ssh = nil
        fail e
      end
    end

    def tx_request_and_rx_reply_internal(msg)
      fail SSHNotConnected.new unless @ssh
      @ssh.send(msg)
      buff = StringIO.new
      @ssh.receive(netconf_1_1_parser(buff))
      @message_id = @message_id + 1
      return buff.string
    end

    def tx_request_and_rx_reply(msg)
      begin
        tx_request_and_rx_reply_internal(msg)
      rescue Net::SSH::Disconnect => e
        if @options.key?(:no_reconnect)
          fail e
        else
          connect_internal
          tx_request_and_rx_reply_internal(msg)
        end
      end
    end

    public

    def connect()
      connect_internal
    end

    def initialize(login, options = {})
      @login = login
      @ssh = nil
      @options = options
    end

    def get(filter)
      msg = Format::format_get_msg(@message_id, filter)
      RpcResponse.new(tx_request_and_rx_reply(msg))
    end

    def get_config(filter)
      if filter == "" || filter.nil?
        msg = Format::format_get_config_all_msg(@message_id)
      else
        msg = Format::format_get_config_msg(@message_id, filter)
      end
      GetConfigResponse.new(tx_request_and_rx_reply(msg))
    end

    def edit_config(target, default_operation, config)
      msg = Format::format_edit_config_msg(@message_id,
                                           default_operation,
                                           target,
                                           config)
      EditConfigResponse.new(tx_request_and_rx_reply(msg))
    end

    def commit_changes()
      CommitResponse.new(tx_request_and_rx_reply(Format::format_commit_msg(@message_id)))
    end

    def stop()
      tx_request_and_rx_reply(Format::format_close_session(@message_id))
    end
  end
end

=begin

# SAMPLE USAGE

red_vrf =
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
     <vrf>
      <vrf-name>red</vrf-name>
      <create></create>
      <description>foo</description>
      <vpn-id>
        <vpn-oui>2</vpn-oui>
        <vpn-index>2</vpn-index>
      </vpn-id>
      <remote-route-filter-disable></remote-route-filter-disable>
     </vrf>
   </vrfs>'

rds = "<vrfs xmlns='http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg'>
  <vrf xmlns:xc='urn:ietf:params:xml:ns:netconf:base:1.0' xc:operation='delete'>
    <vrf-name>
       BLUE 
    </vrf-name>
    <create/>
    <description>
       Generic external traffic 
    </description>
  </vrf>
</vrfs>"

delete_red_vrf =
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
     <vrf xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="delete">
      <vrf-name>red</vrf-name>
      <create></create>
      <description>foo</description>
      <vpn-id>
        <vpn-oui>2</vpn-oui>
        <vpn-index>2</vpn-index>
      </vpn-id>
      <remote-route-filter-disable></remote-route-filter-disable>
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

vrf_filter = '<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
srlg_filter = '<infra-rsi-cfg:srlg xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'

login = { :target => '192.168.1.16',
  :username => 'root',
  :password => 'lab'}
#filter = vrf_filter
filter = srlg_filter
#puts "NC client starting"
ncc = Netconf::Client.new(login)
begin
  #puts "NC client connecting"
  ncc.connect
rescue => e
  puts "Attempted to connect and got #{e.class}/#{e}"
  exit
end

require 'pry'
require 'pry-nav'

#filter = '<inventory xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-invmgr-oper"/>'
#filter = '<inventory xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-invmgr-oper-sub1"/>'
filter = '<inventory xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-invmgr-oper"/>'
reply = ncc.get(filter)
revision = nil
formatter = REXML::Formatters::Pretty.new()
o = StringIO.new
#formatter.write(reply.response, o)
#puts o.string
#exit
#binding.pry
#reply.response.elements.each("rpc-reply/data/inventory/racks/rack/entity/slot/tsi1s/tsi1/attributes/inv-basic-bag/model-name") do |e|
reply.response.elements.each("rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/*") do |e|
  puts "name: #{e.name}, text: #{e.text}"

end
exit
name = ""
reply.response.elements.each("rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/name") do |e|
  name = e.text
end
product_id = ""
reply.response.elements.each("rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/model-name") do |e|
  product_id = e.text
end
software_revision = ""
reply.response.elements.each("rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/software-revision") do |e|
  software_revision = e.text
end

puts name
puts product_id
puts software_revision
exit

#filter = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-oper"/>'
filter = '<inventory xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-invmgr-oper"/>'
reply = ncc.get(filter)
#binding.pry
formatter = REXML::Formatters::Pretty.new()
o = StringIO.new
#reply.response.elements.each("rpc-reply/data/inventory/racks/*") do |e|
revision = nil
reply.response.elements.each("rpc-reply/data/inventory/racks/rack/entity/slot/tsi1s/tsi1/attributes/inv-basic-bag/software-revision") do |e|
  if e.text != nil
    revision = e.text
  end
  #formatter.write(e, o)
end
puts revision
#puts o.string
exit

puts "NC client connected"
#reply = ncc.get_config(vrf_filter)
reply = ncc.get_config(nil)
puts reply.config_as_string
exit


reply = ncc.edit_config("candidate", "merge", rds)
puts "edit_config response errors"
reply.errors.each do |e|
  puts "Error:"
  e.each { |k,v| puts "#{k} - #{v}" }
end
reply = ncc.commit_changes()
puts "commit_changes response errors"
reply.errors.each do |e|
  puts "Error:"
  e.each { |k,v| puts "#{k} - #{v}" }
end

exit

# Add the red vrf
reply = ncc.edit_config("candidate", "merge", red_vrf)
puts "edit_config response errors"
reply.errors.each do |e|
  puts "Error:"
  e.each { |k,v| puts "#{k} - #{v}" }
end
reply = ncc.commit_changes()
puts "commit_changes response errors"
reply.errors.each do |e|
  puts "Error:"
  e.each { |k,v| puts "#{k} - #{v}" }
end

reply = ncc.edit_config("candidate", "merge", delete_red_vrf)
puts "edit_config response errors"
reply.errors.each do |e|
  puts "Error:"
  e.each { |k,v| puts "#{k} - #{v}" }
end
reply = ncc.commit_changes()
puts "commit_changes response errors"
reply.errors.each do |e|
  puts "Error:"
  e.each { |k,v| puts "#{k} - #{v}" }
end

=end

