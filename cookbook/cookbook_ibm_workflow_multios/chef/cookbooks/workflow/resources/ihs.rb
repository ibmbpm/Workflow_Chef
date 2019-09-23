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
# Provider:: workflow_ihs
#

actions :configure, :restart
default_action :configure

# <> The user to run all actions
property :runas_user, String, required: true

# <> The group to run all actions
property :runas_group, String, required: true

# <> The install directory of IHS, typical /opt/IBM/HTTPServer
property :ihs_install_root, String, required: true

# <> The keystore path, e.g. /opt/IBM/HTTPServer/conf/my_keystore.kdb
property :ihs_keystore, String, required: true

# <> The password to the keystore
property :ihs_keystore_password, String, required: true

# <> The host name if IHS
property :ihs_host_name, String, required: true

# <> The port to run SSL at, if the port is lower that 1000 the runas_user must be able to sudo
property :ihs_port, String, required: true
