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
# Recipe::create_singlecluster
#
# <> Configures IBM Business Automation Workflow SingleCluster topology
#

# TODO: try to meet the rule - all CHEF Cookbook's and Recipe's must be inherently idempotent.

# decrypt the encrypted data, all kinds of password are encrypted.
# TODO: consider moving this to internal attribute later
chef_vault = node['workflow']['vault']['name']

celladmin_alias_password = node['workflow']['config']['celladmin_alias_password']
deadmin_alias_password = node['workflow']['config']['deadmin_alias_password']
ps_pc_alias_password = node['workflow']['config']['ps_pc_alias_password']
metering_apikey = node['workflow']['config']['metering']['apikey']
unless chef_vault.empty?
  encrypted_id = node['workflow']['vault']['encrypted_id']
  require 'chef-vault'
  celladmin_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['celladmin_alias_password']
  deadmin_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['deadmin_alias_password']
  ps_pc_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['ps_pc_alias_password']
  metering_apikey = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['metering']['apikey']
end

# TODO: consider to remove following logic after changing template to use same parameter
node_hostnames = node['workflow']['config']['node_hostnames']
if node['workflow']['config']['cluster_type'] == 'SingleCluster'
  node_hostnames = node['workflow']['config']['node_hostname']
end

# TODO: use following codes to upcase the input nodes attributes.
#       code refactoring to use force_override in internal.rb, and also for other force_default attrbutes

# The name of the COMMON database.
db2_cmndb_name = node['workflow']['config']['db2_cmndb_name'].upcase if !node['workflow']['config']['db2_cmndb_name'].nil?
# The name of the ProcessServerDb database.
db2_bpmdb_name = node['workflow']['config']['db2_bpmdb_name'].upcase if !node['workflow']['config']['db2_bpmdb_name'].nil?
# The name of the PerformanceDb database.
db2_pdwdb_name = node['workflow']['config']['db2_pdwdb_name'].upcase if !node['workflow']['config']['db2_pdwdb_name'].nil?
# The name of the IcnDb/DosDb/TosDb database.
db2_cpedb_name = node['workflow']['config']['db2_cpedb_name'].upcase if !node['workflow']['config']['db2_cpedb_name'].nil?
# The name of shared db
db2_shareddb_name = node['workflow']['config']['db2_shareddb_name'].upcase if !node['workflow']['config']['db2_shareddb_name'].nil?
# The name of cellonly db
db2_cellonlydb_name = node['workflow']['config']['db2_cellonlydb_name'].upcase if !node['workflow']['config']['db2_cellonlydb_name'].nil?

# The schema name of the IcnDb database.
icndb_schema = node['workflow']['config']['cpedb']['icndb']['schema'].upcase if !node['workflow']['config']['cpedb']['icndb']['schema'].nil?
# The table space name of the IcnDb database.
icndb_tsicn = node['workflow']['config']['cpedb']['icndb']['tsicn'].upcase if !node['workflow']['config']['cpedb']['icndb']['tsicn'].nil?
# The schema name of the DosDb database.
dosdb_schema = node['workflow']['config']['cpedb']['dosdb']['schema'].upcase if !node['workflow']['config']['cpedb']['dosdb']['schema'].nil?
# The data table space name of the DosDb database.
dosdb_tsdosdata = node['workflow']['config']['cpedb']['dosdb']['tsdosdata'].upcase if !node['workflow']['config']['cpedb']['dosdb']['tsdosdata'].nil?
# The lob table space name of the DosDb database.
dosdb_tsdoslob = node['workflow']['config']['cpedb']['dosdb']['tsdoslob'].upcase if !node['workflow']['config']['cpedb']['dosdb']['tsdoslob'].nil?
# The idx table space name of the DosDb database.
dosdb_tsdosidx = node['workflow']['config']['cpedb']['dosdb']['tsdosidx'].upcase if !node['workflow']['config']['cpedb']['dosdb']['tsdosidx'].nil?
# The schema name of the TosDb database.
tosdb_schema = node['workflow']['config']['cpedb']['tosdb']['schema'].upcase if !node['workflow']['config']['cpedb']['tosdb']['schema'].nil?
# The data table space name of the DosDb database.
tosdb_tstosdata = node['workflow']['config']['cpedb']['tosdb']['tstosdata'].upcase if !node['workflow']['config']['cpedb']['tosdb']['tstosdata'].nil?
# The lob table space name of the DosDb database.
tosdb_tstoslob = node['workflow']['config']['cpedb']['tosdb']['tstoslob'].upcase if !node['workflow']['config']['cpedb']['tosdb']['tstoslob'].nil?
# The idx table space name of the DosDb database.
tosdb_tstosidx = node['workflow']['config']['cpedb']['tosdb']['tstosidx'].upcase if !node['workflow']['config']['cpedb']['tosdb']['tstosidx'].nil?

