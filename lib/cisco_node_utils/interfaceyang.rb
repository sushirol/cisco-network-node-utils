require_relative 'node_util'
require 'json'

module Cisco
  class InterfaceYang < NodeUtil
    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name.downcase
      create if instantiate
    end

    def self.interfaces
      hash = {}
      intf = config_getyang('interfaceyang', 'all_interfaces')
      puts "out put is ====> #{intf}"
      intf = JSON.parse(intf)

      intf_list = intf['Cisco-IOS-XR-ifmgr-cfg:interface-configurations']['interface-configuration']
      return hash if intf_list.nil?
      intf_list.each do |id|
        name = id["interface-name"]
        hash[name] = InterfaceYang.new(name, false)
      end
      hash
    end
  end
end
