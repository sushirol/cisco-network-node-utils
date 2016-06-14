# June 2016, Charles Burkett
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

require 'json'

module Cisco

  class Yang

    # Is the specified yang string empty?
    def self.empty?(yang)
      return !yang || yang.empty?
    end

    # Given a current and target YANG configuration, returns true if
    # the configurations are in-sync, relative to a "merge_config" action
    def self.insync_for_merge(target, current)
      target_hash = self.empty?(target) ? {} : JSON.parse(target)
      current_hash = self.empty?(current) ? {} : JSON.parse(current)

      !needs_something?(:merge, target_hash, current_hash)
    end

    # Given a current and target YANG configuration, returns true if
    # the configuration are in-sync, relative to a "replace_config" action
    def self.insync_for_replace(target, current)
      target_hash = self.empty?(target) ? {} : JSON.parse(target)
      current_hash = self.empty?(current) ? {} : JSON.parse(current)

      !needs_something?(:replace, target_hash, current_hash)
    end

    # usage:
    #   needs_something?(op, target, run)
    #
    #   op     - symbol - If value is not :replace, it's assumed to be :merge.
    #                     Indicates to the function whether to check for a
    #                     possible merge vs. replace
    #
    #   target - JSON   - JSON tree representing target configuration
    #
    #   run    - JSON   - JSON tree representing target configuration
    #
    #
    # Needs merge will determine if target and run differ
    # sufficiently to necessitate running the merge command.
    #
    # The logic here amounts to determining if target is a subtree
    # of run, with a tiny bit of domain trickiness surrounding
    # elements that are arrays that contain a single nil element
    # that is required for "creating" certain configuration elements.
    #
    # There are ultimately 3 different types of elements in a json
    # tree.  Hashes, Arrays, and leaves.  While hashes and array values
    # are organized with an order, the logic here ignores the order.
    # In fact, it specifically attempts to match assuming order
    # doesn't matter.  This is largely to allow users some freedom
    # in specifying the config in the manifest.  The gRPC interface
    # doesn't seem to care about order.  If that changes, then so
    # should this code.
    #
    # Arrays and Hashes are compared by iterating over every element
    # in target, and ensuring it is within run.
    #
    # Leaves are directly compared for equality, excepting the
    # condition that the target leaf is in fact an array with one
    # element that is nil.
    #
    # Needs replace will determine if target and run differ
    # sufficiently to necessitate running the replace command.
    #
    # The logic is the same as merge, except when comparing
    # hashes, if the run hash table has elements that are not
    # in target, we ultimately indicate that replace is needed
    def self.needs_something?(op, target, run)
      not hash_equiv?(op, target, run)
    end

    def self.nil_array(elt)
      elt.nil? || (elt.is_a?(Array) && elt.length == 1 && elt[0].nil?)
    end

    def self.sub_elt(op, target, run)
      if target.is_a?(Hash) && run.is_a?(Hash)
        return self.hash_equiv?(op, target, run)
      elsif target.is_a?(Array) && run.is_a?(Array)
        return self.array_equiv?(op, target, run)
      else
        return !(target != run && !self.nil_array(target))
      end
    end

    def self.array_equiv?(op, target, run)
      n = target.length
      delete = false
      loop = lambda {|i|
        if i == n
          if op == :replace
            # NB: Not sure if this is correct
            if delete
              run.length == (target.length - 1)
            else
              run.length == target.length
            end
          else
            # NB: Will need to insert logic around delete here
            true
          end
        else
          target_elt = target[i]
          # Detect and note if our target has a delete tag.  Run shall never have a
          # delete tag (it comes from the host)
          if :delete == target_elt
            delete = true
            loop.call(i + 1)
          else
            run_elt = run.find { |run_elt|
              self.sub_elt(op, target_elt, run_elt)
            }
            
            if run_elt.nil? && !nil_array(target_elt)
              # Add additional delete logic here
              target_elt.nil?
            else
              loop.call(i + 1)
            end
          end
        end
      }
      loop.call(0)
    end

    def self.hash_equiv?(op, target, run)
      keys = target.keys
      n = keys.length
      loop = lambda {|i|
        if i == n
          if op == :replace
            run.keys.length == target.keys.length
          else
            true
          end
        else
          k = keys[i]
          run_v = run[k]
          target_v = target[k]
          if run_v.nil? && !self.nil_array(target_v)
            false
          else
            self.sub_elt(op, target_v, run_v) && loop.call(i + 1)
          end
        end
      }
      loop.call(0)
    end

  end # Yang
end # Cisco