workflow_createde 'ibm_workflow_createde' do
  sw_repo  node['ibm']['sw_repo']
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
  dmgr_hostname  node['workflow']['config']['dmgr_hostname']
  node_hostnames  node_hostnames
  database_type  node['workflow']['config']['database_type']
  # db2 settings
  db2_install node['workflow']['config']['db2_install']
  db2_hostname  node['workflow']['config']['db2_hostname']
  db2_port  node['workflow']['config']['db2_port']
  db_alias_user  node['workflow']['config']['db_alias_user']
  db_alias_password  node['workflow']['config']['db_alias_password']
  db2_bpmdb_name  db2_bpmdb_name
  db2_pdwdb_name  db2_pdwdb_name
  db2_cmndb_name  db2_cmndb_name
  db2_cpedb_name  db2_cpedb_name
  cpedb_icndb_schema  icndb_schema
  cpedb_icndb_tsicn  icndb_tsicn
  cpedb_dosdb_schema  dosdb_schema
  cpedb_dosdb_tsdosdata  dosdb_tsdosdata
  cpedb_dosdb_tsdoslob  dosdb_tsdoslob
  cpedb_dosdb_tsdosidx  dosdb_tsdosidx
  cpedb_tosdb_schema  tosdb_schema
  cpedb_tosdb_tstosdata  tosdb_tstosdata
  cpedb_tosdb_tstoslob  tosdb_tstoslob
  cpedb_tosdb_tstosidx  tosdb_tstosidx
  db2_data_dir  node['workflow']['config']['db2_data_dir']
  db2_shareddb_name  db2_shareddb_name
  db2_cellonlydb_name  db2_cellonlydb_name
  db2_schema  node['workflow']['config']['db2_schema']
  # oracle settings
  oracle_jdbc_driver  node['workflow']['config']['oracle']['jdbc_driver']
  oracle_jdbc_driver_path  node['workflow']['config']['oracle']['jdbc_driver_path']
  oracle_hostname  node['workflow']['config']['oracle']['hostname']
  oracle_port  node['workflow']['config']['oracle']['port']
  oracle_database_name  node['workflow']['config']['oracle']['database_name']
  oracle_cmndb_username  node['workflow']['config']['oracle']['shareddb']['username']
  oracle_cmndb_password  node['workflow']['config']['oracle']['shareddb']['password']
  oracle_cellonlydb_username  node['workflow']['config']['oracle']['cellonlydb']['username']
  oracle_cellonlydb_password  node['workflow']['config']['oracle']['cellonlydb']['password']
  oracle_psdb_username  node['workflow']['config']['oracle']['psdb']['username']
  oracle_psdb_password  node['workflow']['config']['oracle']['psdb']['password']
  oracle_icndb_username  node['workflow']['config']['oracle']['icndb']['username']
  oracle_icndb_password  node['workflow']['config']['oracle']['icndb']['password']
  oracle_icndb_tsicn  node['workflow']['config']['oracle']['icndb']['tsicn']
  oracle_dosdb_username  node['workflow']['config']['oracle']['dosdb']['username']
  oracle_dosdb_password  node['workflow']['config']['oracle']['dosdb']['password']
  oracle_dosdb_tsdosdata  node['workflow']['config']['oracle']['dosdb']['tsdosdata']
  oracle_tosdb_username  node['workflow']['config']['oracle']['tosdb']['username']
  oracle_tosdb_password  node['workflow']['config']['oracle']['tosdb']['password']
  oracle_tosdb_tstosdata  node['workflow']['config']['oracle']['tosdb']['tstosdata']
  oracle_pdwdb_username  node['workflow']['config']['oracle']['pdwdb']['username']
  oracle_pdwdb_password  node['workflow']['config']['oracle']['pdwdb']['password']
  # ps settings
  ps_environment_purpose  node['workflow']['config']['ps_environment_purpose']
  ps_offline  node['workflow']['config']['ps_offline']
  ps_pc_transport_protocol  node['workflow']['config']['ps_pc_transport_protocol']
  ps_pc_hostname  node['workflow']['config']['ps_pc_hostname']
  ps_pc_port  node['workflow']['config']['ps_pc_port']
  ps_pc_contextroot_prefix  node['workflow']['config']['ps_pc_contextroot_prefix']
  ps_pc_alias_user  node['workflow']['config']['ps_pc_alias_user']
  ps_pc_alias_password  ps_pc_alias_password
  # metering
  metering_identifier_name  node['workflow']['config']['metering']['identifier_name']
  metering_url  node['workflow']['config']['metering']['url']
  metering_apikey metering_apikey
  action [:check_attrs, :prepare, :create, :restore_isc, :ps_online_setup, :start_dmgr, :start_nodeagent, :enable_metering, :start_server]
end
