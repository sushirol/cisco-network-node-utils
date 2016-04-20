require_relative 'node_util'
require 'json'

module Cisco
  class VrfYang < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      @name = name.downcase.strip
      create if instantiate
    end

    def self.vrfs
      hash = {}
      vrf = config_getyang('vrfyang', 'all_vrfs')

      return hash if vrf.empty?
      vrf = JSON.parse(vrf)
      vrf_list = vrf['Cisco-IOS-XR-infra-rsi-cfg:vrfs']['vrf']
      return hash if vrf_list.nil?
      vrf_list.each do |id|
        name = id["vrf-name"]
        hash[name] = VrfYang.new(name, false)
      end
      hash
    end

    def create
      config_setyang('vrfyang', 'create', vrf: @name)
    end

    def destroy
      config_rmyang('vrfyang', 'destroy', vrf: @name)
    end

    def description
      vrf_desc = config_getyang('vrfyang', 'description', vrf: @name)
      return "" if vrf_desc.empty?
      m_desc = JSON.parse(vrf_desc)
      desc = m_desc['Cisco-IOS-XR-infra-rsi-cfg:vrfs']['vrf'][0]['description']
      return "" if desc[0].nil?
      desc
    end

    def description=(desc)
      fail TypeError unless desc.is_a?(String)
      desc.strip!
      no_cmd = desc.empty? ? 'no' : ""
      config_setyang('vrfyang', 'description', vrf: @name, state: no_cmd, desc: desc)
    end

    def default_description
      vrf_desc = config_get_default('vrfyang', 'description')
      return "" if vrf_desc.empty?
      vrf_desc

    end

    def shutdown
      config_get('vrfyang', 'shutdown', vrf: @name)
    end

    def shutdown=(val)
      no_cmd = (val) ? '' : 'no'
      config_setyang('vrfyang', 'shutdown', vrf: @name, state: no_cmd)
    end

    def default_shutdown
      config_get_default('vrfyang', 'shutdown')
    end

    # route_distinguisher
    # Note that this property is supported by both bgp and vrf providers.
    def route_distinguisher
      config_get('vrfyang', 'route_distinguisher', vrf: @name)
    end

    def route_distinguisher=(rd)
      # feature bgp and nv overlay required for rd cli in NXOS
      if platform == :nexus
        Feature.bgp_enable
        Feature.nv_overlay_enable      # TBD: Only req'd for n7k?
        Feature.nv_overlay_evpn_enable # TBD: Only req'd for n7k?
      end
      if rd == default_route_distinguisher
        state = 'no'
        rd = ''
      else
        state = ''
      end
      config_set('vrfyang', 'route_distinguisher', state: state, vrf: @name, rd: rd)
    end

    def default_route_distinguisher
      config_get_default('vrfyang', 'route_distinguisher')
    end

    # Vni (Getter/Setter/Default)
    def vni
      config_get('vrfyang', 'vni', vrf: @name)
    end

    def vni=(id)
      Feature.vn_segment_vlan_based_enable if platform == :nexus
      no_cmd = (id) ? '' : 'no'
      id = (id) ? id : vni
      config_set('vrfyang', 'vni', vrf: @name, state: no_cmd, id: id)
    end

    def default_vni
      config_get_default('vrfyang', 'vni')
    end
  end
end
