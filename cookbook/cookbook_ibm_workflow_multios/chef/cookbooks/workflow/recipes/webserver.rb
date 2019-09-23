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
# Recipe::webserver
#
# <> Create a unmanaged node and a webserver
#

# decrypt the encrypted data, all kinds of password are encrypted.
chef_vault = node['workflow']['vault']['name']

deadmin_alias_password = node['workflow']['config']['deadmin_alias_password']
ihs_admin_password = node['ihs']['admin_password']
unless chef_vault.empty?
  encrypted_id = node['workflow']['vault']['encrypted_id']
  require 'chef-vault'
  deadmin_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['deadmin_alias_password']
  ihs_admin_password = chef_vault_item(chef_vault, encrypted_id)['ihs']['admin_password']
end

cell_name = 'PSCell1' # fixed cell name for PS and AdvancedOnly
cell_name = 'PCCell1' if node['workflow']['config']['product_type'] != 'AdvancedOnly' && node['workflow']['config']['deployment_type'] == 'PC'

workflow_webserver 'ibm_workflow_webserver' do
  install_dir node['workflow']['install_dir']
  deadmin_alias_user node['workflow']['config']['deadmin_alias_user']
  deadmin_alias_password deadmin_alias_password
  runas_user node['workflow']['runas_user']
  runas_group node['workflow']['runas_group']
  dmgr_hostname node['workflow']['config']['dmgr_hostname']
  ihs_cell_name cell_name
  ihs_node_name node['ihs']['node_name']
  ihs_host_name node['ihs']['host_name']
  ihs_port node['ihs']['port']
  ihs_install_root node['ihs']['install_root']
  ihs_plugin_root node['ihs']['plugin_root']
  ihs_admin_port node['ihs']['admin_port']
  ihs_admin_user node['ihs']['admin_user']
  ihs_admin_password ihs_admin_password

  action [:create, :retrieve_ihs_certificate, :propagate]
end
