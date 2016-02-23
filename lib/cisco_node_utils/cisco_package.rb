#
# implementation of CiscoPackage class
#
# April 2015, Alex Hunsberger
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

require_relative 'node_util'

module Cisco
  # This CiscoPackage class provides cisco package management functions through nxapi.
  class CiscoPackage < NodeUtil
    attr_reader :src, :pkg_filename, :pkg

    def self.install(src, pkg_filename, pkg, action)
      @src = src
      @pkg_filename = pkg_filename
      @pkg = pkg
      @set_args = { src: @src, pkg_filename: @pkg_filename, pkg: @pkg }
      case 
      when 'add' == action
        puts 'add'
#              config_set('cisco_package', 'install_add', pkg)
      when 'activate' == action
        config_set('cisco_package', 'install_activate', @set_args)
        puts 'Package activated'
      else
        puts "improper action."
      end
    end

    # returns version of package, or false if package doesn't exist
=begin
    def self.query(pkg)
      fail TypeError unless pkg.is_a? String
      fail ArgumentError if pkg.empty?
      b = config_get('cisco_package', 'query', pkg)
      fail "Multiple matching packages found for #{pkg}" if b && b.size > 1
      b.nil? ? nil : b.first
    end

    def self.remove(pkg)
      config_set('cisco_package', 'remove', pkg)
    end
=end
  end
end
