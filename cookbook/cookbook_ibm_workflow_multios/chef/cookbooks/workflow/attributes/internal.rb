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
# <> The attribues defined in this file, will be used internally
#

#
# <> Attributes defined for Business Automation Workflow installation
#

# temp folder, which used to store some tmp files
default['ibm']['temp_dir'] = '/tmp/ibm_cloud'

# if archives are secured, need provide, hide them by now
# TODO: keep them internally, expose them out later if needed.
default['ibm']['sw_repo_user'] = 'repouser'
default['ibm']['sw_repo_password'] = ''


# The prerequistes packages, which need be installed ahead of time
force_default['workflow']['prereq_packages'] = []
force_default['db2']['os_libraries'] = []
case node['platform_family']
  when 'rhel'
    case node['kernel']['machine']
    when 'x86_64'
      force_default['db2']['os_libraries'] = %w(cpp compat-libstdc++-33 compat-libstdc++-33.i686 pam pam.i686 gcc gcc-c++ libaio libstdc++.i686 libstdc++ kernel-devel ksh nfs-utils openssh openssh-server redhat-lsb sg3_utils)
      force_default['workflow']['prereq_packages'] = if node['platform_version'].to_i >= 7
    #Removing compat-libstdc++-296 and gtk2-engines paxkages for RHEL7 as its not supported. gtk2-engines is required only for the Installation manager GUI which will not be supported on RHEL7
                                                 %w(compat-libstdc++-33 compat-db ksh gtk2 psmisc pam rpm-build elfutils elfutils-libs libXft glibc libgcc nss-softokn-freebl nss-softokn-freebl libXp libXmu libXtst openssl libXp libXmu libXtst pam gtk2)
                                               else
                                                 %w(compat-libstdc++-33 compat-db ksh gtk2 gtk2-engines pam rpm-build elfutils elfutils-libs libXft glibc libgcc nss-softokn-freebl nss-softokn-freebl libXp libXmu libXtst openssl libXp libXmu libXtst pam compat-libstdc++-296 gtk2 gtk2-engines)
                                               end
    end
  when 'debian'
    case node['kernel']['machine']
    when 'x86_64'
      force_default['db2']['os_libraries'] = %w(cpp gcc ksh openssh-server rpm unzip binutils libaio1 libnuma1 libpam0g:i386 libx32stdc++6)
      force_default['workflow']['prereq_packages'] = %w(libxtst6 libgtk2.0-bin libxft2 cpp gcc ksh openssh-server rpm unzip binutils libaio1 libnuma1 libpam0g:i386 libx32stdc++6 nfs-common)
    end
end

# Expand directory, unzip the archive files here
force_default['ibm']['expand_area'] = node['ibm']['temp_dir'] + '/expand_area'

# Workflow Edition
force_default['workflow']['edition'] = ''
case node['workflow']['features']
  when 'WorkflowEnterprise.Production', 'WorkflowEnterprise.NonProduction'
    force_default['workflow']['edition'] = 'Enterprise'
  when 'EnterpriseServiceBus.Production', 'EnterpriseServiceBus.NonProduction'
    force_default['workflow']['edition'] = 'ESB'
  when 'WorkflowExpress.Production', 'WorkflowExpress.NonProduction'
    force_default['workflow']['edition'] = 'Exp'
end

# Constants, used to download & extract installation images, archives list, base on os, workflow version
# 
# 1. BAW_18_0_0_1_Linux_x86_1_of_3.tar.gz
# 2. BAW_18_0_0_1_Linux_x86_2_of_3.tar.gz
# 3. BAW_18_0_0_1_Linux_x86_3_of_3.tar.gz
#
force_override['workflow']['version'] = node['workflow']['version'].gsub('.', '_')
force_override['workflow']['archive_names'] = {
  'was' => {
    'filename' => "BAW_#{node['workflow']['version']}_Linux_x86_1_of_3.tar.gz" },
  'workflow' => {
    'filename' => "BAW_#{node['workflow']['version']}_Linux_x86_2_of_3.tar.gz" },
  'db2' => {
    'filename' => "BAW_#{node['workflow']['version']}_Linux_x86_3_of_3.tar.gz" }
}

# The runas user/group while doing 'execute'
# For admin mode, will use root/root as user and group name, same rule as was
case node['workflow']['install_mode']
  when 'admin'
    force_default['workflow']['runas_user'] = 'root'
    force_default['workflow']['runas_group'] = 'root'
  else
    force_default['workflow']['runas_user'] = node['workflow']['os_users']['workflow']['name']
    force_default['workflow']['runas_group'] = node['workflow']['os_users']['workflow']['gid']
end

# IM installation directory
force_default['workflow']['im_install_dir'] = ''
case node['workflow']['install_mode']
when 'admin'
  force_default['workflow']['im_install_dir'] = '/opt/IBM/InstallationManager'
when 'nonAdmin'
  force_default['workflow']['im_install_dir'] = '/home/' + node['workflow']['os_users']['workflow']['name'] + '/IBM/InstallationManager'
when 'group'
  force_default['workflow']['im_install_dir'] = '/home/' + node['workflow']['os_users']['workflow']['name'] + '/IBM/InstallationManager_Group'
end

#
# <> Attributes defined for Business Automation Workflow configuration
#

# The name of the SharedDb database.
force_default['workflow']['config']['db2_shareddb_name'] = node['workflow']['config']['db2_cmndb_name']
# The name of the CellOnlyDb database.
force_default['workflow']['config']['db2_cellonlydb_name'] = node['workflow']['config']['db2_cmndb_name']

# For information about the restrictions that pertain to IBM Business Automation Workflow database schema names, 
# see the IBM Business Automation Workflow topic "Configuration properties for the BPMConfig command" 
# in the IBM Knowledge Center: http://www-01.ibm.com/support/knowledgecenter/SSFPJS/welcome
force_default['workflow']['config']['db2_schema'] = node['workflow']['config']['db_alias_user']

# The database data directory path.
force_default['workflow']['config']['db2_data_dir'] = '/home/' + node['workflow']['config']['db_alias_user'] + '/' + node['workflow']['config']['db_alias_user'] + '/NODE0000'

# The unified local case network shared directory, the attribute is defined for the limitation that same directory should be used among multiple nodes
default['workflow']['config']['local_case_network_shared_dir'] = '/opt/IBM/Workflow/CaseManagement/properties'

# The local oracle driver directory, used to put oracle jdbc driver
default['workflow']['config']['oracle']['jdbc_driver_path'] = node['workflow']['install_dir'] + '/jdbcdrivers/Oracle'

# The database_type attribute
force_override['workflow']['config']['database_type'] = node['workflow']['config']['database_type'].strip.upcase if !node['workflow']['config']['database_type'].nil?
force_override['workflow']['config']['database_type'] = 'Oracle' if !node['workflow']['config']['database_type'].nil? && 'ORACLE'.eql?(node['workflow']['config']['database_type'].strip.upcase)

# <> Attributes defined for chef-vault
#

# TODO: enhance later to support
default['workflow']['vault']['name'] = node['ibm_internal']['vault']['name']
default['workflow']['vault']['encrypted_id'] = node['ibm_internal']['vault']['item']
