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
# Recipe::install
#
# <> Installs IBM Business Automation Workflow
#

# decrypt the encrypted data, all kinds of password are encrypted.
chef_vault = node['workflow']['vault']['name']

db2_password = node['db2']['password']
db2_fenced_password = node['db2']['fenced_password']
db2_das_password = node['db2']['das_password']
celladmin_alias_password = node['workflow']['config']['celladmin_alias_password']

unless chef_vault.empty?
  #Chef::Log.info("Before decryption: db2_password: #{db2_password}, db2_fenced_password: #{db2_fenced_password}, db2_das_password: #{db2_das_password}")
  encrypted_id = node['workflow']['vault']['encrypted_id']
  require 'chef-vault'
  db2_password = chef_vault_item(chef_vault, encrypted_id)['db2']['password']
  db2_fenced_password = chef_vault_item(chef_vault, encrypted_id)['db2']['fenced_password']
  db2_das_password = chef_vault_item(chef_vault, encrypted_id)['db2']['das_password']
  celladmin_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['celladmin_alias_password']
end

# TODO: try to meet the rule - all CHEF Cookbook's and Recipe's must be inherently idempotent.

# check install_mode
user = node['workflow']['runas_user']
im_install_dir = node['workflow']['im_install_dir']

case node['workflow']['install_mode']
when 'admin'
  if user != 'root'
    Chef::Log.fatal "Admin Verification 1: Installation Manager Admin role must be executed as root"
    raise "Admin Verification 1: Installation Manager Admin role must be executed as root"
  end
when 'nonAdmin'
  if user == 'root'
    Chef::Log.fatal "Non-Admin Verification 1: Installation Manager Non-Admin role must NOT be executed as root"
    raise "Non-Admin Verification 1: Installation Manager Non-Admin role must NOT be executed as root"
  end
  unless im_install_dir.include? "/home/#{user}"
    Chef::Log.fatal "Non-Admin Verification 2: Installation Manager Non-Admin role must installed under the /home directory"
    raise "Non-Admin Verification 2: Installation Manager Non-Admin role must installed under the /home directory"
  end
when 'group'
  if user == 'root'
    Chef::Log.fatal "Group Verification 1: Installation Manager Group role must NOT be executed as root"
    raise "Group Verification 1: Installation Manager Group role must NOT be executed as root"
  end
  unless im_install_dir.include? "/home/#{user}"
    Chef::Log.fatal "Group Verification 2: Installation Manager Group role must installed under the /home directory"
    raise "Group Verification 2: Installation Manager Group role must installed under the /home directory"
  end
else
  Chef::Log.fatal "Install Mode Verification 1: Installation Manager role must be admin / nonAdmin or group"
  raise "Install Mode Verification 1: Installation Manager role must be admin / nonAdmin or group"
end


# check db2 settings

# install db2 with was/workflow in one group in admin mode, or install db2 separately.
=begin
# raise exception for the case of db2 installation under nonAdmin & group mode
if node['workflow']['install_mode'] != 'admin' && node['db2']['install'] == 'true'
   Chef::Log.fatal "Admin Verification: DB2 must be installed under admin mode"
   raise "Admin Verification: DB2 must be installed under admin mode"
end
=end

if node['db2']['install'] == 'true'

  if node['db2']['port'].nil? || !(node['db2']['port'] =~ /^[1-9][0-9]*$/)
    Chef::Log.fatal "DB2 Settings Verification: DB2 port must be specified with valid positive num"
    raise "DB2 Settings Verification: DB2 port must be specified with valid positive num"
  end

  # TODO: do more check if the user name and password is valid later
  if node['db2']['username'].nil? || node['db2']['username'].empty?
    Chef::Log.fatal "DB2 Settings Verification: DB2 user name must NOT be blank"
    raise "DB2 Settings Verification: DB2 user name must NOT be blank"
  end

  if db2_password.nil? || db2_password.empty?
    Chef::Log.fatal "DB2 Settings Verification: DB2 user password must NOT be blank"
    raise "DB2 Settings Verification: DB2 user password must NOT be blank"
  end

  if node['db2']['fenced_username'].nil? || node['db2']['fenced_username'].empty?
    Chef::Log.fatal "DB2 Settings Verification: DB2 fenced user name must NOT be blank"
    raise "DB2 Settings Verification: DB2 fenced user name must NOT be blank"
  end

  if db2_fenced_password.nil? || db2_fenced_password.empty?
    Chef::Log.fatal "DB2 Settings Verification: DB2 fenced user password must NOT be blank"
    raise "DB2 Settings Verification: DB2 fenced user password must NOT be blank"
  end

  if node['db2']['das_username'].nil? || node['db2']['das_username'].empty?
    Chef::Log.fatal "DB2 Settings Verification: DB2 das user name must NOT be blank"
    raise "DB2 Settings Verification: DB2 das user name must NOT be blank"
  end

  if db2_das_password.nil? || db2_das_password.empty?
    Chef::Log.fatal "DB2 Settings Verification: DB2 das user password must NOT be blank"
    raise "DB2 Settings Verification: DB2 das user password must NOT be blank"
  end
