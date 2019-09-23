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
# Provider:: workflow_post_deployment
#

include IM::Helper
include WF::Helper
use_inline_resources

# Create Action apply
#action :start_env do
  # info for current node
#  serverName = compute_server_name(new_resource.node_hostnames, node['hostname'])
#  nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])
#  dmgrHostname = get_dmgr_hostname(new_resource.node_hostnames)
#  Chef::Log.info("Information of current node - serverName:  #{serverName}, nodeIndex: #{nodeIndex}, dmgrHostname: #{dmgrHostname}")
#  user = define_user
#  group = define_group

#  ruby_block "start: start environment" do
#    block do
#      start_env(user, nodeIndex, serverName, group, new_resource.install_dir, dmgrHostname, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password)
#    end
#  end
#end

action :start_dmgr_pa do
    user = define_user
    group = define_group
    start_dmgr(user, group, new_resource.install_dir)
end
action :start_nodeagent_pa do
  workflow_user = define_user
  workflow_group = define_group
  dmgr_hostname = get_dmgr_hostname(new_resource.node_hostnames)
  nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])
  sync_node(workflow_user, nodeIndex, workflow_group, new_resource.install_dir, dmgr_hostname, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password)
  start_nodeagent(workflow_user, nodeIndex, workflow_group, new_resource.install_dir)
end

action :start_server_pa do
  workflow_user = define_user
  workflow_group = define_group

  serverName = compute_server_name(new_resource.node_hostnames, node['hostname'])
  nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])

  start_server(workflow_user, nodeIndex, serverName, workflow_group, new_resource.install_dir)
end

# define workflow user
# if not specified, return default value based on im_install_mode
# validate if specified user exists, meanwhile
def define_user
  case new_resource.im_install_mode
  when 'admin'
    user = if new_resource.user.nil?
             'root'
           else
             unless im_user_exists_unix?(new_resource.user)
               Chef::Log.fatal "User Name provided #{new_resource.user}, does not exist"
               raise "User Verification 1: User Name provided #{new_resource.user}, does not exist"
             end
             new_resource.user
           end
    user
  when 'nonAdmin', 'group'
    user = if new_resource.user.nil?
             Chef::Log.fatal "User Name not provided! Please provide the user that should be used to install your product"
             raise "User Name not provided! Please provide the user that should be used to install your product"
           else
             unless im_user_exists_unix?(new_resource.user)
               Chef::Log.fatal "User Name provided #{new_resource.user}, does not exist"
               raise "User Verification 1: User Name provided #{new_resource.user}, does not exist"
             end
             new_resource.user
           end
    user
  end
end

# define workflow group
# if not specified, return default value based on im_install_mode
def define_group
  case new_resource.im_install_mode
  when 'admin'
    group = if new_resource.group.nil?
              'root'
            else
              new_resource.group
            end
    group
  when 'nonAdmin', 'group'
    group = if new_resource.group.nil?
              Chef::Log.fatal "Group not provided! Please provide the group that should be used to install your product"
              raise "Group not provided! Please provide the group that should be used to install your product"
            else
              new_resource.group
            end
    group
  end
end
