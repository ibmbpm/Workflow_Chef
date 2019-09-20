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
# Recipe::post_deployment
#
# <> Post-deployment for IBM Business Automation Workflow
#
chef_vault = node['workflow']['vault']['name']

celladmin_alias_password = node['workflow']['config']['celladmin_alias_password']
unless chef_vault.empty?
  encrypted_id = node['workflow']['vault']['encrypted_id']
  require 'chef-vault'
  celladmin_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['celladmin_alias_password']
end


workflow_upgrade 'cleanup_installed_fixpacks' do
  install_dir  node['workflow']['install_dir']
  user  node['workflow']['runas_user']
  group  node['workflow']['runas_group']
  action [:cleanup]
end

# start environment for upgrade existing instance case
workflow_post_deployment 'start_environment' do
  node_hostnames  node['workflow']['config']['node_hostnames']
  im_install_mode  node['workflow']['install_mode']
  install_dir  node['workflow']['install_dir']
  user  node['workflow']['runas_user']
  group  node['workflow']['runas_group']
  celladmin_alias_user  node['workflow']['config']['celladmin_alias_user']
  celladmin_alias_password  celladmin_alias_password
  action [:start_dmgr_pa, :start_nodeagent_pa, :start_server_pa]
end
