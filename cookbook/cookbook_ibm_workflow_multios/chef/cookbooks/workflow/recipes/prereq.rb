# =================================================================
# Copyright 2018 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =================================================================

#
# Cookbook Name::workflow
# Recipe::prereq
#
# <> This recipe will add to the environment the necessary Pre-Requisites to be added prior to Workflow Instalation, this will include
# <> Adding users, Packages, Kernel Configuration
#
# <> @author: xbyu@cn.ibm.com

# This will only work if the VM has access to rubygems.org
# Otherwise the gem should be installed during bootstrap
# TODO: enable vault later
#chef_gem 'chef-vault' do
#  action :install
#  version '2.9.0'
#  compile_time true
#end

Chef::Log.info("node['platform_family']: #{node['platform_family']}")

case node['platform_family']
when 'debian'
  # run 'apt-get update' to get lastest packages info
  execute 'Update debian/ubuntu repos' do
    command "apt-get update"
    ignore_failure true
  end

  # for db2
  execute 'enable_extra_repository' do
    command 'dpkg --add-architecture i386'
    ignore_failure true
  end

  node['db2']['os_libraries'].each do |p|
    package p do
      action :install
    end
  end
when 'rhel'
  execute 'enable_extra_repository' do
    command 'yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional'
    only_if { node['db2']['os_libraries'].include?('compat-libstdc++-33') }
    not_if 'yum list compat-libstdc++-33'
    only_if { node['platform_family'] == 'rhel' }
    only_if { node['platform_version'].split('.').first.to_i >= 7 }
    not_if { File.foreach('/sys/devices/virtual/dmi/id/bios_version').grep(/amazon$/).empty? }
  end

  Chef::Log.info("Remove pam.i686 is exists")
  execute 'remove pam.i686' do
    command 'yum erase -y pam.i686'
    only_if { node['platform_family'] == 'rhel' }
    only_if { node['platform_version'].split('.').first.to_i >= 7 }
  end
 
  node['db2']['os_libraries'].each do |p|
    package p do
      action :install
    end
  end
end

case node['platform_family']
when 'debian','rhel'

  # Install the prereq packages
  node['workflow']['prereq_packages'].each do |p|
    package p do
      action :install
      ignore_failure  true
    end
  end

  # TODO: if IM install by root in nonAdmin mode, what needed?
  #       root ulimits or the normal user's limits?
  # TODO: if IM install by non-root in nonAdmin mode, is this okay?
  template "/etc/security/limits.d/workflow-limits.conf" do
    source "workflow-limits.conf.erb"
    mode '0644'
    variables(
      :OSADMINUSER => (node['os_admin']['user']).to_s,
      :OSUSER => (node['workflow']['os_users']['workflow']['name']).to_s
    )
  end

  #create OS users and groups
  node['workflow']['os_users'].each_pair do |_k, u|
    next if u['name'].nil?
    next if u['gid'].nil?
    group u['gid'] do
      action :create
    end

    user u['name'] do
      action :create
      comment u['comment']
      home u['home']
      gid u['gid']
      shell u['shell']
      manage_home true
    end

    directory u['home'] do
      action :create
      mode '0755'
      recursive true
    end

  end
end

# create directories ahead of time
[node['ibm']['temp_dir'], node['ibm']['expand_area']].each do |dir|
    directory dir do
      recursive true
      action :create
      mode '0755'
    end
end
