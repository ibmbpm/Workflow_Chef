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
# Recipe::prereq_check
#
# <> This recipe will check the environment prior to installing software.
#

# TODO: check memory, disk, OS etc. Followup Workflow pre-requisites IC info

Chef::Log.info("prereq_check: checking environment ...")

# check environment - disk
im_install_dir = node['workflow']['im_install_dir']
install_dir = node['workflow']['install_dir']
# TODO: what's official settings? Seems the codes don't work for Ubuntu
# TODO: need consider idempotence, the codes are executed more than one time
=begin
dirs = { '/' => 30720,
         '/tmp' => 10,
         im_install_dir => 500,
         node['ibm']['temp_dir'] => 10240,
         install_dir => 15360 }
dirs.each_pair do |dir, size|
  ibm_cloud_utils_freespace "check-freespace-for-#{dir}-directory" do
    path dir
    required_space size
    continue true
    action :check
    error_message "Please make sure you have at least #{size}MB free space under #{dir}"
  end
end
=end