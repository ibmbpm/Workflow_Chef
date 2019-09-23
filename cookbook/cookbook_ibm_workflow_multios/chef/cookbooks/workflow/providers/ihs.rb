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
# Provider:: workflow_ihs
#

# TODO disable admin server (after propagate plugin)

include IM::Helper
include WF::Helper
include IHS::Helper
use_inline_resources

# enable SSL using self signed certificate
action :configure do
  return if ::File.exist?("#{new_resource.ihs_install_root}/chef-state/ihs_done")

  # Manage GSKIT keystore
  execute 'create-key-db' do
    command "./gsk8capicmd_64 -keydb -create -db #{new_resource.ihs_keystore} -pw #{new_resource.ihs_keystore_password} -type cms -expire 3650 -stash"
    user new_resource.runas_user
    group new_resource.runas_group
    cwd "#{new_resource.ihs_install_root}/gsk8/bin"
    environment 'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:#{new_resource.ihs_install_root}/gsk8/lib64"
    sensitive true
    not_if {::File.exist?("#{new_resource.ihs_install_root}/chef-state/ihs-conf/create_keydb_done")}
  end

  directory "#{new_resource.ihs_install_root}/chef-state/ihs-conf" do
    recursive true
    owner new_resource.runas_user
    group new_resource.runas_group
    action :create
  end

  file "#{new_resource.ihs_install_root}/chef-state/ihs-conf/create_keydb_done" do
    owner new_resource.runas_user
    group new_resource.runas_group
    content ''
    action :create
  end

  # Create self-signed certificate
  execute 'create-self-signed-cert' do
    command "./gsk8capicmd_64 -cert -create -db #{new_resource.ihs_keystore} -pw #{new_resource.ihs_keystore_password} -size 2048 -dn \"CN=#{new_resource.ihs_host_name}\" -label \"#{new_resource.ihs_host_name} self-signed server certificate\" -expire 3650 -ca true -default_cert yes"
    cwd "#{new_resource.ihs_install_root}/gsk8/bin"
    user new_resource.runas_user
    group new_resource.runas_group
    environment 'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:#{new_resource.ihs_install_root}/gsk8/lib64"
    sensitive true
    not_if {::File.exist?("#{new_resource.ihs_install_root}/chef-state/ihs-conf/create_self_signed_cert_done")}
  end

  file "#{new_resource.ihs_install_root}/chef-state/ihs-conf/create_self_signed_cert_done" do
    owner new_resource.runas_user
    group new_resource.runas_group
    content ''
    action :create
  end

  # Create SSL vhost configuration file
  template "#{new_resource.ihs_install_root}/conf.d/ssl.conf" do
    source 'ssl.conf.erb'
    user new_resource.runas_user
    group new_resource.runas_group
    variables(
      :SSLPORT => new_resource.ihs_port,
      :KEYSTORE => new_resource.ihs_keystore
    )
  end

  # Disable default port 8080
  execute 'Disable default port 8080' do
    cwd "#{new_resource.ihs_install_root}/conf"
    command "sed -i.bak 's/^Listen 8080/#Listen 8080/' httpd.conf"
    user new_resource.runas_user
    group new_resource.runas_group
  end

  # remember for later runs
  file "#{new_resource.ihs_install_root}/chef-state/ihs_done" do
    owner new_resource.runas_user
    group new_resource.runas_group
    content ''
    action :create
  end
end

# restart IHS
action :restart do
  pid_file = pid_file(new_resource.ihs_install_root)

  execute 'Stop IHS using apachectl' do
    command "sudo ./apachectl stop" # for ports lower than 1024 we need sudo
    cwd "#{new_resource.ihs_install_root}/bin"
    environment 'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:#{new_resource.ihs_install_root}/gsk8/lib64"
  end

  # TODO: check whether the server is stopped using following ways:
  #       curl "http://127.0.0.1:#{IHSPORT}/server-status" 2>&1 | grep "IBM_HTTP_Server/#{IHSVERSION}"
  #       ps -ef | grep -v grep | awk '{ print $2 }' | grep -w $(cat #{PIDFILE})
  ruby_block "sleep: waiting for server stop" do
    block do
      i = 0
      while ::File.exist?(pid_file) do
        sleep 1
        i = i + 1
        if (i > 60)
          # warn and ignore, in case the process is killed directly or the process can't be stopped
          Chef::Log.warn "After 1 minute, IHS is still running..."
          # "kill -TERM '$(cat #{pid_file})'"
          break
        end
      end
    end
    only_if { ::File.exist?(pid_file) }
  end

  execute 'Start IHS using apachectl' do
    command "sudo ./apachectl start" # for ports lower than 1024 we need sudo
    cwd "#{new_resource.ihs_install_root}/bin"
    environment 'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:#{new_resource.ihs_install_root}/gsk8/lib64"
  end
  # TODO verify restart was successful
end
