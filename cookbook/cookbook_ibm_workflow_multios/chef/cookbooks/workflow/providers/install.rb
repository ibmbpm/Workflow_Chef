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

include IM::Helper
include WF::Helper
use_inline_resources

# Create Action preare
action :prepare do
  install_prepare_done = new_resource.workflow_expand_area + '/install_prepare_done'

  if ::File.exist?(install_prepare_done)
    Chef::Log.info("#{install_prepare_done} exists, nothing to do.")
  elsif @current_resource.im_installed && @current_resource.installed
    Chef::Log.info("In the case of 'im_installed && installed', nothing to do.")
  else
    converge_by("prepare_install #{@new_resource}") do
      repo_paths = new_resource.sw_repo
      workflow_expand_area = new_resource.workflow_expand_area

      runas_user = define_user
      runas_group = define_group

      im_folder_permission = define_im_folder_permission

      im_archive_names = node['workflow']['archive_names']
      im_archive_names.each_pair do |p, v|
        filename = v['filename']
        #md5 = v['md5']
        Chef::Log.info("Unpacking #{filename}...")

        ibm_cloud_utils_unpack "unpack-#{filename}" do
          source "#{repo_paths}/#{filename}"
          target_dir workflow_expand_area
          mode im_folder_permission
          #checksum md5
          owner runas_user
          group runas_group
          remove_local true
          secure_repo new_resource.secure_repo
          vault_name node['workflow']['vault']['name']
          vault_item node['workflow']['vault']['encrypted_id']
          repo_self_signed_cert new_resource.repo_nonsecureMode
        end
      end

      # create directories in advance
      # ibm log directory
      ibm_log_dir = define_ibm_log_dir
      create_dir(ibm_log_dir, runas_user, runas_group)

      # workflow installation directory
      create_dir(new_resource.install_dir, runas_user, runas_group)

      # IM installation directory
      im_install_dir = define_im_install_dir
      create_dir(im_install_dir, runas_user, runas_group)

      # IM data directory
      im_data_dir = define_im_data_dir
      create_dir(im_data_dir, runas_user, runas_group)

      # IM shared directory
      im_shared_dir = define_im_shared_dir
      create_dir(im_shared_dir, runas_user, runas_group)

      # remember for later runs
      file "#{install_prepare_done}" do
        owner runas_user
        group runas_group
        content "#{SecureRandom.hex}"
        action :create
      end
    end
  end
end

# Create Action cleanup
# Cleanup environment after Workflow installation
action :cleanup do
  expand_dir = new_resource.workflow_expand_area
  Chef::Log.info("Cleanup #{expand_dir} \n")
  directory expand_dir do
    recursive true
    action :delete
  end
end

