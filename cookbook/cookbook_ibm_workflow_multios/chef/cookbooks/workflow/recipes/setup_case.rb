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
# Recipe::setup_case
#
# <> Setup case for IBM Business Automation Workflow SingleCluster topology
#

# Make case work for SingleClusters topology in the way temporarily
# TODO: refactoring later, the case need be run after that the whole ND is setup

# decrypt the encrypted data, all kinds of password are encrypted.
chef_vault = node['workflow']['vault']['name']

celladmin_alias_password = node['workflow']['config']['celladmin_alias_password']
deadmin_alias_password = node['workflow']['config']['deadmin_alias_password']
unless chef_vault.empty?
  #Chef::Log.info("Before decryption: celladmin_alias_password: #{celladmin_alias_password}, deadmin_alias_password: #{deadmin_alias_password}, db_alias_password: #{db_alias_password}, ps_pc_alias_password: #{ps_pc_alias_password}")
  encrypted_id = node['workflow']['vault']['encrypted_id']
  require 'chef-vault'
  celladmin_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['celladmin_alias_password']
  deadmin_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['deadmin_alias_password']
end

# TODO: consider to remove following logic after changing template to use same parameter
node_hostnames = node['workflow']['config']['node_hostnames']
if node['workflow']['config']['cluster_type'] == 'SingleCluster'
  node_hostnames = node['workflow']['config']['node_hostname']
end

# TODO: some paramters are not needed by setup_case, need do code refactoring
workflow_createde 'ibm_workflow_createde' do
  install_dir  node['workflow']['install_dir']
  product_type  node['workflow']['config']['product_type']
  deployment_type  node['workflow']['config']['deployment_type']
  cluster_type  node['workflow']['config']['cluster_type']
  workflow_runas_user  node['workflow']['runas_user']
  workflow_runas_group  node['workflow']['runas_group']
  deadmin_alias_user  node['workflow']['config']['deadmin_alias_user']
  deadmin_alias_password  deadmin_alias_password
  celladmin_alias_user  node['workflow']['config']['celladmin_alias_user']
  celladmin_alias_password  celladmin_alias_password
  ihs_hostname  node['workflow']['config']['ihs_hostname']
  ihs_https_port  node['workflow']['config']['ihs_https_port']
  dmgr_hostname  node['workflow']['config']['dmgr_hostname']
  node_hostnames  node_hostnames
  action [:setup_case]
end
