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
      ret = []
      continue = true

      @channel.on_data do |ch, data|
        result = parser.call(data)
        # If parser returns :stop, we take that as a hint to stop
        # expecting data for this message.
        #
        # If parser returns :continue, then we presume the parser
        # is collecting data segments and looking for enough to
        # parse a full "thing"
        #
        # If parser returns something else, then we presume the
        # parser wants us to hold onto it for them, we'll
        # add it to an array and return it when done.
        continue = false if result == :stop
        if result != :continue && result != :stop
          ret << result
        end
      end

      @channel.on_extended_data do |ch, type, data|
        continue = false
      end

      # Loop is executed until on_data sets continue to false
      @connection.loop {continue}

      ret
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
        "    #{nc_filter}\n" +
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

    def hello_parser(buff)
      lambda do |data|
        md = /(?=\]\]>\]\])/m.match(data)
        if md.nil?
          buff.write(data)
          :continue
        else
          md = /^(?=.*?\b.*\b)((?!\]\]>\]\]).)*$/m.match(data)
          # NB: Using anything except this includes the "]]>]]>" for some reason, revisit
          buff.write("#{md}")
          :stop
        end
      end
    end

    def netconf_1_1_parser(buff)
      state = :scanning_for_LF_HASH
      bytes_left = 0
      buffering_data = StringIO.new

      parser = lambda do |data|
        data = data + buffering_data.string
        buffering_data.truncate(0)
        case state
        when :scanning_for_LF_HASH
          if data.length >= 3
            md = /\n#/m.match(data)
            if data[0-1] == "\n#"
              raise ParseException, "expected LF HASH, but didn't get one with #{data}"
            else
              if data[2] == "#"
                state = :scanning_for_end_of_chunks
              else
                state = :scanning_for_chunk_start
              end
              # NB: Not pruning data here, should change it to do so since
              #     the first two bytes have been parsed.
              parser.call(data)
            end
          else
            buffering_data.write(data)
            :continue
          end
        when :scanning_for_chunk_start
          md = /\n#(\d+)\n/m.match(data)
          if md.nil?
            raise ParseException, "expected match for chunk_start, didn't get one with #{data}"
          else
            # Jump to scanning_for_chunk_data state
            # Set bytes_left to value of chunk size
            state = :scanning_for_chunk_data
            bytes_left = Integer("#{md[1]}")

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
          md = /\n##\n/m.match(data)
          if md.nil?
            raise ParseException, "unexpected: Did not receive the end of chunks sequence LF HASH HASH LF"
          else
            :stop
          end
        else
          raise InternalError, "unexpected state: #{state}"
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
        # It's possible to get these exceptions
        #
        # Net::SSH::Disconnect
        # Net::SSH::AuthenticationFailed
        # Errno::EHOSTUNREACH
        # Errno::ECONNREFUSED
        @ssh = nil
        raise e
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
          raise e
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
      msg = Format::format_get_config_msg(@message_id, filter)
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
     </vrf>
   </vrfs>'

delete_red_vrf =
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
     <vrf xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="delete">
      <vrf-name xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="delete">red</vrf-name>
      <create></create>
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

login = { :target => '192.168.1.16',
  :username => 'root',
  :password => 'lab'}
filter = '<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
#filter = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
ncc = Netconf::Client.new(login)
begin
  ncc.connect
rescue => e
  puts "Attempted to connect and got #{e.class}/#{e}"
  exit
end
=begin
reply = ncc.get(nil)
reply.response.each do |re|
  puts re
end
exit

begin
  #reply = ncc.get_config(filter)
   reply = ncc.get_config(nil)
rescue => e
  puts "Attempted to get configuration and got #{e.class}/#{e}"
  exit
end

reply.config.each { |c|
  puts "config element"
#  puts c
}

puts "config as string:\n #{reply.config_as_string}"

exit



# ... did not finish the begin/rescue/end pattern below, imagine it

puts "config response from #{filter}"
reply.errors.each do |e|
  puts "Error:"
  e.each { |k,v| puts "#{k} - #{v}" }
end
reply.config.each { |c| puts c }

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

# Show the config we just added
reply = ncc.get_config(vrf_filter)
reply.config.each { |c| puts c }

# Delete the VRF
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

puts "Sleeping for 65 seconds to give you time to disable SSH on the router"
sleep(65)

# Show the config we just removed
reply = ncc.get_config(vrf_filter)
reply.config.each { |c| puts c }

# Delete the VRF
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
