# June 2016, Chris Frisz
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

require_relative 'yang'

require "rexml/document"

module Cisco

  class Netconf

    def self.empty?(nc)
      return !nc || nc.empty?
    end

    def self.convert_xml(xml)
      raise "unexpected #{xml} is not an XML document" unless xml.is_a?(REXML::Document)
      return convert_xml_node(xml.root)
    end

    def self.convert_xml_node(node)
      raise "unexpected #{node} is not an XML node" unless node.is_a?(REXML::Element)
      out_hash = {}
      children = node.to_a
      child_names = children.map { |child| child.name }
      if !node.has_elements?
        out_hash[node.name] = [nil]
      elsif child_names.all? { |name| name + 's' == node.name }
        name = child_names[0]
        out_array = children.map { |child| convert_xml_node(child)[name] }
        out_hash[node.name] = {name => out_array}
      else
        node_hash = {}
        children.each do |child|
          grandchildren = child.to_a
          if grandchildren.length == 1 && child.has_text?
            text = grandchildren[0].value.strip
            # convert to a number if that's what the text seems to represent
            node_hash[child.name] = /\A[-+]?\d+\z/.match(text) ? text.to_i : text
          else
            node_hash = convert_xml_node(child).merge(node_hash)
          end
        end
        out_hash[node.name] = node_hash
      end
      if node.attributes['operation'] == 'delete'
        if out_hash[node.name].is_a? Hash
          out_hash[node.name][:operation] = :delete
        elsif out_hash[node.name].is_a? Array
          out_hash[node.name] << { :operation => :delete }
        else
          raise 'expected Hash or Array, but got #{out_hash[node.name].class}'
        end
      end
      if !node.namespaces.empty?
        if out_hash[node.name].is_a? Hash
          out_hash[node.name][:namespaces] = node.namespaces
        elsif out_hash[node.name].is_a? Array
          out_hash[node.name] << { :namespaces => node.namespaces }
        else
          raise 'expected Hash or Array, but got #{out_hash[node.name].class}'
        end
      end
      return out_hash
    end

    def self.insync_for_merge(target, current)
      target_doc = self.empty?(target) ? {} : convert_xml(REXML::Document.new(target, { :ignore_whitespace_nodes => :all }))
      current_doc = self.empty?(current) ? {} : convert_xml(REXML::Document.new(current, { :ignore_whitespace_nodes => :all }))

      !needs_something?(:merge, target_doc, current_doc)
    end

    def self.insync_for_replace(target, current)
      target_doc = self.empty?(target) ? {} : convert_xml(REXML::Document.new(target, { :ignore_whitespace_nodes => :all }))
      current_doc = self.empty?(current) ? {} : convert_xml(REXML::Document.new(current, { :ignore_whitespace_nodes => :all }))

      !Yang::needs_something?(:replace, target_doc, current_doc)
    end

  end # Netconf
end # Cisco
