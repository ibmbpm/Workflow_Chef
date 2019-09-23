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
# Provider:: workflow_install
#

actions :prepare, :install_im, :install, :cleanup
default_action :install

# <> The repository to search.
property :sw_repo, String, required: true

# <> If the software repo is public this should be set to "false"
property :secure_repo, String, default: 'true'

# <> If the Software repo is secured but it uses a self signed SSL certificate this should be set to "true"
property :repo_nonsecureMode, String, default: 'false'

# <> The response file for the IBM Installation Manager.
property :response_file, String, required: true

# <> The DB2 response file for the IBM Installation Manager.
property :db2_response_file, String

# <> Temp directory for the product will be downloaded and unpacked
property :workflow_expand_area, String, required: true

# <> Installation directory for the product that is installed using this LWRP
property :install_dir, String, required: true

# <> Offering ID. You can find the value in your IMRepo. Each Product has a different ID
# possible values:
# offering_id                                            profile_id
# com.ibm.bpm.ADV.v85		->	   IBM Business Automation Workflow 18001
property :offering_id, String, required: true

# <> Offering version. You can find the value in your IMRepo.
property :offering_version, String, required: true

# <> WAS offering ID. You can find the value in your IMRepo. Each Product has a different ID
# possible values:
# was_offering_id                                        profile_id
# com.ibm.websphere.ND.v85      ->         IBM WebSphere Application Server V8.5
property :was_offering_id, String, required: true

# <> DB2 offering ID. You can find the value in your IMRepo. Each Product has a different ID
# possible values:
# db2_offering_id                                        profile_id
# com.ibm.ws.DB2EXP.linuxia64   ->         IBM DB2 Advanced Workgroup Server Edition
property :db2_offering_id, String

# DB2 offering version. You can find the value in your IMRepo.
property :db2_offering_version, String

# <> Profile ID. This is a description of the product
property :profile_id, String, required: true

# <> Feature list for the product. This is a list of components that should be installed for a specific product
property :feature_list, String, required: true

# <> Directory where installation artifacts are stored.
property :im_shared_dir, String

# <> User used to install IM and that should be used to install a product
property :user, String, required: true

# <> Group used to install IM and that should be used to install a product
property :group, String, required: true

# <> Installation mode used to install IM and that should be used to install a product
property :im_install_mode, String, required: true, default: 'admin'

# <> Directory where im was installed
property :im_install_dir, String

# <> An absolute path to a directory that will be used to hold any persistent files created as part of the automation
property :ibm_log_dir, String

# <> Installation Manager Version Number to be installed. Supported versions: 1.8.9 for Workflow 18.0.0.1
property :im_version, String, required: true

# <> Installation Manager Data Directory
property :im_data_dir, String


# <> Install DB2 Advanced Workgroup Server Edition
# <> Install Embeded DB2 or not
property :db2_install, String, default: 'false'

# <> Port, DB2 connection port
property :db2_port, String, default: '50000'

# <> DB2 instance user name, db2inst1 as default
property :db2_username, String, default: 'db2inst1'

# <> DB2 instance user password
property :db2_password, String

# <> Create new DB2 das user or not
property :db2_das_newuser, String, default: 'true'

# <> Create new DB2 fenced user or not
property :db2_fenced_newuser, String, default: 'true'

# <> DB2 das user name, dasusr1 as default
property :db2_das_username, String, default: 'dasusr1'

# <> DB2 das user password
property :db2_das_password, String

# <> DB2 fenced user name, db2fenc1 as default
property :db2_fenced_username, String, default: 'db2fenc1'

# <> DB2 fenced user password
property :db2_fenced_password, String

attr_accessor :im_installed
attr_accessor :installed
