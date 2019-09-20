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
# Recipe::attributes
#
# <> The attributes file will define all attributes that may be over-written by CHEF Attribute Precendence
#

# TODO: by now, all switch is passed in as string, change them to boolean later

#
# <> Attributes defined for Business Automation Workflow installation
#

# TODO: keep current hard-coded default value for testing need, need cleanup before releasing

# workflow archive files(images) download location
default['ibm']['sw_repo'] = ''
# workflow ifix files download location
default['ibm']['ifix_repo'] = ''
# workflow fixpack files download location
default['ibm']['fixpack_repo'] = ''

# log directory - all log files generated during installation & configuration
default['ibm']['log_dir'] = '/var/log/ibm_cloud'

# os admin user
default['os_admin']['user'] = ''

#default['workflow']['install_mode'] = 'group'
default['workflow']['install_mode'] = 'nonAdmin'

default['workflow']['os_users'] = {
  'workflow'  =>  {
    'name' =>     'wfuser',
    'gid' =>      'wfgrp',
    'comment' =>  'OS administrative user for Workflow installation',
    'home' =>     "/home/wfuser",
    'shell' =>    '/bin/bash'
  }
}

default['workflow']['im_version'] = ''

# The release and fixpack level of Business Automation Workflow to be installed. Example formats are 18001.
default['workflow']['version'] = ''

default['workflow']['features'] = 'WorkflowEnterprise.Production' # 'WorkflowEnterprise.Production', 'WorkflowEnterprise.NonProduction',
# 'EnterpriseServiceBus.Production', 'EnterpriseServiceBus.NonProduction', 'WorkflowExpress.Production' or 'WorkflowExpress.NonProduction'
# currently, use different template for different workflow edition, so, no need to make workflow feature customization

# TODO: workflow features & workflow offering_id must keep consistent, add check later
# or leverage workflow offering_id to determine workflow features
default['workflow']['offering_id'] = ''
default['workflow']['offering_version'] = ''

default['workflow']['install_dir'] = '/opt/IBM/Workflow'

# ifix list in string format. For example "ifix1.zip, ifix2.zip, ifix3.zip"
default['workflow']['ifix_names'] = ''

# fixpack list in string format. For example "cf1.tar.gz, cf2.tar.gz, cf3.tar.gz"
# Change fixpack_names to fixpack_names_list to solve one of cam limitation, duplicated fixpack download issue.
default['workflow']['fixpack_names_list'] = ''

default['was']['offering_id'] = ''
# TODO: modify the profile id to workflow, and change the profile id to a full name of workflow
# TODO: consider to remove this attribute, and use 'Business Automation Workflow' as replacement.
default['workflow']['profile_id'] = ''

default['db2']['offering_id'] = ''
default['db2']['offering_version'] = ''

default['db2']['install'] = 'true'
# To install DB2 Advanced Workgroup Server Edition, config the DB2 user name and encrypted password.
# MUST if attribute ['db2']['install'] is 'true'
default['db2']['port'] = '50000'
default['db2']['username'] = 'db2inst1'
default['db2']['password'] = ''
default['db2']['das_newuser'] = 'true'
default['db2']['fenced_newuser'] = 'true'
default['db2']['fenced_username'] = 'db2fenc1'
default['db2']['fenced_password'] = ''
default['db2']['das_username'] = 'dasusr1'
default['db2']['das_password'] = ''


#
# <> Attributes defined for Business Automation Workflow configuration
#

default['workflow']['config']['product_type'] = 'Advanced'
default['workflow']['config']['deployment_type'] = 'PC'
default['workflow']['config']['cluster_type'] = 'SingleCluster'

