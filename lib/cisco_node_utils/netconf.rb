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

require 'libxml'

module Cisco include LibXML

  class Netconf

    def self.empty?(nc)
      return !nc || nc.empty?
    end

    def self.convert_xml(xml)
      raise "unexpected #{xml} is not an XML document" unless xml.is_a?(LibXML::XML::Document)
      return convert_xml_node(xml.root)
    end

    def self.convert_xml_node(node)
      raise "unexpected #{node} is not an XML node" unless node.is_a?(LibXML::XML::Node)
      out_hash = {}
      children = node.children.select { |child| !child.empty? }
      child_names = children.map { |child| child.name }
      if node.empty? || children.length == 0
        out_hash[node.name] = [nil]
      elsif child_names.all? { |name| name + 's' == node.name }
        name = child_names[0]
        out_array = children.map { |child| convert_xml_node(child)[name] }
        out_hash[node.name] = {name => out_array}
      else
        node_hash = {}
        children.each do |child|
          grandchildren = child.children.select { |gc| !gc.empty? }
          if grandchildren.length == 1 && grandchildren.first.text?
            text = grandchildren.first.content.strip
            # convert to a number if that's what the text seems to represent
            node_hash[child.name] = /\A[-+]?\d+\z/.match(text) ? text.to_i : text
          else
            node_hash = convert_xml_node(child).merge(node_hash)
          end
        end
        out_hash[node.name] = node_hash
      end
      return out_hash
    end

    def self.insync_for_merge(target, current)
      target_doc = self.empty?(target) ? {} : convert_xml(LibXML::XML::Document.string(target))
      current_doc = self.empty?(current) ? {} : convert_xml(LibXML::XML::Document.string(current))

      !needs_something?(:merge, target_doc, current_doc)
    end

    def self.insync_for_replace(target, current)
      target_doc = self.empty?(target) ? {} : convert_xml(LibXML::XML::Document.string(target))
      current_doc = self.empty?(current) ? {} : convert_xml(LibXML::XML::Document.string(current))

      !Yang::needs_something?(:replace, target_doc, current_doc)
    end

  end # Netconf
end # Cisco