# Create Action install_im
action :install_im do
  if @current_resource.im_installed
    Chef::Log.info "#{@new_resource} already exists - nothing to do."
  else
    converge_by("install_im #{@new_resource}") do

      im_install_dir = define_im_install_dir
      im_data_dir = define_im_data_dir
      im_shared_dir = define_im_shared_dir
      im_folder_permission = define_im_folder_permission

      user = define_user
      group = define_group

      # install the 64bit directly for that only 64bit OS is supported by Workflow, if need, extract and allow install 32bit for 32bit OS.
      im_repo = new_resource.workflow_expand_area + '/IM64'

      ibm_log_dir = define_ibm_log_dir
      im_log_dir = ibm_log_dir + '/im'

      # evidence for im
      im_evidence_dir = ibm_log_dir + '/evidence'

      # create the folders needed
      [im_log_dir, im_evidence_dir, "#{im_install_dir}/eclipse"].each do |dir|
        directory dir do
          recursive true
          action :create
          mode im_folder_permission
          owner user
          group group
        end
      end

      # run the install - With im_shared_dir set (Above V1.8)
      execute "installim_#{new_resource.name}" do
        # install the 64bit directly for that only 64bit OS is supported by Workflow, if need, extract and allow install 32bit for 32bit OS.
        cwd "#{im_repo}/tools"
        command %( ./imcl install com.ibm.cic.agent -repositories #{im_repo} -installationDirectory #{im_install_dir}/eclipse -accessRights #{new_resource.im_install_mode} -acceptLicense -dataLocation #{im_data_dir} -sharedResourcesDirectory #{im_shared_dir} -log #{im_log_dir}/IM.install.log)
        user user
        group group
        not_if { im_installed?(im_install_dir, new_resource.im_version, user) }
      end

      evidence_tar = "#{im_evidence_dir}/im-#{cookbook_name}-#{node['hostname']}-#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.tar"
      evidence_log = "#{cookbook_name}-#{node['hostname']}.log"
      # run validation script
      execute 'Verify IM installation' do
        user user
        group group
        command "#{im_install_dir}/eclipse/tools/imcl version >> #{im_log_dir}/#{evidence_log}"
        only_if { Dir.glob("#{evidence_tar}").empty? }
      end

      # tar logs
      ibm_cloud_utils_tar "Create_#{evidence_tar}" do
        source "#{im_log_dir}/#{evidence_log}"
        target_tar evidence_tar
        only_if { Dir.glob("#{evidence_tar}").empty? }
      end

      # clean up evidence log
      #["#{im_log_dir}/#{evidence_log}"].each do |dir|
      #  file dir do
      #    action :delete
      #  end
      #end
    end
  end
end

action :install do
  if @current_resource.installed
    Chef::Log.info "#{@new_resource} already exists - nothing to do."
  elsif @current_resource.im_installed
    converge_by("install #{@new_resource}") do

      im_install_dir = define_im_install_dir
      im_shared_dir = define_im_shared_dir
      ibm_log_dir = define_ibm_log_dir

      workflow_log_dir = ibm_log_dir + '/workflow'

      workflow_repo = new_resource.workflow_expand_area + '/repository/repos_64bit'
      im_repo = new_resource.workflow_expand_area + '/IM64'

      user = define_user
      group = define_group

      if !(new_resource.db2_response_file.nil? || new_resource.db2_response_file.empty?)
        # re-encrypt the passwords using './imutilsc -s encryptString xxx', IM need encrypted passwords
        cmd_out = shell_out!("#{im_repo}/tools/imutilsc -s encryptString " + new_resource.db2_password)
        db2_password = cmd_out.stdout

        db2_fenced_password = ''
        db2_das_password = ''
        if new_resource.db2_install == 'true'
          cmd_out = shell_out!("#{im_repo}/tools/imutilsc -s encryptString " + new_resource.db2_fenced_password)
          db2_fenced_password = cmd_out.stdout
          cmd_out = shell_out!("#{im_repo}/tools/imutilsc -s encryptString " + new_resource.db2_das_password)
          db2_das_password = cmd_out.stdout
        end

        db2_log_dir = ibm_log_dir + '/db2'
        db2_im_data_dir = '/var/ibm/InstallationManager_DB2'
        db2_install_dir = '/opt/IBM/DB2wWAS'
        db2_install_mode = 'admin'
        db2_install_user = 'root'
        db2_install_group = 'root'

        db2_silent_install_file="#{im_repo}/#{new_resource.db2_offering_id}_#{new_resource.db2_response_file}"

        template db2_silent_install_file do
          source 'responsefiles/' + new_resource.db2_response_file + '.erb'
          variables(
            :REPO_LOCATION => workflow_repo,
            :IM_REPO_LOCATION => im_repo,
            :INSTALL_LOCATION => db2_install_dir,
            :PROFILE_ID => new_resource.profile_id,
            :WAS_OFFERING_ID => new_resource.was_offering_id,
            :DB2_OFFERING_ID => new_resource.db2_offering_id,
            :DB2_PORT => new_resource.db2_port,
            :DB2INSTANCE_USERID => new_resource.db2_username,
            :ENCRYPTED_PWD => db2_password,
            :DB2_DAS_NEWUSER => new_resource.db2_das_newuser,
            :DB2_FENCED_NEWUSER => new_resource.db2_fenced_newuser,
            :DB2FENCED_USERID => new_resource.db2_fenced_username,
            :DB2FENCED_ENCRYPTED_PWD => db2_fenced_password,
            :DB2DAS_USERID => new_resource.db2_das_username,
            :DB2DAS_ENCRYPTED_PWD => db2_das_password
          )
        end

        # use 'userinstc', 'installc' or 'groupinstc' seperately or specify different install mode
        install_command = "./imcl input #{db2_silent_install_file} -dataLocation #{db2_im_data_dir} -showProgress -accessRights #{db2_install_mode} -acceptLicense -log #{db2_log_dir}/#{new_resource.db2_offering_id}.install.log"

        execute "install #{new_resource.name}" do
          user db2_install_user
          group db2_install_group
          cwd im_repo + '/tools'
          command install_command
          not_if { ibm_installed_from_data?(im_repo + '/tools', db2_im_data_dir, new_resource.db2_offering_id, '', db2_install_user) }
        end
      end

      silent_install_file="#{im_install_dir}/#{new_resource.offering_id}_#{new_resource.response_file}"

      template silent_install_file do
        source 'responsefiles/' + new_resource.response_file + '.erb'
        variables(
          :REPO_LOCATION => workflow_repo,
          :IM_REPO_LOCATION => im_repo,
          :INSTALL_LOCATION => new_resource.install_dir,
          :IM_INSTALL_LOCATION => im_install_dir,
          :WAS_OFFERING_ID => new_resource.was_offering_id,
          :DB2_OFFERING_ID => new_resource.db2_offering_id,
          :DB2_PORT => new_resource.db2_port,
          :DB2INSTANCE_USERID => new_resource.db2_username,
          :ENCRYPTED_PWD => db2_password,
          :DB2_DAS_NEWUSER => new_resource.db2_das_newuser,
          :DB2_FENCED_NEWUSER => new_resource.db2_fenced_newuser,
          :DB2FENCED_USERID => new_resource.db2_fenced_username,
          :DB2FENCED_ENCRYPTED_PWD => db2_fenced_password,
          :DB2DAS_USERID => new_resource.db2_das_username,
          :DB2DAS_ENCRYPTED_PWD => db2_das_password,
          :OFFERING_ID => new_resource.offering_id,
          :FEATURE_LIST => new_resource.feature_list,
          :PROFILE_ID => new_resource.profile_id,
          :IMSHARED => im_shared_dir
        )
      end

      # use 'userinstc', 'installc' or 'groupinstc' seperately or specify different install mode
      install_command = "./imcl input #{silent_install_file} -showProgress -accessRights #{new_resource.im_install_mode} -acceptLicense -log #{workflow_log_dir}/#{new_resource.offering_id}.install.log"

      execute "install #{new_resource.name}" do
        user user
        group group
        cwd im_install_dir + '/eclipse/tools'
        command install_command

        # TODO: for admin mode, DB2 will be installed.
        # workflow installation success doesn't mean that DB2 installation success.
        not_if { ibm_installed?(im_install_dir, new_resource.offering_id, '', user) }
      end

      workflow_evidence_dir = ibm_log_dir + '/evidence'
      im_folder_permission = define_im_folder_permission
      [workflow_log_dir, workflow_evidence_dir].each do |dir|
        directory dir do
          recursive true
          action :create
          mode im_folder_permission
          owner user
          group group
        end
      end

      evidence_tar = "#{workflow_evidence_dir}/wf-#{cookbook_name}-#{node['hostname']}-#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.tar"
      evidence_log = "#{cookbook_name}-#{node['hostname']}.log"
      # run validation script
      execute 'Verify Workflow installation' do
        user user
        group group
        command "#{new_resource.install_dir}/bin/versionInfo.sh -long >> #{workflow_log_dir}/#{evidence_log}"
        only_if { Dir.glob("#{evidence_tar}").empty? }
      end

      # tar logs
      ibm_cloud_utils_tar "Create_#{evidence_tar}" do
        source "#{workflow_log_dir}/#{evidence_log}"
        target_tar evidence_tar
        only_if { Dir.glob("#{evidence_tar}").empty? }
      end

      # clean up evidence log
      #["#{workflow_log_dir}/#{evidence_log}"].each do |dir|
      #  file dir do
      #    action :delete
      #  end
      #end

      ["/tmp/master_password_file.txt", "/tmp/credential.store"].each do |dir|
        file dir do
          action :delete
        end
      end
    end
  else
    user = define_user
    Chef::Log.fatal "Installation manager is not installed for user #{user}. Please use :install_im action to install IM."
    raise "Installation manager is not installed for user #{user}. Please use :install_im action to install IM."
  end
end

# Override Load Current Resource
def load_current_resource
  Chef.event_handler do
    on :run_failed do
      HandlerSensitiveFiles::Helper.new.remove_sensitive_files_on_run_failure
    end
  end
  im_install_dir = define_im_install_dir
  user = define_user

  # CHEF 12 @current_resource = Chef::Resource::WorkflowInstall.new(@new_resource.name)
  @current_resource = Chef::Resource.resource_for_node(:workflow_install, node).new(@new_resource.name)

  # a common step is to load the current_resource instance variables with what is established in the new_resource.
  # what is passed into new_resouce via our recipes, is not automatically passed to our current_resource.
  @current_resource.user(user)
  @current_resource.im_version(@new_resource.im_version)
  @current_resource.im_install_dir(im_install_dir)
  @current_resource.offering_id(@new_resource.offering_id)

  # get current state
  @current_resource.im_installed = im_installed?(im_install_dir, @new_resource.im_version, user)
  @current_resource.installed = ibm_installed?(im_install_dir, @new_resource.offering_id, '', user)
end

# create directory and assign to specified user:group,
# root:root will be used to do chown if no user:group specified
def create_dir(dir, user = 'root', group = 'root')
  subdirs = subdirs_to_create(dir, user)
  subdirs.each do |dir|
    directory dir do
      action :create
      recursive true
      owner user
      group group
    end
  end
end

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

# define im data directory
# if not specified, return default value based on im_install_mode
def define_im_data_dir
  user = define_user
  case new_resource.im_install_mode
  when 'admin'
    im_data_dir = if new_resource.im_data_dir.nil?
                    '/var/ibm/InstallationManager'
                  else
                    new_resource.im_data_dir
                  end
    im_data_dir
  when 'nonAdmin'
    im_data_dir = if new_resource.im_data_dir.nil?
                    '/home/' + user + '/var/ibm/InstallationManager'
                  else
                    new_resource.im_data_dir
                  end
    im_data_dir
  when 'group'
    im_data_dir = if new_resource.im_data_dir.nil?
                    '/home/' + user + '/var/ibm/InstallationManager_Group'
                  else
                    new_resource.im_data_dir
                  end
    im_data_dir
  end
end

# define im shared directory
# if not specified, return default value based on im_install_mode
def define_im_shared_dir
  user = define_user
  case new_resource.im_install_mode
  when 'admin'
    im_shared_dir = if new_resource.im_shared_dir.nil?
                      '/opt/IBM/IMShared'
                    else
                      new_resource.im_shared_dir
                    end
    im_shared_dir
  when 'nonAdmin', 'group'
    im_shared_dir = if new_resource.im_shared_dir.nil?
                      '/home/' + user + '/opt/IBM/IMShared'
                    else
                      new_resource.im_shared_dir
                    end
    im_shared_dir
  end
end

# define ibm log directory
# if not specified, return default value based on im_install_mode
def define_ibm_log_dir
  user = define_user
  case new_resource.im_install_mode
  when 'admin'
    ibm_log_dir = if new_resource.ibm_log_dir.nil?
                      '/var/log/ibm_cloud'
                    else
                      new_resource.ibm_log_dir
                    end
    ibm_log_dir
  when 'nonAdmin', 'group'
    ibm_log_dir = if new_resource.ibm_log_dir.nil?
                      '/home/' + user + '/var/log/ibm_cloud'
                    else
                      new_resource.ibm_log_dir
                    end
    ibm_log_dir
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