# Deployment environment administrator authentication alias.
default['workflow']['config']['deadmin_alias_user'] = 'deadmin'
default['workflow']['config']['deadmin_alias_password'] = ''
# Cell (WAS) administration authentication alias
default['workflow']['config']['celladmin_alias_user'] = 'admin'
default['workflow']['config']['celladmin_alias_password'] = ''
# The host name of the deployment manager. Do not use localhost for environments that span multiple hosts.
default['workflow']['config']['dmgr_hostname'] = ''
# If the host name is the same as the deployment manager, this node will be created on the same computer. Do not use localhost for environments that span multiple hosts.
default['workflow']['config']['node_hostname'] = ''

# same as default['db2']['install'] above
default['workflow']['config']['db2_install'] = 'true'
# The host name of the database. Do not use localhost for environments that span multiple hosts.
default['workflow']['config']['db2_hostname'] = ''
# The port of the DB2 database
default['workflow']['config']['db2_port'] = '50000'
# Database user authentication alias
default['workflow']['config']['db_alias_user'] = 'db2inst1'
# Database user authentication alias password
default['workflow']['config']['db_alias_password'] = ''
# The name of the COMMON database.
default['workflow']['config']['db2_cmndb_name'] = 'CMNDB'
# The name of the ProcessServerDb database.
default['workflow']['config']['db2_bpmdb_name'] = 'BPMDB'
# The name of the PerformanceDb database.
default['workflow']['config']['db2_pdwdb_name'] = 'PDWDB'
# The name of the IcnDb/DosDb/TosDb database.
default['workflow']['config']['db2_cpedb_name'] = 'CPEDB'
# The schema name of the IcnDb database.
default['workflow']['config']['cpedb']['icndb']['schema'] = 'ICNSA'
# The table space name of the IcnDb database.
default['workflow']['config']['cpedb']['icndb']['tsicn'] = 'WFICNTS'
# The schema name of the DosDb database.
default['workflow']['config']['cpedb']['dosdb']['schema'] = 'DOSSA'
# The data table space name of the DosDb database.
default['workflow']['config']['cpedb']['dosdb']['tsdosdata'] = 'DOSSA_DATA_TS'
# The lob table space name of the DosDb database.
default['workflow']['config']['cpedb']['dosdb']['tsdoslob'] = 'DOSSA_LOB_TS'
# The idx table space name of the DosDb database.
default['workflow']['config']['cpedb']['dosdb']['tsdosidx'] = 'DOSSA_IDX_TS'
# The schema name of the TosDb database.
default['workflow']['config']['cpedb']['tosdb']['schema'] = 'TOSSA'
# The data table space name of the DosDb database.
default['workflow']['config']['cpedb']['tosdb']['tstosdata'] = 'TOSSA_DATA_TS'
# The lob table space name of the DosDb database.
default['workflow']['config']['cpedb']['tosdb']['tstoslob'] = 'TOSSA_LOB_TS'
# The idx table space name of the DosDb database.
default['workflow']['config']['cpedb']['tosdb']['tstosidx'] = 'TOSSA_IDX_TS'

# (<> PS only <>) The purpose of this Process Server environment: Development, Test, Staging, or Production.
default['workflow']['config']['ps_environment_purpose'] = 'Development'
# (<> PS only <>) Options: true or false. Set to false if the Process Server is online and can be connected to the Process Center.
default['workflow']['config']['ps_offline'] = 'false'
# (<> PS only <>) Options: http or https. The transport protocol for communicating with the Process Center environment.
default['workflow']['config']['ps_pc_transport_protocol'] = 'https'
# (<> PS only <>) The host name of the Process Center environment.
default['workflow']['config']['ps_pc_hostname'] = ''
# (<> PS only <>) The port number of the Process Center environment.
default['workflow']['config']['ps_pc_port'] = '9443'
# (<> PS only <>) The context root prefix of the Process Center environment. If set, the context root prefix must start with a forward slash character (/).
default['workflow']['config']['ps_pc_contextroot_prefix'] = ''
# (<> PS only <>) Process Center authentication alias (which is used by online Process Server environments to connect to Process Center)
default['workflow']['config']['ps_pc_alias_user'] = 'admin'
default['workflow']['config']['ps_pc_alias_password'] = ''
