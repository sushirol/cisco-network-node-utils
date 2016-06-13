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
#      child_names = children.map { |child| child.name }
      if children.length == 1 && node.has_text?
        out_hash[node.name] = [children[0].value.strip]
      elsif !node.has_elements?
        out_hash[node.name] = [nil]
      else
        out_hash[node.name] = children.map { |child| convert_xml_node(child) }
      end
      if node.attributes['operation'] == 'delete'
        if out_hash[node.name].is_a? Hash
          out_hash[node.name][:operation] = :delete
        elsif out_hash[node.name].is_a? Array
          out_hash[node.name] << :delete
        else
          raise "expected Hash or Array, but got #{out_hash[node.name].class}"
        end
      end
      if !node.namespaces.empty?
        if out_hash[node.name].is_a? Hash
          out_hash[node.name][:namespaces] = node.namespaces
        elsif out_hash[node.name].is_a? Array
          out_hash[node.name] << { :namespaces => node.namespaces }
        else
          raise "expected Hash or Array, but got #{out_hash[node.name].class}"
        end
      end
      return out_hash
    end

    def self.insync_for_merge(target, current)
      target_doc = self.empty?(target) ? {} : convert_xml(REXML::Document.new(target, { :ignore_whitespace_nodes => :all }))
      current_doc = self.empty?(current) ? {} : convert_xml(REXML::Document.new(current, { :ignore_whitespace_nodes => :all }))

      !Yang::needs_something?(:merge, target_doc, current_doc)
    end

    def self.insync_for_replace(target, current)
      target_doc = self.empty?(target) ? {} : convert_xml(REXML::Document.new(target, { :ignore_whitespace_nodes => :all }))
      current_doc = self.empty?(current) ? {} : convert_xml(REXML::Document.new(current, { :ignore_whitespace_nodes => :all }))

      !Yang::needs_something?(:replace, target_doc, current_doc)
    end

  end # Netconf
end # Cisco
