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
# Cookbook Name:: workflow
# Provider:: workflow_webserver
#

include IM::Helper
include WF::Helper
use_inline_resources

# Create Web Server
action :create do
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/webserver_done")
  return if ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile/config/cells/#{new_resource.ihs_cell_name}/nodes/#{new_resource.ihs_node_name}")

  webserver_jython = '/tmp/create_webserver.jy'

  template webserver_jython do
    source 'wsadmin/create_webserver.jy.erb'
    variables(
      NODE_NAME: new_resource.ihs_node_name,
      CELL_NAME: new_resource.ihs_cell_name,
      HOST_NAME: new_resource.ihs_host_name,
      WEBSERVER_PORT: new_resource.ihs_port,
      WEBSERVER_INSTALLDIR: new_resource.ihs_install_root,
      PLUGIN_INSTALLDIR: new_resource.ihs_plugin_root,
      ADMINSERVER_PORT: new_resource.ihs_admin_port,
      ADMINSERVER_USER: new_resource.ihs_admin_user,
      ADMINSERVER_PASSWORD: new_resource.ihs_admin_password,
      INSTALL_DIR: new_resource.install_dir
    )
  end

  ruby_block 'wsadmin: create web server' do
    block do
      wsadmin_out = WF::Helper.run_jython("#{new_resource.runas_user}", "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", webserver_jython)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
  end

  file webserver_jython do
    action :delete
  end

  directory "#{new_resource.install_dir}/chef-state" do
    owner new_resource.runas_user
    group new_resource.runas_group
    action :create
  end

  # remember for later runs
  file "#{new_resource.install_dir}/chef-state/webserver_done" do
    owner new_resource.runas_user
    group new_resource.runas_group
    content ''
    action :create
  end
end

# Retrieve signer certificate of IHS
action :retrieve_ihs_certificate do
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/retrieve_ihs_certificate_done")
  return if new_resource.ihs_host_name.nil? || new_resource.ihs_host_name.empty?
  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  retrieve_signer_certificate_jython = "#{new_resource.install_dir}/profiles/DmgrProfile/bin/retrieve_signer_certificate.jy"

  # generate retrieve signer certificate jython file, and keep for future potential issue investigation
  template retrieve_signer_certificate_jython do
    source 'wsadmin/retrieve_signer_certificate.jy.erb'
    variables(
      ihs_hostname: new_resource.ihs_host_name,
      ihs_https_port: new_resource.ihs_port
    )
  end

  ruby_block 'wsadmin: retrieve IHS signer certificate' do
    block do
      wsadmin_out = WF::Helper.run_jython("#{new_resource.runas_user}", "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", retrieve_signer_certificate_jython)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
  end

  directory "#{new_resource.install_dir}/chef-state" do
    owner new_resource.runas_user
    group new_resource.runas_group
    action :create
  end

  # remember for later runs
  file "#{new_resource.install_dir}/chef-state/retrieve_ihs_certificate_done" do
    owner new_resource.runas_user
    group new_resource.runas_group
    content ''
    action :create
  end
end

# Should Propagate Web Server every time, for both fresh and upgrade paths
action :propagate do
  return unless ::File.exist?("#{new_resource.install_dir}/chef-state/webserver_done")
  return unless ::File.exist?("#{new_resource.install_dir}/chef-state/retrieve_ihs_certificate_done")
  # return if ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile/config/cells/#{new_resource.ihs_cell_name}/nodes/#{new_resource.ihs_node_name}")

  propagate_webserver_jython = '/tmp/propagate_webserver.jy'

  template propagate_webserver_jython do
    source 'wsadmin/propagate_webserver.jy.erb'
    variables(
      NODE_NAME: new_resource.ihs_node_name,
      CELL_NAME: new_resource.ihs_cell_name,
      INSTALL_DIR: new_resource.install_dir
    )
  end

  ruby_block 'wsadmin: propagate web server' do
    block do
      wsadmin_out = WF::Helper.run_jython("#{new_resource.runas_user}", "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", propagate_webserver_jython)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
  end

  file propagate_webserver_jython do
    action :delete
  end

end