end

if !(['WorkflowEnterprise.Production', 'WorkflowEnterprise.NonProduction', 'EnterpriseServiceBus.Production', 'EnterpriseServiceBus.NonProduction', 'WorkflowExpress.Production', 'WorkflowExpress.NonProduction'].include? node['workflow']['features'])
    Chef::Log.fatal "Please make sure you have the right value for attribute ['workflow']['features'], the input one is #{node['workflow']['features']}"
    raise "Please make sure you have the right value for attribute ['workflow']['features'], the input one is #{node['workflow']['features']}"
end

# TODO: check feature
# TODO: extract check to one appropriate place

# Construct template name according to workflow edition and db2 install
template_name = 'workflow' + node['workflow']['edition']

if node['db2']['install'] == 'true'
  if node['workflow']['install_mode'] != 'admin'
    # in the case, install db2 using separate template, otherwise,
    # install db2 using same template as workflow/was.
    db2_template_name = 'DB2_linux_response_root_64bit.xml'
  else
    template_name = template_name + '_DB2'
  end
end

case node['workflow']['install_mode']
  when 'admin'
    template_name = template_name + '_linux_response_root_64bit.xml'
  when 'nonAdmin'
    template_name = template_name + '_linux_response_nonroot_64bit.xml'
  when 'group'
    template_name = template_name + '_linux_response_group_64bit.xml'
end

Chef::Log.info("template_name:#{template_name}, db2_template_name:#{db2_template_name}")

# Determine if https is used
repo_nonsecureMode = 'false'
secure_repo = 'false'
# the secure_repo, in theory, is nothing with https/http, but by test, the basic authentication
# is always enabled for the https request. 
# TODO: decouple the https with secure_repo later
if node['ibm']['sw_repo'].match(/^https:\/\//)
  repo_nonsecureMode = 'true'
  secure_repo = 'true'
end
Chef::Log.info("repo_nonsecureMode: #{repo_nonsecureMode}")

Chef::Resource::User.send(:include, IM::Helper)

workflow_install 'ibm_workflow' do
  sw_repo  node['ibm']['sw_repo']
  workflow_expand_area  node['ibm']['expand_area']
  install_dir  node['workflow']['install_dir']
  response_file  template_name
  db2_response_file  db2_template_name
  offering_id  node['workflow']['offering_id']
  offering_version  node['workflow']['offering_version']
  im_version  node['workflow']['im_version']
  was_offering_id  node['was']['offering_id']
  db2_offering_id  node['db2']['offering_id']
  db2_offering_version  node['db2']['offering_version']
  profile_id  node['workflow']['profile_id']
  feature_list  node['workflow']['features']
  im_install_mode  node['workflow']['install_mode']
  ibm_log_dir  node['ibm']['log_dir']
  user  node['workflow']['runas_user']
  group  node['workflow']['runas_group']
  secure_repo  secure_repo # if it's true, need set vault info using ['workflow']['vault'] ...
  repo_nonsecureMode  repo_nonsecureMode
  # db2 settings
  db2_install  node['db2']['install']
  db2_port  node['db2']['port']
  db2_username  node['db2']['username']
  db2_password  db2_password
  db2_das_newuser  node['db2']['das_newuser']
  db2_fenced_newuser  node['db2']['fenced_newuser']
  db2_fenced_username  node['db2']['fenced_username']
  db2_fenced_password  db2_fenced_password
  db2_das_username  node['db2']['das_username']
  db2_das_password  db2_das_password
  action [:prepare, :install_im, :install, :cleanup]
end