require_relative 'node_util'

module Cisco
  class Yang < NodeUtil
    def initialize
      debug "---- test yang ----"
      ypath = '{"Cisco-IOS-XR-ifmgr-cfg:interface-configurations":[null]}'
      op = getyang(command: "#{ypath}")
      puts op
    end
  end
end
