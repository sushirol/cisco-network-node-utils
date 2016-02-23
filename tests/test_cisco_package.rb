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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/cisco_package'

class TestCiscoPackage < CiscoTestCase
  # rubocop:disable Style/ClassVars
  @@skip = false
  @@run_setup = true
  @@src = '/disk0:'
  @@pkg = 'xrv9k-m2m-2.0.0.0-r61102I.x86_64'
  @@pkg_filename = 'xrv9k-m2m-2.0.0.0-r61102I.x86_64.rpm-XR-DEV-16.02.14C'
  #@@pkg = 'xrv9k-xr-6.0.0.21I'
  #@@pkg_filename = 'xrv9k-xr-6.0.0.21I.rpm'
  #@@pkg_filename = 'xrv9k-m2m-2.0.0.0-r61102I.x86_64.rpm-XR-DEV-16.02.1'

  def setup
    super
    # only run check once (can't use initialize because @device isn't ready)
    return unless @@run_setup

    s = @device.cmd("run file #{@@pkg_filename}")
    if /RPM v3.0 bin/.match(s)
      puts "RPM exists"
      # add pkg to the repo
      # normally this could be accomplished by first installing via full path
      # but that would make these tests order dependent
      unless @device.cmd("show install package #{@@pkg}")[/Version/]
        puts "RPM is not installed. Add source. This may take few minutes."
        #@device.cmd("install add source #{@@src} #{@@pkg_filename}")
        # Wait for install to complete
        #sleep 30
      else
      end
    else
      puts "RPM is not present. Skip test."
      @@skip = true
    end
    @@run_setup = false # rubocop:disable Style/ClassVars
  end

  def skip?
    skip "file #{@@src} #{@@pkg_filename} is required. " \
      'this file can be found in the cisco_node_utils/tests directory' if @@skip
  end

  def test_activate
    skip?
    if @device.cmd("show install package #{@@pkg}")[/Version/]
      puts "Package is already installed. Deactivate package. This may take few minutes."
      #@device.cmd("install deactivate #{@@pkg}")
      #@device.cmd("install commit")
#      node.cache_flush
      sleep 20
    end

    puts "Activating new package. This may take few minutes."
    CiscoPackage.install(@@src, @@pkg_filename, @@pkg, 'activate')
    sleep 20

    s = @device.cmd("show install package #{@@pkg}")[/Version/]
    assert(s, "failed to find installed package #{@@pkg}")
  rescue RuntimeError => e
    assert(false, e.message + @@incompatible_rpm_msg)
  end
  
=begin
  def test_remove
    skip?
    unless @device.cmd("show install package | include #{@@pkg}")[/@patching/]
      @device.cmd("install add #{@@pkg} activate")
      node.cache_flush
      sleep 20
    end
    Yum.remove(@@pkg)
    sleep 20
    refute_show_match(command: "show install package | include #{@@pkg}",
                      pattern: /@patching/)
  end

  def test_ambiguous_package_error
    skip?
    assert_raises(RuntimeError) { Yum.query('busybox') }
  end

  def test_package_does_not_exist_error
    assert_raises(Cisco::CliError) do
      Yum.install('bootflash:this_is_not_real.rpm', 'management')
    end
    assert_raises(RuntimeError) do
      Yum.install('also_not_real', 'management')
    end
  end

  def test_query
    skip?
    unless @device.cmd("show install package | include #{@@pkg}")[/@patching/]
      @device.cmd("install activate #{@@pkg}")
      node.cache_flush
      sleep 20
    end
    ver = Yum.query(@@pkg)
    print "pkg version is #{ver}\n"
    assert_equal(ver, @@pkg_ver, @@incompatible_rpm_msg)
    @device.cmd("install deactivate #{@@pkg}")
    node.cache_flush
    sleep 20
    ver = Yum.query(@@pkg)
    assert_nil(ver)
  end
=end
end
