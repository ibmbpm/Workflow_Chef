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
# Recipe::applyifx
#
# <> Apply ifixes for IBM Business Automation Workflow
#

# Decrypt the encrypted data, all kinds of password are encrypted.
chef_vault = node['workflow']['vault']['name']

celladmin_alias_password = node['workflow']['config']['celladmin_alias_password']
unless chef_vault.empty?
  #Chef::Log.info("Before decryption: db2_password: #{db2_password}, db2_fenced_password: #{db2_fenced_password}, db2_das_password: #{db2_das_password}")
  encrypted_id = node['workflow']['vault']['encrypted_id']
  require 'chef-vault'
  celladmin_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['celladmin_alias_password']
end

# Determine if https is used
repo_nonsecureMode = 'false'
secure_repo = 'false'
if node['ibm']['ifix_repo'].match(/^https:\/\//)
  repo_nonsecureMode = 'true'
  secure_repo = 'true'
end
Chef::Log.info("repo_nonsecureMode: #{repo_nonsecureMode}")

Chef::Resource::User.send(:include, IM::Helper)

# TODO: enable secure mode for private repository and add SSL support later
workflow_applyifix 'ibm_workflow' do
  ifix_repo  node['ibm']['ifix_repo']
  ifix_names  node['workflow']['ifix_names']
  install_dir  node['workflow']['install_dir']
  im_install_mode  node['workflow']['install_mode']
  user  node['workflow']['runas_user']
  group  node['workflow']['runas_group']
  celladmin_alias_user  node['workflow']['config']['celladmin_alias_user']
  celladmin_alias_password  celladmin_alias_password
  node_hostnames  node['workflow']['config']['node_hostnames']
  repo_nonsecureMode  repo_nonsecureMode
  secure_repo  secure_repo # if it's true, need set vault info using ['workflow']['vault']
  action [:apply]
end