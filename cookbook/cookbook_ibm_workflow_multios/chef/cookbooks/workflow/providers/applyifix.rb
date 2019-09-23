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
#

include IM::Helper
include WF::Helper
use_inline_resources

# Create Action prepare
action :prepare do
  [node['ibm']['temp_dir'], node['ibm']['expand_area']].each do |dir|
      directory dir do
        recursive true
        action :create
        mode '0755'
      end
  end
end

# Create Action apply
action :apply do
  ifix_names = new_resource.ifix_names

  if ifix_names.nil? || ifix_names.empty? || ifix_names.lstrip.empty?
    Chef::Log.info "applyifix #{@new_resource} no ifixes need by installed - nothing to do."
  else
    converge_by("applyifix #{@new_resource}") do

      ifix_names = ifix_names.split(",")
      im_install_dir = define_im_install_dir
      im_folder_permission = define_im_folder_permission
      user = define_user
      group = define_group
      #user = node['workflow']['runas_user']
      #group = node['workflow']['runas_group']

      ifixes_expand_area = node['ibm']['expand_area'] + '/ifixes'
      # Manage base directory - Ifixes directory
      subdirs = subdirs_to_create(ifixes_expand_area, user)
      Chef::Log.info "#{subdirs}"
      subdirs.each do |dir|
        directory dir do
          action :create
          recursive true
          owner user
          group group
        end
      end

      # Write repository.config, will override if exists
      # TODO: no need to write new repository.config file if no ifixes need be installed.
      need_install = false
      ruby_block "genereate: ifixes repository.config" do
        block do
          repository_config_filename = ifixes_expand_area  + "/repository.config"
          repository_config = open(repository_config_filename, 'w')
          begin
            FileUtils.chown user, group, repository_config
            repository_config.puts("LayoutPolicy=Composite")
            repository_config.puts("LayoutPolicyVersion=0.0.0.1")


            repo_paths = new_resource.ifix_repo
            ifix_names.each_with_index do |ifix_name, index|
              Chef::Log.info("Unpacking #{ifix_name}...")
              # ignore if the ifix_name is not valid
              next if ifix_name.nil? || ifix_name.lstrip.empty?

              # remove the blanks before and after the ifix name
              ifix_name = ifix_name.lstrip.rstrip
              ifix_zip_name = ifix_name + ".zip"
              # If the input ifix_name is with .zip, handle it
              if ifix_name =~ /\.zip$/
                ifix_zip_name = ifix_name
                ifix_name = ::File.basename(ifix_name, ".zip").to_s
              end

              unless ifix_installed?(im_install_dir, ifix_name, user)
                ibm_cloud_utils_unpack "unpack-#{ifix_name}" do
                  source "#{repo_paths}/#{ifix_zip_name}"
                  target_dir ifixes_expand_area + "/#{ifix_name}"
                  mode im_folder_permission
                  #checksum md5
                  owner user
                  group group
                  remove_local true
                  secure_repo new_resource.secure_repo
                  vault_name node['workflow']['vault']['name']
                  vault_item node['workflow']['vault']['encrypted_id']
                  repo_self_signed_cert new_resource.repo_nonsecureMode
                end

                need_install = true
                repository_config.puts("repository.url.#{index}=./#{ifix_name}")
              end
            end
          ensure
            # close file in finally block, always!
            repository_config.close
          end
        end
      end

      # info for current node
      serverName = compute_server_name(new_resource.node_hostnames, node['hostname'])
      nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])
      Chef::Log.info("Information of current node - serverName:  #{serverName}, nodeIndex: #{nodeIndex}")

      # stop environment before installing ifixes
      ruby_block "stop: stop environment after applying ifixes" do
        block do
          stop_env(user, nodeIndex, serverName, group, new_resource.install_dir, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password)
        end
        only_if { need_install }
      end

      # set "-preferences offering.service.repositories.areUsed=false" to apply ifixes only
      cmd = "./imcl updateAll -preferences offering.service.repositories.areUsed=false -repositories #{ifixes_expand_area} -acceptLicense -installationDirectory #{new_resource.install_dir} -installFixes all"
      execute "applyifix_#{new_resource.name}" do
        # Install ifixes
        cwd "#{im_install_dir}/eclipse/tools"
        command cmd
        user user
        group group
        only_if { need_install }
      end

      # TODO: evidence
    end
  end
end

# TODO: refactoring to reuse same logic as 'install' provider

# define im installation directory
# if not specified, return default value based on im_install_mode
def define_im_install_dir
  user = define_user
  case new_resource.im_install_mode
  when 'admin'
    im_install_dir = if new_resource.im_install_dir.nil?
                       '/opt/IBM/InstallationManager'
                     else
                       new_resource.im_install_dir
                     end
    im_install_dir
  when 'nonAdmin'
    im_install_dir = if new_resource.im_install_dir.nil?
                       '/home/' + user + '/IBM/InstallationManager'
                     else
                       new_resource.im_install_dir
                     end
    im_install_dir
  when 'group'
    im_install_dir = if new_resource.im_install_dir.nil?
                       '/home/' + user + '/IBM/InstallationManager_Group'
                     else
                       new_resource.im_install_dir
                     end
    im_install_dir
  end
end

# define im folder permission
def define_im_folder_permission
  case new_resource.im_install_mode
  when 'admin'
    im_folder_permission = '755'
    im_folder_permission
  when 'nonAdmin', 'group'
    im_folder_permission = '775'
    im_folder_permission
  end
end

# define workflow user
# if not specified, return default value based on im_install_mode
# validate if specified user exists, meanwhile
def define_user
  case new_resource.im_install_mode
  when 'admin'
    user = if new_resource.user.nil?
             'root'
           else
             unless im_user_exists_unix?(new_resource.user)
               Chef::Log.fatal "User Name provided #{new_resource.user}, does not exist"
               raise "User Verification 1: User Name provided #{new_resource.user}, does not exist"
             end
             new_resource.user
           end
    user
  when 'nonAdmin', 'group'
    user = if new_resource.user.nil?
             Chef::Log.fatal "User Name not provided! Please provide the user that should be used to install your product"
             raise "User Name not provided! Please provide the user that should be used to install your product"
           else
             unless im_user_exists_unix?(new_resource.user)
               Chef::Log.fatal "User Name provided #{new_resource.user}, does not exist"
               raise "User Verification 1: User Name provided #{new_resource.user}, does not exist"
             end
             new_resource.user
           end
    user
  end
end

# define workflow group
# if not specified, return default value based on im_install_mode
def define_group
  case new_resource.im_install_mode
  when 'admin'
    group = if new_resource.group.nil?
              'root'
            else
              new_resource.group
            end
    group
  when 'nonAdmin', 'group'
    group = if new_resource.group.nil?
              Chef::Log.fatal "Group not provided! Please provide the group that should be used to install your product"
              raise "Group not provided! Please provide the group that should be used to install your product"
            else
              new_resource.group
            end
    group
  end
end