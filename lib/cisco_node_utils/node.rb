# Cisco node helper class. Abstracts away the details of the underlying
# transport (whether NXAPI or some other future transport) and provides
# various convenient helper methods.
#
# December 2014, Glenn F. Matthews
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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

require_relative 'client'
require_relative 'exceptions'
require_relative 'logger'

module Cisco
  class Node
    @instance = nil

    attr_reader :client

    def self.instance(*args)
      if @instance && !args.empty? && args != @args
        fail "Can't change existing instance (#{@args} -> #{args})"
      end
      @args ||= args
      @instance ||= new(*args)
    end

    def initialize(*args)
      @client = Cisco::Client.create(*args)
    end

    def to_s
      client.to_s
    end

    def setyang(**kwargs)
      @client.setyang(**kwargs)
    end

    def rmyang(**kwargs)
      @client.rmyang(**kwargs)
    end

    def replaceyang(**kwargs)
      @client.replaceyang(**kwargs)
    end

    def getyang(**kwargs)
      @client.getyang(**kwargs)
    end
  end
end
