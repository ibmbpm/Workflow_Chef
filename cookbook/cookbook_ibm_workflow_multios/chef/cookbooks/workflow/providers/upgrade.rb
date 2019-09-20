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
# Provider:: workflow_upgrade
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
  fixpack_names_list = new_resource.fixpack_names_list
  if fixpack_names_list.nil? || fixpack_names_list.empty? || fixpack_names_list.lstrip.empty? 
    Chef::Log.info "upgrade #{@new_resource} no fixpack need be installed - nothing to do."
  else
    converge_by("upgrade #{@new_resource}") do

      fixpack_names_list = fixpack_names_list.split(",")
      im_install_dir = define_im_install_dir
      im_folder_permission = define_im_folder_permission
      user = define_user
      group = define_group

      fixpack_expand_area = node['ibm']['expand_area'] + '/fixpacks'
      # Manage base directory - fixpack directory
      subdirs = subdirs_to_create(fixpack_expand_area, user)
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
      # TODO: no need to write new repository.config file if no fixpack need be installed.
      need_install = false
      # attention: record if the fixpack is installed by Chef scripts, don't support the case that customer handle the 'upgrade' manually.
      installed_fixpacks_filename = "#{new_resource.install_dir}/chef-state/upgrade/installed_fixpacks"
      temp_installed_fixpacks_filename = "#{new_resource.install_dir}/chef-state/upgrade/.installed_fixpacks_temp"
      directory "#{new_resource.install_dir}/chef-state" do
        owner user
        group group
        action :create
      end
      directory "#{new_resource.install_dir}/chef-state/upgrade" do
        owner user
        group group
        action :create
      end

      Chef::Log.info "installed_fixpacks exist?:#{::File.exist?(installed_fixpacks_filename)}"
      file installed_fixpacks_filename do
        content ''
        owner user
        group group
        action :create
        only_if { !::File.exist?(installed_fixpacks_filename) }
      end
      # clean content of the temp file if exists, otherwise create new one with empty content
      file temp_installed_fixpacks_filename do
        content ''
        owner user
        group group
        action :create
      end

      ruby_block "prepare: download fixpack & repository.config" do
        block do
          repository_config_filename = fixpack_expand_area  + "/repository.config"
          repository_config = open(repository_config_filename, 'w')

          tempfile = open(temp_installed_fixpacks_filename, "w")
          begin
            FileUtils.chown user, group, repository_config
            repository_config.puts("LayoutPolicy=Composite")
            repository_config.puts("LayoutPolicyVersion=0.0.0.1")

            repo_paths = new_resource.fixpack_repo

            valid_fixpacks = []
            fixpack_names_list.each_with_index do |fixpack_name, index|
              Chef::Log.info("Deal with #{fixpack_name}...")
              # ignore if the fixpack is not valid
              next if fixpack_name.nil? || fixpack_name.strip.empty? || fixpack_name.strip == ".zip"

              # remove the blanks before and after the fixpack name
              fixpack_name = fixpack_name.strip

              # Fixpack multiple parts support
              unzip_folder_name = ''
              fixpack_parts = fixpack_name.split(";")

              next if fixpack_parts.nil? || fixpack_parts.size == 0

              valid_fixpack_parts = []
              valid_fixpack_parts_hash = Hash.new
              fixpack_parts.each_with_index do |fixpack_part, idx|
                next if fixpack_part.nil? || fixpack_part.strip.empty? || fixpack_part.strip == ".zip"

                # remove the blanks before and after the fixpack part name
                fixpack_part = fixpack_part.strip

                fixpack_part_zip_name = fixpack_part + ".zip"
                # If the input fixpack_part is with .zip, handle it
                if fixpack_part =~ /\.zip$/
                  fixpack_part_zip_name = fixpack_part
                  fixpack_part = ::File.basename(fixpack_part, ".zip").to_s
                end

                # avoid duplicated parts
                next if valid_fixpack_parts.include?(fixpack_part)
                valid_fixpack_parts.push(fixpack_part)

                # use the 1st valid part name as whole fixpack folder name, to avoid in valid folder name and length
                unzip_folder_name = fixpack_part if unzip_folder_name.empty?

                valid_fixpack_parts_hash[fixpack_part]=fixpack_part_zip_name
              end
              # no valid fixpack/fixpack parts
              next if valid_fixpack_parts.size == 0

              fixpack_qualified_name = valid_fixpack_parts_hash.keys.sort.to_s
              Chef::Log.info ("The qualified name of the fixpack: #{fixpack_qualified_name}")

              # avoid duplicated fixpacks
              next if valid_fixpacks.include?(fixpack_qualified_name)
              valid_fixpacks.push(fixpack_qualified_name)

              match = false
              # match using multiple parts together
              ::File.open(installed_fixpacks_filename).each do |line|
                Chef::Log.info "installed_fixpacks line=#{line}"
                if !line.nil? && line.strip.eql?(fixpack_qualified_name)
                  match = true
                  Chef::Log.info "Match the fixipack(#{fixpack_qualified_name}): #{match}"
                  break
                end
              end
              # continue if found the fixpack part in the installed_fixpacks file
              # or break directly?
              next if match

              # append the content to end of the file
              tempfile.puts fixpack_qualified_name

              Chef::Log.info ("Ready to download fixpack: #{fixpack_qualified_name}")
              valid_fixpack_parts_hash.keys.sort.each do |fixpack_part|
                fixpack_part_zip_name = valid_fixpack_parts_hash[fixpack_part]

                ibm_cloud_utils_unpack "unpack-#{fixpack_part}" do
                  source "#{repo_paths}/#{fixpack_part_zip_name}"
                  target_dir fixpack_expand_area + "/#{unzip_folder_name}"
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
              end

              repository_config.puts("repository.url.#{index}=./#{unzip_folder_name}")
              need_install = true
            end
          ensure
            # close file in finally block, always!
            repository_config.close
            tempfile.close
          end
        end
      end

      # stop environment before upgrade, and the environment will be started in continuous role.
      ruby_block "stop: stop environment before upgrade" do
        block do
          # info for current node
          serverName = compute_server_name(new_resource.node_hostnames, node['hostname'])
          nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])
          Chef::Log.info("Information of current node - serverName:  #{serverName}, nodeIndex: #{nodeIndex}")

          stop_env(user, nodeIndex, serverName, group, new_resource.install_dir, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password)
        end
        only_if { need_install }
      end

      # set "-preferences offering.service.repositories.areUsed=false" to upgrade only
      cmd = "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./imcl updateAll -preferences offering.service.repositories.areUsed=false -repositories #{fixpack_expand_area} -acceptLicense -installationDirectory #{new_resource.install_dir}"
      Chef::Log.info("Upgrade command:  #{cmd}")
      execute "upgrade_#{new_resource.name}" do
        # Upgrade
        cwd "#{im_install_dir}/eclipse/tools"
        command cmd
        user user
        group group
        only_if { need_install }
      end

      # dbupgrade command, itself doesn't support full idempotence, so, if it fails, no way to support 're-run'
      # but, if it sucesses, then, re-run won't actually happen if still same version, it's idempotence in this way.
      # issue 113 AdvancedOnly doesn't need dbupgrade according to KC
      if new_resource.product_type != 'AdvancedOnly'
          Chef::Log.info("Run dbupgrade: #{new_resource.product_type}")
          cmd = "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; echo 'y' | ./DBUpgrade.sh -profileName DmgrProfile"
          Chef::Log.info("DBUpgrade command:  #{cmd}")
          execute "dbupgrade_#{new_resource.name}" do
            cwd "#{new_resource.install_dir}/bin"
            command cmd
            user user
            group group
            only_if { need_install && ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")}
          end
      else
          Chef::Log.info("Ignore dbupgrade: #{new_resource.product_type}")
      end
      

      # write the content of temp file to the main file, for that the upgrade for the fixpacks are done.
      ruby_block "write #{installed_fixpacks_filename}" do
        block do
          installed_fixpacks = open(installed_fixpacks_filename, "a")
          begin
            ::File.open(temp_installed_fixpacks_filename).each do |line|
              Chef::Log.info "temp_installed_fixpacks_filename, line: #{line}"
              installed_fixpacks.puts line
            end
          ensure
            installed_fixpacks.close
          end
        end
        only_if { need_install }
      end
      # delete temp file if exists
      file temp_installed_fixpacks_filename do
        owner user
        group group
        action :delete
      end

      # TODO: evidence
    end
  end
end

# Create Action cleanup
# Cleanup the installed_fixpacks after whole-deployment, avoid multiple-times download/unzip fixpacks in one-time deployment
action :cleanup do
  user = define_user
  group = define_group
  # delete installed_fixpacks if exists
  file "#{new_resource.install_dir}/chef-state/upgrade/installed_fixpacks" do
    owner user
    group group
    action :delete
  end

  fixpack_expand_area = node['ibm']['expand_area'] + '/fixpacks'
  Chef::Log.info("Cleanup #{fixpack_expand_area} \n")
  directory fixpack_expand_area do
    recursive true
    action :delete
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
