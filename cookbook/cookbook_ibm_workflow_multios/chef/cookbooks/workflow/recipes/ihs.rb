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
# Recipe::ihs
#
# <> Configure the IHS instance
#

# decrypt the encrypted data, all kinds of password are encrypted.
chef_vault = node['workflow']['vault']['name']

keystore_password = node['ihs']['keystore_password']
unless chef_vault.empty?
  encrypted_id = node['workflow']['vault']['encrypted_id']
  require 'chef-vault'
  keystore_password = chef_vault_item(chef_vault, encrypted_id)['ihs']['keystore_password']
end

workflow_ihs 'ibm_workflow_ihs' do
  runas_user node['ihs']['runas_user']
  runas_group node['ihs']['runas_group']
  ihs_install_root node['ihs']['install_root']
  ihs_keystore node['ihs']['keystore']
  ihs_keystore_password keystore_password
  ihs_host_name node['ihs']['host_name']
  ihs_port node['ihs']['port']

  action [:configure, :restart]
end
