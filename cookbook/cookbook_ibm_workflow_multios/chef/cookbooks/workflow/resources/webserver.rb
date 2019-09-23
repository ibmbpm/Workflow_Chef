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
# Provider:: workflow_webserver
#
actions :create, :retrieve_ihs_certificate, :propagate
default_action :create

# <> The workflow install directory
property :install_dir, String, required: true

# <> The workflow admin user
property :deadmin_alias_user, String, required: true

# <> The workflow admin password
property :deadmin_alias_password, String, required: true

# <> The workflow runas user
property :runas_user, String, required: true

# <> The workflow runas group
property :runas_group, String, required: true

# <> The workflow Dmgr hostname
property :dmgr_hostname, String, required: true

# <> The name of the IHS cell
property :ihs_cell_name, String, required: true

# <> The name of the IHS (unmanaged) node
property :ihs_node_name, String, required: true

# <> The host name of the IHS web server
property :ihs_host_name, String, required: true

# <> The web port of the web server
property :ihs_port, String, required: true

# <> The directory where IHS is installed
property :ihs_install_root, String, required: true

# <> The plugin directory of IHS
property :ihs_plugin_root, String, required: true

# <> The IHS admin port
property :ihs_admin_port, String, required: true

# <> The IHS admin user
property :ihs_admin_user, String, required: true

# <> The IHS admin password
property :ihs_admin_password, String, required: true
