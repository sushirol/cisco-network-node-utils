#
# NXAPI implementation of Router OSPF Area class
#
# June 2016, Sai Chintalapudi
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

require 'ipaddr'
require_relative 'node_util'
require_relative 'router_ospf'
require_relative 'router_ospf_vrf'

module Cisco
  # node_utils class for ospf_area
  class RouterOspfArea < NodeUtil
    attr_reader :router, :vrf, :area_id

    def initialize(ospf_router, vrf_name, area_id, instantiate=true)
      fail TypeError unless ospf_router.is_a?(String)
      fail TypeError unless vrf_name.is_a?(String)
      fail ArgumentError unless ospf_router.length > 0
      fail ArgumentError unless vrf_name.length > 0
      @area_id = area_id.to_s
      fail ArgumentError if @area_id.empty?

      Feature.ospf_enable if instantiate
      # Convert to dot-notation

      @router = ospf_router
      @vrf = vrf_name
      @area_id = IPAddr.new(area_id.to_i, Socket::AF_INET) unless @area_id[/\./]

      set_args_keys_default
    end

    def self.areas
      hash = {}
      RouterOspf.routers.each do |name, _obj|
        # get all area ids under default vrf
        area_ids = config_get('ospf_area', 'areas', name: name)
        if area_ids
          hash[name] = {}
          hash[name]['default'] = {}
          area_ids.uniq.each do |area|
            hash[name]['default'][area] =
              RouterOspfArea.new(name, 'default', area, false)
          end
        end
        vrf_ids = config_get('ospf', 'vrf', name: name)
        next if vrf_ids.nil?
        vrf_ids.each do |vrf|
          # get all area ids under each vrf
          area_ids = config_get('ospf_area', 'areas', name: name, vrf: vrf)
          next if area_ids.nil?
          hash[name] ||= {}
          hash[name][vrf] = {}
          area_ids.uniq.each do |area|
            hash[name][vrf][area] =
              RouterOspfArea.new(name, vrf, area, false)
          end
        end
      end
      hash
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @router, area: @area_id }
      @set_args[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    def destroy
      return unless Feature.ospf_enabled?
      [:authentication,
       :default_cost,
       :filter_list_in,
       :filter_list_out,
       :range,
       :stub,
      ].each do |prop|
        send("#{prop}=", send("default_#{prop}")) unless
          send("#{prop}") == send("default_#{prop}")
      end
      set_args_keys_default
    end

    def ==(other)
      (ospf_router == other.ospf_router) &&
        (vrf_name == other.vrf_name) && (area_id == other.area_id)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # CLI can be either of the following or none
    # area 1.1.1.1 authentication
    # area 1.1.1.1 authentication message-digest
    def authentication
      auth = config_get('ospf_area', 'authentication', @get_args)
      return default_authentication unless auth
      auth.include?('message-digest') ? 'md5' : 'clear_text'
    end

    def authentication=(val)
      state = val ? '' : 'no'
      auth = (val.to_s == 'md5') ? 'message-digest' : ''
      set_args_keys(state: state, auth: auth)
      config_set('ospf_area', 'authentication', @set_args)
    end

    def default_authentication
      config_get_default('ospf_area', 'authentication')
    end

    # CLI can be the following or none
    # area 1.1.1.1 default-cost 1000
    def default_cost
      config_get('ospf_area', 'default_cost', @get_args)
    end

    def default_cost=(val)
      state = val == default_default_cost ? 'no' : ''
      cost = val == default_default_cost ? '' : val
      set_args_keys(state: state, cost: cost)
      config_set('ospf_area', 'default_cost', @set_args)
    end

    def default_default_cost
      config_get_default('ospf_area', 'default_cost')
    end

    # CLI can be the following or none
    # area 1.1.1.1 filter-list route-map aaa in
    def filter_list_in
      config_get('ospf_area', 'filter_list_in', @get_args)
    end

    def filter_list_in=(val)
      return if filter_list_in == false && val == false
      state = val ? '' : 'no'
      rm = val ? val : filter_list_in
      set_args_keys(state: state, route_map: rm)
      config_set('ospf_area', 'filter_list_in', @set_args)
    end

    def default_filter_list_in
      config_get_default('ospf_area', 'filter_list_in')
    end

    # CLI can be the following or none
    # area 1.1.1.1 filter-list route-map bbb out
    def filter_list_out
      config_get('ospf_area', 'filter_list_out', @get_args)
    end

    def filter_list_out=(val)
      return if filter_list_out == false && val == false
      state = val ? '' : 'no'
      rm = val ? val : filter_list_out
      set_args_keys(state: state, route_map: rm)
      config_set('ospf_area', 'filter_list_out', @set_args)
    end

    def default_filter_list_out
      config_get_default('ospf_area', 'filter_list_out')
    end

    # range can take multiple values for the same vrf
    # area 1.1.1.1 range 10.3.0.0/32
    # area 1.1.1.1 range 10.3.0.1/32
    # area 1.1.1.1 range 10.3.3.0/24
    # area 1.1.1.1 range 10.3.0.0/16 not-advertise cost 23
    # sometimes the not-advertise and cost are reversed in the
    # show command for reasons unknown!
    # area 1.1.1.1 range 10.3.0.0/16 cost 23 not-advertise
    # use positional way of getting the values as it is
    # simple and there are only two properties which are
    # optional. ip is mandatory
    # the return list is of the form [ip, not-advertise, cost]
    # ex: [['10.3.0.0/16', 'not-advertise', '23'],
    #      ['10.3.0.0/32', 'not-advertise'],
    #      ['10.3.0.1/32'],
    #      ['10.3.3.0/24', '450']]
    def range
      list = []
      ranges = config_get('ospf_area', 'range', @get_args)
      ranges.each do |line|
        llist = []
        params = line.split
        llist[0] = params[0]
        llist[1] = 'not_advertise' if line.include?('not-advertise')
        if line.include?('cost')
          arr_index = llist[1].nil? ? 1 : 2
          llist[arr_index] = params[params.index('cost') + 1]
        end
        list << llist
      end
      list
    end

    def range=(set_list)
      # fail if set_list contains duplicate ip values
      ip_list = []
      set_list.each do |ip, _not_advertise, _cval|
        ip_list << ip
      end
      fail ArgumentError, 'Duplicate ip values for range' unless
        ip_list.size == ip_list.uniq.size
      # reset the current ranges first due to bug CSCuz98937
      cur_list = range
      cur_list.each do |ip, _not_advertise, _cval|
        set_args_keys(state: 'no', ip: ip, not_advertise: '',
                      cost: '', value: '')
        config_set('ospf_area', 'range', @set_args)
      end
      # now set the range from the set_list
      set_list.each do |ip, noadv, cval|
        na = noadv == 'not_advertise' ? 'not-advertise' : ''
        cost = cval ? 'cost' : ''
        value = cval ? cval : ''
        # in case of 2 variables, ip and cost
        if noadv && noadv != 'not_advertise'
          cost = 'cost'
          value = noadv
        end
        set_args_keys(state: '', ip: ip, not_advertise: na,
                      cost: cost, value: value)
        config_set('ospf_area', 'range', @set_args)
      end
    end

    def default_range
      config_get_default('ospf_area', 'range')
    end

    def stub
      config_get('ospf_area', 'stub', @get_args)
    end

    def stub=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('ospf_area', 'stub', @set_args)
    end

    def default_stub
      config_get_default('ospf_area', 'stub')
    end

    def stub_no_summary
      config_get('ospf_area', 'stub_no_summary', @get_args)
    end

    def stub_no_summary=(val)
      if val
        state = ''
        set_args_keys(state: state)
        config_set('ospf_area', 'stub_no_summary', @set_args)
      else
        if stub
          # reset and set stub
          set_args_keys(state: 'no')
          config_set('ospf_area', 'stub', @set_args)
          set_args_keys(state: '')
          config_set('ospf_area', 'stub', @set_args)
        end
      end
    end

    def default_stub_no_summary
      config_get_default('ospf_area', 'stub_no_summary')
    end
  end # class
end # module
