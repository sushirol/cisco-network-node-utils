# June 2015, Michael G Wiebe
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

#require_relative 'node_util'
#require_relative 'feature'
#require_relative 'logger'

module Cisco
  class Yang

    def self.empty?(yang)
      return !yang || yang.empty?
    end

    # Given a current and target YANG configuration, returns true if
    # the configuration are in-sync, relative to a "merge_config" action
    def self.insync_for_merge(current, target)

        current_hash = self.empty?(current) ? {} : JSON.parse(current)
        target_hash = self.empty?(target) ? {} :
          JSON.parse(target.gsub(/\,\s*\"create\"\s*:\s*null/, ''))

        current_hash == target_hash
    end

    # Given a current and target YANG configuration, returns true if
    # the configuration are in-sync, relative to a "replace_config" action
    def self.insync_for_replace(current, target)
      return self.insync_for_merge(current, target)
    end

  end # Yang
end # Cisco
