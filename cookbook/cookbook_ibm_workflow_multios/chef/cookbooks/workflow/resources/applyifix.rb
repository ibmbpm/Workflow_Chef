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
# Provider:: workflow_applyifix

actions :apply, :prepare
default_action :apply

# <> The repository to search ifixes.
property :ifix_repo, String, default: node['ibm']['ifix_repo']

# <> Ifix names, format like "ifix1.zip, ifix2,zip, ifix3.zip"
property :ifix_names, String

# <> Installation directory for the product that is installed using this LWRP
property :install_dir, String, required: true

# <> Installation mode used to install IM and that should be used to install a product
property :im_install_mode, String, required: true, default: 'admin'

# <> Directory where im was installed
property :im_install_dir, String

# <> User used to install IM and that should be used to install a product
property :user, String, required: true

# <> Group used to install IM and that should be used to install a product
property :group, String, required: true

# <> The fully qualified domain names of all node, format like "node01_hostname, node02_hostname, node03_hostname"
property :node_hostnames, String

# <> The user name of the cell administrator.
property :celladmin_alias_user, String

# <> The password of the cell administrator.
property :celladmin_alias_password, String

# <> If the software repo is public this should be set to "false"
property :secure_repo, String, default: 'true'

# <> If the Software repo is secured but it uses a self signed SSL certificate this should be set to "true"
property :repo_nonsecureMode, String, default: 'false'