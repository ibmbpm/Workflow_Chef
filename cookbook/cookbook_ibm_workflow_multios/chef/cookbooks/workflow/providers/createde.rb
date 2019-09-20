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
# Provider:: workflow_createde
#

include WF::Helper
use_inline_resources

#Validate inputs
action :check_attrs do
  product_type = new_resource.product_type
  deployment_type = new_resource.deployment_type
  cluster_type = new_resource.cluster_type

  if cluster_type != 'SingleCluster' && cluster_type != 'SingleClusters'
    Chef::Log.fatal "Please make sure you have the right value('SingleCluster', 'SingleClusters' or 'ThreeClusters') for attribute ['workflow']['config']['cluster_type'], the input one is #{cluster_type}"
    raise "Please make sure you have the right value('SingleCluster', 'SingleClusters' or 'ThreeClusters') for attribute ['workflow']['config']['cluster_type'], the input one is #{cluster_type}"
  end

  if !(['Advanced', 'AdvancedOnly'].include? product_type)
    Chef::Log.fatal "Please make sure you have the right value for attribute ['workflow']['config']['product_type'], the input one is #{product_type}"
    raise "Please make sure you have the right value for attribute ['workflow']['config']['product_type'], the input one is #{product_type}"
  end

  if product_type != 'AdvancedOnly' && deployment_type != 'PC' && deployment_type != 'PS'
    Chef::Log.fatal "Please make sure you have the right value('PC' or 'PS') for attribute ['workflow']['config']['deployment_type'], the input one is #{deployment_type}"
    raise "Please make sure you have the right value('PC' or 'PS') for attribute ['workflow']['config']['deployment_type'], the input one is #{deployment_type}"
  end
end

#Create Action prepare
action :prepare do
  if new_resource.database_type == 'DB2' && new_resource.db2_install == 'true'
    if @current_resource.database_created
      Chef::Log.info "#{@new_resource} already exists - nothing to do."
    else
      converge_by("Prepare - createDatabase #{@new_resource}") do
        # TODO: no handling for case that only one or two of the databases are created.

        # create database - BPMDB/PDWDB/COMMONDB
        createdb_template = 'config/db2/createDatabase.sql.erb'
        if new_resource.product_type == 'AdvancedOnly'
          createdb_template = 'config/db2/createDatabase_AdvancedOnly.sql.erb'
        end
        Chef::Log.info("createdb_template: #{createdb_template}")

        # make sure db2 is started
        # TODO: seems db2 will be started always, if yes, remove this.
        execute "start_db2" do
          command "su - #{new_resource.db_alias_user} -c \"db2start\""
          ignore_failure true
        end

        silent_create_database_sql_abspath = "#{new_resource.install_dir}/bin/createDatabase.sql"
        Chef::Log.info("silent_create_database_sql_abspath: #{silent_create_database_sql_abspath}")

        template silent_create_database_sql_abspath do
          source createdb_template
          variables(
            :BPMDB_NAME => new_resource.db2_bpmdb_name,
            :PDWDB_NAME => new_resource.db2_pdwdb_name,
            :CMNDB_NAME => new_resource.db2_cmndb_name,
            :DB2_USER => new_resource.db2_schema
          )
        end

        # create database before creating environment
        execute "execute createDatabase" do
          command "su - #{new_resource.db_alias_user} -c \"db2 -tvf #{silent_create_database_sql_abspath}\""
          not_if { processdb_created? }
        end

        # Prepare for CPE if product type is not 'AdvancedOnly'
        if new_resource.product_type != 'AdvancedOnly'
          # generate createDatabase_ECM sql
          cpe_createdb_template = 'config/db2/createDatabase_ECM.sql.erb'
          cpe_silent_create_database_sql_abspath = "#{new_resource.install_dir}/bin/createDatabase_ECM.sql"
          Chef::Log.info("cpe_createdb_template: #{cpe_createdb_template}, cpe_silent_create_database_sql_abspath: #{cpe_silent_create_database_sql_abspath}")

          template cpe_silent_create_database_sql_abspath do
            source cpe_createdb_template
            variables(
              :DB2_DATA_DIR => new_resource.db2_data_dir,
              :CPEDB_NAME => new_resource.db2_cpedb_name,
              :DB2_USER => new_resource.db_alias_user
            )
          end

          # generate createTablespace_Advanced sql
          cpe_create_tablespace_template = 'config/db2/createTablespace_Advanced.sql.erb'
          cpe_silent_create_tablespace_sql_abspath = "#{new_resource.install_dir}/bin/createTablespace_Advanced.sql"
          Chef::Log.info("cpe_create_tablespace_template: #{cpe_create_tablespace_template}, cpe_silent_create_tablespace_sql_abspath: #{cpe_silent_create_tablespace_sql_abspath}")

          template cpe_silent_create_tablespace_sql_abspath do
            source cpe_create_tablespace_template
            variables(
              :DB2_DATA_DIR => new_resource.db2_data_dir,
              :CPEDB_NAME => new_resource.db2_cpedb_name,
              :CPEDB_ICNDB_SCHEMA => new_resource.cpedb_icndb_schema,
              :CPEDB_ICNDB_TSICN => new_resource.cpedb_icndb_tsicn,
              :CPEDB_DOSDB_SCHEMA => new_resource.cpedb_dosdb_schema,
              :CPEDB_DOSDB_TSDOSDATA => new_resource.cpedb_dosdb_tsdosdata,
              :CPEDB_DOSDB_TSDOSDLOB => new_resource.cpedb_dosdb_tsdoslob,
              :CPEDB_DOSDB_TSDOSIDX => new_resource.cpedb_dosdb_tsdosidx,
              :CPEDB_TOSDB_SCHEMA => new_resource.cpedb_tosdb_schema,
              :CPEDB_TOSDB_TSTOSDATA => new_resource.cpedb_tosdb_tstosdata,
              :CPEDB_TOSDB_TSTOSLOB => new_resource.cpedb_tosdb_tstoslob,
              :CPEDB_TOSDB_TSTOSIDX => new_resource.cpedb_tosdb_tstosidx,
              :DB2_USER => new_resource.db_alias_user
            )
          end

          # generate createDatabase_ECM sh
          cpedb_sh_template = 'config/db2/createDatabase_ECM.sh.erb'
          cpedb_silent_sh_abspath = "#{new_resource.install_dir}/bin/createDatabase_ECM.sh"
          Chef::Log.info("cpedb_sh_template: #{cpedb_sh_template}, cpedb_silent_sh_abspath: #{cpedb_silent_sh_abspath}")

          template cpedb_silent_sh_abspath do
            source cpedb_sh_template
            variables(
              :DB2_DATA_DIR => new_resource.db2_data_dir,
              :CPEDB_NAME => new_resource.db2_cpedb_name,
              :CREATE_DB_ECM_SQL => cpe_silent_create_database_sql_abspath,
              :CPEDB_DOSDB_SCHEMA => new_resource.cpedb_dosdb_schema,
              :CPEDB_TOSDB_SCHEMA => new_resource.cpedb_tosdb_schema,
              :CREATE_TSPACE_ECM_SQL => cpe_silent_create_tablespace_sql_abspath
            )
            mode '0755'
          end

          # create case DB folders & create CPE database/tablespace/schema
          execute "execute createCPEDB" do
            command "su - #{new_resource.db_alias_user} -c \"#{cpedb_silent_sh_abspath}\""
            not_if { cpedb_created? }
          end
        end

        # TODO: evidence
      end
    end
  elsif new_resource.database_type == 'Oracle'
    workflow_user = new_resource.workflow_runas_user
    workflow_group = new_resource.workflow_runas_group

    oracle_jdbc_driver_path = new_resource.oracle_jdbc_driver_path
    # manage base directory - oracle jdbc driver path
    subdirs = subdirs_to_create(oracle_jdbc_driver_path, workflow_user)
    Chef::Log.info "oracle_jdbc_driver_path, subdirs: #{subdirs}"
    subdirs.each do |dir|
      directory dir do
        action :create
        recursive true
        owner workflow_user
        group workflow_group
      end
    end

    # determine if https is used
    repo_nonsecureMode = 'false'
    secure_repo = 'false'
    # the secure_repo, in theory, is nothing with https/http, but by test, the basic authentication
    # is always enabled for the https request. 
    if new_resource.sw_repo.nil? || new_resource.sw_repo.empty?
      raise "Software repository is necessary for Oracle driver download."
    elsif
      new_resource.sw_repo.match(/^https:\/\//)
      repo_self_signed_cert = 'true'
      secure_repo = 'true'
    end
    Chef::Log.info("secure_repo: #{secure_repo}, repo_nonsecureMode: #{repo_nonsecureMode}")

    # copy the remote oracle jdbc driver to local oracle jdbc driver path
    ibm_cloud_utils_unpack "download - #{new_resource.oracle_jdbc_driver}" do
      source "#{new_resource.sw_repo}/drivers/#{new_resource.oracle_jdbc_driver}"
      target_dir "#{oracle_jdbc_driver_path}"
      mode '775'
      #checksum md5
      owner workflow_user
      group workflow_group
      secure_repo secure_repo
      vault_name node['workflow']['vault']['name']
      vault_item node['workflow']['vault']['encrypted_id']
      repo_self_signed_cert repo_self_signed_cert
      action [:download]
    end
  end

  if new_resource.cluster_type != 'SingleCluster'
    workflow_user = new_resource.workflow_runas_user
    workflow_group = new_resource.workflow_runas_group

    local_case_network_shared_dir = new_resource.local_case_network_shared_dir
    # manage base directory - local case network shared directory
    subdirs = subdirs_to_create(local_case_network_shared_dir, workflow_user)
    Chef::Log.info "local_case_network_shared_dir, subdirs: #{subdirs}"
    subdirs.each do |dir|
      directory dir do
        action :create
        recursive true
        owner workflow_user
        group workflow_group
      end
    end

    # for multiple nodes, if case_network_shared_dir is specified, need mount the networkshared directory to local path before create action.
    Chef::Log.info "case_network_shared_dir: #{new_resource.case_network_shared_dir}"
    if !new_resource.case_network_shared_dir.nil? && !new_resource.case_network_shared_dir.empty?
      # idempotence supported by the mount and enable, if the networks shard directory is changed, mount will fail, which is currently not supported.
      mount local_case_network_shared_dir do
        device "#{new_resource.case_network_shared_dir}"
        fstype 'nfs'
        options 'rw'
        action [:mount, :enable]
      end
    end

    # create rulesRepo folder under the specified network shared directory if it doesn't exist
    rules_repo_dir = local_case_network_shared_dir + '/rulesRepo'
    directory rules_repo_dir do
      action :create
      recursive true
      owner workflow_user
      group workflow_group
      not_if { ::Dir.exist?(rules_repo_dir) }
    end
  end

  ruby_block "hosts: modify /etc/hosts" do
    block do
      # remove '127.x.x.x  node-hostname' mapping if exists, or announce this as blocking issue to client in readme.
      file = Chef::Util::FileEdit.new("/etc/hosts")
      loopback_hostname_mapping = "127\..*\s#{node['hostname']}"
      Chef::Log.info "#{loopback_hostname_mapping}"
      # remove Loopback Address/hostname mappings
      file.search_file_delete_line(/^#{loopback_hostname_mapping}/)

      # if specified node hostname is not known by each other, need add mappings to /etc/hosts for multiple nodes case.
      new_resource.ip_hostname_pairs.each do |ip, hostname|
        Chef::Log.info "ip: #{ip}, hostname: #{hostname}"

        shorthostname = hostname[0, hostname.index('.')] if !hostname.nil? && hostname.index('.')

        insert_line_text = "#{ip}\t#{hostname}"
        insert_line_text = "#{ip}\t#{hostname} #{shorthostname}" if !shorthostname.nil?

        insert_line_re = /^#{ip}\s#{hostname}/
        insert_line_re = /^#{ip}\s#{hostname}\s#{shorthostname}/ if !shorthostname.nil?
        Chef::Log.info "insert_line_text: #{insert_line_text}"

        file.insert_line_if_no_match(insert_line_re, insert_line_text)
        file.write_file
      end
    end
    only_if { new_resource.cluster_type != 'SingleCluster' }
  end
end

#Create Action create
action :create do
  if @current_resource.de_created
    Chef::Log.info "#{@new_resource} already exists - nothing to do."
  else
    converge_by("create #{@new_resource}") do
      install_dir = new_resource.install_dir

      createde_property_file = define_createde_property_file
      silent_createde_propfile_abspath = "#{install_dir}/bin/#{createde_property_file}"
      Chef::Log.info("create - silent_createde_propfile_abspath: #{silent_createde_propfile_abspath}")

      # decrypt the encrypted passwods
      chef_vault = node['workflow']['vault']['name']
      database_type = new_resource.database_type
      # DB2 password
      db_alias_password = new_resource.db_alias_password
      # oracle passwords
      oracle_cmndb_password = new_resource.oracle_cmndb_password
      oracle_cellonlydb_password = new_resource.oracle_cellonlydb_password
      oracle_psdb_password = new_resource.oracle_psdb_password
      oracle_icndb_password = new_resource.oracle_icndb_password
      oracle_dosdb_password = new_resource.oracle_dosdb_password
      oracle_tosdb_password = new_resource.oracle_tosdb_password
      oracle_pdwdb_password = new_resource.oracle_pdwdb_password
      unless chef_vault.empty?
        encrypted_id = node['workflow']['vault']['encrypted_id']
        require 'chef-vault'

        if database_type.nil? || database_type.empty?
          raise "Parameter - 'database_type' is required, please set Database Type from the CAM console."
        elsif database_type.strip.eql?('DB2')
          db_alias_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['db_alias_password']
        elsif database_type.strip.eql?('Oracle')
          oracle_cmndb_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['oracle']['shareddb']['password']
          oracle_cellonlydb_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['oracle']['cellonlydb']['password']
          oracle_psdb_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['oracle']['psdb']['password']
          oracle_icndb_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['oracle']['icndb']['password']
          oracle_dosdb_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['oracle']['dosdb']['password']
          oracle_tosdb_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['oracle']['tosdb']['password']
          oracle_pdwdb_password = chef_vault_item(chef_vault, encrypted_id)['workflow']['config']['oracle']['pdwdb']['password']
        end

      end

      # TODO: using same template for SingleCluster and SingleClusters later
      if new_resource.cluster_type == 'SingleClusters'
        node_hostnames = new_resource.node_hostnames.split(",")

        nodes_config = ''
        index = 0
        valid_hnames = []
        node_hostnames.each do |node_hostname|
          Chef::Log.info("Config for #{node_hostname}...")
          # ignore if the node_hostname is not valid
          next if node_hostname.nil? || node_hostname.lstrip.empty?

          # remove the blanks before and after the node hostname
          node_hostname = node_hostname.lstrip.rstrip

          next if valid_hnames.include?(node_hostname)
          valid_hnames.push(node_hostname)

          index = index + 1
          # TODO: extract DB2 and SingleCluster from the hard-coded file name out
          silent_createde_nodex_propfile_abspath = "#{install_dir}/bin/SingleClusters-Node#{index}-#{database_type}.properties"
          template silent_createde_nodex_propfile_abspath do
            source "config/SingleClusters-Nodex-#{database_type}.properties.erb"
            variables(
              :NODE_INDEX => index,
              :BAW_INSTALL_PATH => install_dir,
              :NODE_HOST_NAME => node_hostname
            )
          end

          Chef::Log.info "node silent_createde_nodex_propfile_abspath: #{silent_createde_nodex_propfile_abspath}"
          ruby_block "read: node property file" do
            block do
              nodex_config = ::File.read(silent_createde_nodex_propfile_abspath)
              #nodex_config = ::File.read(silent_createde_nodex_propfile_abspath) if ::File.exist?(silent_createde_nodex_propfile_abspath)
              Chef::Log.info("Configuration for #{node_hostname}: #{nodex_config}")

              nodes_config = nodes_config + nodex_config + "\n\n\n" if !nodex_config.nil? && !nodex_config.lstrip.empty?
            end
            only_if { ::File.exist?(silent_createde_nodex_propfile_abspath) }
          end
        end

        # TODO: extract the validation to seperated validator later.
        if index == 0
          Chef::Log.fatal "No valid node hostname exists in #{new_resource.node_hostnames}. Please pass in correct node hostnames."
          raise "No valid node hostname exists in #{new_resource.node_hostnames}. Please pass in correct node hostnames."
        end

        ruby_block 'template: generate createde property file' do
          block do
            template silent_createde_propfile_abspath do
              source 'config/' + createde_property_file + '.erb'
              variables(
                :DEADMIN_ALIAS_USER => new_resource.deadmin_alias_user,
                :DEADMIN_ALIAS_PWD => new_resource.deadmin_alias_password,
                :BPMDB_ALIAS_USER => new_resource.db_alias_user,
                :BPMDB_ALIAS_PWD => db_alias_password,
                :CELLADMIN_ALIAS_USER => new_resource.celladmin_alias_user,
                :CELLADMIN_ALIAS_PWD => new_resource.celladmin_alias_password,
                :DMGR_HOST_NAME => new_resource.dmgr_hostname,
                :BAW_INSTALL_PATH => install_dir,
                :NODES_CONFIG => nodes_config,
                :CASE_NETWORK_SHARED_DIR => new_resource.local_case_network_shared_dir,
                # DB2 settings
                :DB2_HOST_NAME => new_resource.db2_hostname,
                :DB2_PORT => new_resource.db2_port,
                :BAW_DB_SCHEMA => new_resource.db2_schema,
                :DB2_SHAREDDB_NAME => new_resource.db2_shareddb_name,
                :DB2_BPMDB_NAME => new_resource.db2_bpmdb_name,
                :DB2_PDWDB_NAME => new_resource.db2_pdwdb_name,
                :DB2_CPEDB_NAME => new_resource.db2_cpedb_name,
                :CPEDB_ICNDB_SCHEMA => new_resource.cpedb_icndb_schema,
                :CPEDB_ICNDB_TSICN => new_resource.cpedb_icndb_tsicn,
                :CPEDB_DOSDB_SCHEMA => new_resource.cpedb_dosdb_schema,
                :CPEDB_DOSDB_TSDOSDATA => new_resource.cpedb_dosdb_tsdosdata,
                :CPEDB_DOSDB_TSDOSDLOB => new_resource.cpedb_dosdb_tsdoslob,
                :CPEDB_DOSDB_TSDOSIDX => new_resource.cpedb_dosdb_tsdosidx,
                :CPEDB_TOSDB_SCHEMA => new_resource.cpedb_tosdb_schema,
                :CPEDB_TOSDB_TSTOSDATA => new_resource.cpedb_tosdb_tstosdata,
                :CPEDB_TOSDB_TSTOSLOB => new_resource.cpedb_tosdb_tstoslob,
                :CPEDB_TOSDB_TSTOSIDX => new_resource.cpedb_tosdb_tstosidx,
                :DB2_DATA_DIR => new_resource.db2_data_dir,
                :DB2_CELLONLY_NAME => new_resource.db2_cellonlydb_name,
                # Oracle settings
                :ORACLE_HOST_NAME => new_resource.oracle_hostname,
                :ORACLE_PORT => new_resource.oracle_port,
                :ORACLE_DATABASE_NAME => new_resource.oracle_database_name,
                :ORACLE_CMNDB_ALIAS_USER => new_resource.oracle_cmndb_username,
                :ORACLE_CMNDB_ALIAS_PWD => oracle_cmndb_password,
                :ORACLE_PSDB_ALIAS_USER => new_resource.oracle_psdb_username,
                :ORACLE_PSDB_ALIAS_PWD => oracle_psdb_password,
                :ORACLE_ICNDB_ALIAS_USER => new_resource.oracle_icndb_username,
                :ORACLE_ICNDB_ALIAS_PWD => oracle_icndb_password,
                :ORACLE_ICNDB_TSICN => new_resource.oracle_icndb_tsicn,
                :ORACLE_DOSDB_ALIAS_USER => new_resource.oracle_dosdb_username,
                :ORACLE_DOSDB_ALIAS_PWD => oracle_dosdb_password,
                :ORACLE_DOSDB_TSDOSDATA => new_resource.oracle_dosdb_tsdosdata,
                :ORACLE_TOSDB_ALIAS_USER => new_resource.oracle_tosdb_username,
                :ORACLE_TOSDB_ALIAS_PWD => oracle_tosdb_password,
                :ORACLE_TOSDB_TSTOSDATA => new_resource.oracle_tosdb_tstosdata,
                :ORACLE_PDWDB_ALIAS_USER => new_resource.oracle_pdwdb_username,
                :ORACLE_PDWDB_ALIAS_PWD => oracle_pdwdb_password,
                :ORACLE_CELLDB_ALIAS_USER => new_resource.oracle_cellonlydb_username,
                :ORACLE_CELLDB_ALIAS_PWD => oracle_cellonlydb_password,
                # PS only variables
                :PS_PURPOSE => new_resource.ps_environment_purpose,
                :PS_OFFLINE => new_resource.ps_offline,
                :PS_PC_TRANSPORT_PROTOCOL => new_resource.ps_pc_transport_protocol,
                :PS_PC_HOSTNAME => new_resource.ps_pc_hostname,
                :PS_PC_PORT => new_resource.ps_pc_port,
                :PS_PC_CONTEXTROOT_PREFIX => new_resource.ps_pc_contextroot_prefix,
                :PC_ALIAS_USER => new_resource.ps_pc_alias_user,
                :PC_ALIAS_PWD => new_resource.ps_pc_alias_password
              )
            end
          end
          only_if { !nodes_config.nil? && !nodes_config.empty? }
        end
      elsif new_resource.cluster_type == 'SingleCluster'
        # generate singlecluster createde property file
        ruby_block 'template: generate createde property file' do
          block do
            template silent_createde_propfile_abspath do
              source 'config/' + createde_property_file + '.erb'
              variables(
                :DEADMIN_ALIAS_USER => new_resource.deadmin_alias_user,
                :DEADMIN_ALIAS_PWD => new_resource.deadmin_alias_password,
                :BPMDB_ALIAS_USER => new_resource.db_alias_user,
                :BPMDB_ALIAS_PWD => db_alias_password,
                :CELLADMIN_ALIAS_USER => new_resource.celladmin_alias_user,
                :CELLADMIN_ALIAS_PWD => new_resource.celladmin_alias_password,
                :DMGR_HOST_NAME => new_resource.dmgr_hostname,
                :BAW_INSTALL_PATH => install_dir,
                :NODE_HOST_NAME => new_resource.node_hostnames,
                # DB2 settings
                :DB2_HOST_NAME => new_resource.db2_hostname,
                :DB2_PORT => new_resource.db2_port,
                :BAW_DB_SCHEMA => new_resource.db2_schema,
                :DB2_SHAREDDB_NAME => new_resource.db2_shareddb_name,
                :DB2_BPMDB_NAME => new_resource.db2_bpmdb_name,
                :DB2_PDWDB_NAME => new_resource.db2_pdwdb_name,
                :DB2_CPEDB_NAME => new_resource.db2_cpedb_name,
                :CPEDB_ICNDB_SCHEMA => new_resource.cpedb_icndb_schema,
                :CPEDB_ICNDB_TSICN => new_resource.cpedb_icndb_tsicn,
                :CPEDB_DOSDB_SCHEMA => new_resource.cpedb_dosdb_schema,
                :CPEDB_DOSDB_TSDOSDATA => new_resource.cpedb_dosdb_tsdosdata,
                :CPEDB_DOSDB_TSDOSDLOB => new_resource.cpedb_dosdb_tsdoslob,
                :CPEDB_DOSDB_TSDOSIDX => new_resource.cpedb_dosdb_tsdosidx,
                :CPEDB_TOSDB_SCHEMA => new_resource.cpedb_tosdb_schema,
                :CPEDB_TOSDB_TSTOSDATA => new_resource.cpedb_tosdb_tstosdata,
                :CPEDB_TOSDB_TSTOSLOB => new_resource.cpedb_tosdb_tstoslob,
                :CPEDB_TOSDB_TSTOSIDX => new_resource.cpedb_tosdb_tstosidx,
                :DB2_DATA_DIR => new_resource.db2_data_dir,
                :DB2_CELLONLY_NAME => new_resource.db2_cellonlydb_name,
                # Oracle settings
                :ORACLE_HOST_NAME => new_resource.oracle_hostname,
                :ORACLE_PORT => new_resource.oracle_port,
                :ORACLE_DATABASE_NAME => new_resource.oracle_database_name,
                :ORACLE_CMNDB_ALIAS_USER => new_resource.oracle_cmndb_username,
                :ORACLE_CMNDB_ALIAS_PWD => oracle_cmndb_password,
                :ORACLE_PSDB_ALIAS_USER => new_resource.oracle_psdb_username,
                :ORACLE_PSDB_ALIAS_PWD => oracle_psdb_password,
                :ORACLE_ICNDB_ALIAS_USER => new_resource.oracle_icndb_username,
                :ORACLE_ICNDB_ALIAS_PWD => oracle_icndb_password,
                :ORACLE_ICNDB_TSICN => new_resource.oracle_icndb_tsicn,
                :ORACLE_DOSDB_ALIAS_USER => new_resource.oracle_dosdb_username,
                :ORACLE_DOSDB_ALIAS_PWD => oracle_dosdb_password,
                :ORACLE_DOSDB_TSDOSDATA => new_resource.oracle_dosdb_tsdosdata,
                :ORACLE_TOSDB_ALIAS_USER => new_resource.oracle_tosdb_username,
                :ORACLE_TOSDB_ALIAS_PWD => oracle_tosdb_password,
                :ORACLE_TOSDB_TSTOSDATA => new_resource.oracle_tosdb_tstosdata,
                :ORACLE_PDWDB_ALIAS_USER => new_resource.oracle_pdwdb_username,
                :ORACLE_PDWDB_ALIAS_PWD => oracle_pdwdb_password,
                :ORACLE_CELLDB_ALIAS_USER => new_resource.oracle_cellonlydb_username,
                :ORACLE_CELLDB_ALIAS_PWD => oracle_cellonlydb_password,
                # PS only variables
                :PS_PURPOSE => new_resource.ps_environment_purpose,
                :PS_OFFLINE => new_resource.ps_offline,
                :PS_PC_TRANSPORT_PROTOCOL => new_resource.ps_pc_transport_protocol,
                :PS_PC_HOSTNAME => new_resource.ps_pc_hostname,
                :PS_PC_PORT => new_resource.ps_pc_port,
                :PS_PC_CONTEXTROOT_PREFIX => new_resource.ps_pc_contextroot_prefix,
                :PC_ALIAS_USER => new_resource.ps_pc_alias_user,
                :PC_ALIAS_PWD => new_resource.ps_pc_alias_password
              )
            end
          end
        end
      end

      workflow_user = new_resource.workflow_runas_user
      workflow_group = new_resource.workflow_runas_group

      # Run config command to create topology
      cmd = "./BPMConfig.sh -create -de #{silent_createde_propfile_abspath}"
      # Chef 12+ problem with OS detection. Replacing C.UTF-8 with en_US"
      cmd = "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./BPMConfig.sh -create -de #{silent_createde_propfile_abspath}"
      execute "create_de_#{new_resource.product_type}_#{new_resource.deployment_type}" do

        cwd "#{install_dir}/bin"
        command cmd
        user workflow_user
        group workflow_group
        timeout 7200
        not_if { createde_success? }
      end

      # remove the creade properites file for that some passwords are contained in the file.
      file silent_createde_propfile_abspath do
        action :delete
      end

      # set soap timeout to 300 seconds for config actions to come
      execute 'Bump SOAP timeout' do
        cwd "#{install_dir}/profiles/DmgrProfile/properties"
        command "sed -i.bak 's/com.ibm.SOAP.requestTimeout=180/com.ibm.SOAP.requestTimeout=300/' soap.client.props"
        user workflow_user
        group workflow_group
        only_if { ::Dir.exist?("#{install_dir}/profiles/DmgrProfile/properties") }
      end

      # TODO: evidence
    end
  end
end

# Configuration for IHS
# @multi-nodes-only
# @dmgr_only
action :config_ihs do
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/config_ihs_done")

  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  return if new_resource.cluster_type == 'SingleCluster'

  ihs_hostname = new_resource.ihs_hostname
  ihs_https_port = new_resource.ihs_https_port
  return if ihs_hostname.nil? || ihs_hostname.empty?

  # 1. create virtualhost
  create_ihs_virtualhost_filename = "#{new_resource.install_dir}/bin/create_ihs_virtualhost.jy"

  template create_ihs_virtualhost_filename do
    source 'wsadmin/create_ihs_virtualhost.jy.erb'
    variables(
      :ihs_hostname => ihs_hostname,
      :ihs_https_port => ihs_https_port
    )
  end

  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  # run config command to create ihs virtualhost
  ruby_block 'wsadmin: create ihs virtualhost' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}", nil, nil, nil, nil, create_ihs_virtualhost_filename)
      Chef::Log.info('wsadmin - create_ihs_virtualhost: ' + wsadmin_out)
    end
  end

  # 2. modify default_host to enable ihs https port
  add_default_host_filename = "#{new_resource.install_dir}/bin/add_virtual_host.jy"

  cell_name = 'PSCell1' # fixed cell name for PS and AdvancedOnly
  cell_name = 'PCCell1' if new_resource.product_type != 'AdvancedOnly' && new_resource.deployment_type == 'PC'

  template add_default_host_filename do
    source 'wsadmin/add_virtual_host.jy.erb'
    variables(
      :ihs_hostname => ihs_hostname,
      :cell_name => cell_name,
      :ihs_https_port => ihs_https_port
    )
  end

  # run config command to add host to default_host
  ruby_block 'wsadmin: add default_host' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}", nil, nil, nil, nil, add_default_host_filename)
      Chef::Log.info('wsadmin - add_virtual_host: ' + wsadmin_out)
    end
  end

  directory "#{new_resource.install_dir}/chef-state" do
    owner workflow_user
    group workflow_group
    action :create
  end

  # remember for later runs
  file "#{new_resource.install_dir}/chef-state/config_ihs_done" do
    owner workflow_user
    group workflow_group
    content ''
    action :create
  end
end

# Restore isc to avoid missing BPM content in admin console, known Ubuntu issue
# The whole environment need be restarted after the action.
# @dmgr_only
action :restore_isc do
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/restore_isc_done")

  # known ubuntu limitation
  #return unless (node['platform_family'] == "debian")

  # only need run one-time for multiple nodes environment on dmgr node
  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  converge_by("createde_restore_isc #{@new_resource}") do
    workflow_user = new_resource.workflow_runas_user
    workflow_group = new_resource.workflow_runas_group

    #  Not needed at the moment, but maybe in the future
    # =begin
    #     # stop environment before isc-deploy
    #     serverName = compute_server_name(new_resource.node_hostnames, node['hostname'])
    #     nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])
    #     ruby_block "stop: stop environment after applying ifixes" do
    #       block do
    #         stop_env(workflow_user, nodeIndex, serverName, workflow_group, new_resource.install_dir, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password)
    #       end
    #       only_if { need_install }
    #     end
    # =end

    # run config command to create topology
    # TODO: the 'ulimit -n 65536' should take effect in prepare step.
    isc_restore_cmd = "ulimit -n 65536; ./iscdeploy.sh -restore"
    # Chef 12+ problem with OS detection. Replacing C.UTF-8 with en_US"
    isc_restore_cmd = "export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; ulimit -n 65536; ./iscdeploy.sh -restore"
    execute "isc_restore: restore isc for the issue - missing BPM content in admin console" do
      cwd "#{new_resource.install_dir}/profiles/DmgrProfile/bin"
      command isc_restore_cmd
      user workflow_user
      group workflow_group
      not_if { ::File.exist?("#{new_resource.install_dir}/chef-state/restore_isc_done") }
    end

    directory "#{new_resource.install_dir}/chef-state" do
      owner workflow_user
      group workflow_group
      action :create
    end

    # remember for later runs
    file "#{new_resource.install_dir}/chef-state/restore_isc_done" do
      owner workflow_user
      group workflow_group
      content ''
      action :create
    end
  end
end

# Start the Dmgr
# @dmgr_only
action :start_dmgr do
  # attention: do not use state to determine if starting dmgr or not
  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  start_dmgr(workflow_user, workflow_group, new_resource.install_dir)
end

# Tune environment for setup_case, which should be executed after start_dmgr
# @multi-nodes-only
# @dmgr_only
# @std_only
action :case_tune do
  # tune only once
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/case_tune_done")

  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  return if new_resource.product_type == 'AdvancedOnly'

  return if new_resource.cluster_type == 'SingleCluster'

  # create the jython script, hard-coded the tunning values, TODO: extract the values out later if needed
  jython_tun_case = '/tmp/setup_case_tune.jy'
  template jython_tun_case do
    source 'wsadmin/setup_case_tune.jy.erb'
    variables(
    )
  end

  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  ruby_block 'wsadmin: tune transactio/orb/connectionpool timeout' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", jython_tun_case)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
  end

  file jython_tun_case do
    action :delete
  end

  directory "#{new_resource.install_dir}/chef-state" do
    owner workflow_user
    group workflow_group
    action :create
  end

  # remember for later runs
  file "#{new_resource.install_dir}/chef-state/case_tune_done" do
    owner workflow_user
    group workflow_group
    content ''
    action :create
  end
end

# Restore tune for setup_case, once done, restart the environment
# @multi-nodes-only
# @dmgr_only
# @std_only
action :restore_case_tune do
  # tune only once
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/restore_case_tune_done")

  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  return if new_resource.product_type == 'AdvancedOnly'

  return if new_resource.cluster_type == 'SingleCluster'

  # create the jython script, hard-coded the default settings values, TODO: extract the default values out later if needed
  jython_restore_tune_case = '/tmp/restore_case_tune.jy'
  template jython_restore_tune_case do
    source 'wsadmin/restore_case_tune.jy.erb'
    variables(
    )
  end

  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  ruby_block 'wsadmin: restore default transactio/orb/connectionpool timeout' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", jython_restore_tune_case)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
  end

  file jython_tun_case do
    action :delete
  end

  directory "#{new_resource.install_dir}/chef-state" do
    owner workflow_user
    group workflow_group
    action :create
  end

  # remember for later runs
  file "#{new_resource.install_dir}/chef-state/restore_case_tune_done" do
    owner workflow_user
    group workflow_group
    content ''
    action :create
  end
end

# @dmgr_only
# Start the node agent
action :start_nodeagent do
  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group
  dmgr_hostname = get_dmgr_hostname(new_resource.node_hostnames)

  nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])
  sync_node(workflow_user, nodeIndex, workflow_group, new_resource.install_dir, dmgr_hostname, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password)
  start_nodeagent(workflow_user, nodeIndex, workflow_group, new_resource.install_dir)
end

# Enable metering, register to the metering service
action :enable_metering do 
  # enable once
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/enable_metering_done")

  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  if new_resource.metering_url.nil? || new_resource.metering_url.empty?
    Chef::Log.warn "No metering service url set, ignore."
    return
  end

  if new_resource.metering_apikey.nil? || new_resource.metering_apikey.empty?
    Chef::Log.warn "No metering service apikey set, ignore."
    return
  end

  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  metering_uri = URI(new_resource.metering_url)
  metering_host = metering_uri.host
  metering_port = metering_uri.port

  cell_name = 'PSCell1' # fixed cell name for PS and AdvancedOnly
  cell_name = 'PCCell1' if new_resource.product_type != 'AdvancedOnly' && new_resource.deployment_type == 'PC'

  metering_group = "De1/SingleCluster"
  metering_group = "#{new_resource.metering_identifier_name}/De1/SingleCluster" if !new_resource.metering_identifier_name.nil? && !new_resource.metering_identifier_name.empty?

  default_metering_truststore_password = "umpwd"

  was_usage_metering_propfile = "#{new_resource.install_dir}/profiles/DmgrProfile/config/cells/#{cell_name}/clusters/SingleCluster/was-usage-metering.properties"
  template was_usage_metering_propfile do
    source 'was-usage-metering.properties.erb'
    variables(
      metering_url: new_resource.metering_url,
      metering_apikey: new_resource.metering_apikey,
      metering_keystore_password: default_metering_truststore_password,
      metering_group: metering_group
    )
  end

  # for WAS usage metering bug, remove it once WAS fix the issue
  directory "#{new_resource.install_dir}/profiles/DmgrProfile/config/cells/#{cell_name}/SingleCluster" do
    owner workflow_user
    group workflow_group
    action :create
  end
  was_usage_metering_propfile = "#{new_resource.install_dir}/profiles/DmgrProfile/config/cells/#{cell_name}/SingleCluster/was-usage-metering.properties"
  template was_usage_metering_propfile do
    source 'was-usage-metering.properties.erb'
    variables(
      metering_url: new_resource.metering_url,
      metering_apikey: new_resource.metering_apikey,
      metering_keystore_password: default_metering_truststore_password,
      metering_group: metering_group
    )
  end

  # create the prepare_metering_keystore jython script
  jython_prepare_metering_keystore = "#{new_resource.install_dir}/profiles/DmgrProfile/bin/prepare_metering_keystore.jy"
  metering_keystore_location = "#{new_resource.install_dir}/profiles/icp_metering_truststore.jks"
  template jython_prepare_metering_keystore do
    source 'wsadmin/prepare_metering_keystore.jy.erb'
    variables(
      metering_keystore_location: metering_keystore_location,
      metering_host: metering_host,
      metering_port: metering_port,
      cell_name: cell_name,
      metering_keystore_password: default_metering_truststore_password
    )
  end

  ruby_block 'wsadmin: prepare usage metering trustStore' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", jython_prepare_metering_keystore)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
  end

  ruby_block "copy: icp_metering_truststore.jks to <cluster> folder" do
    block do
      FileUtils.cp metering_keystore_location, "#{new_resource.install_dir}/profiles/DmgrProfile/config/cells/#{cell_name}/clusters/SingleCluster/"
      FileUtils.cp metering_keystore_location, "#{new_resource.install_dir}/profiles/DmgrProfile/config/cells/#{cell_name}/SingleCluster/"
    end
  end

  #file jython_prepare_metering_keystore do
  #  action :delete
  #end

  # create the sync_for_metering jython script
  jython_sync_for_metering = "#{new_resource.install_dir}/profiles/DmgrProfile/bin/sync_for_metering.jy"
  template jython_sync_for_metering do
    source 'wsadmin/sync_for_metering.jy.erb'
    variables(
    )
  end

  ruby_block 'wsadmin: sync for usage metering' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", jython_sync_for_metering)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
  end

  #file jython_sync_for_metering do
  #  action :delete
  #end

  directory "#{new_resource.install_dir}/chef-state" do
    owner workflow_user
    group workflow_group
    action :create
  end

  # remember for later runs
  file "#{new_resource.install_dir}/chef-state/enable_metering_done" do
    owner workflow_user
    group workflow_group
    content ''
    action :create
  end
end

# Start the server
action :start_server do
  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  serverName = compute_server_name(new_resource.node_hostnames, node['hostname'])
  nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])

  start_server(workflow_user, nodeIndex, serverName, workflow_group, new_resource.install_dir)
end

# Stop the node agent
action :stop_nodeagent do
  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group
  nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])

  stop_nodeagent(workflow_user, nodeIndex, workflow_group, new_resource.install_dir, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password)
end

# Stop the server
action :stop_server do
  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  serverName = compute_server_name(new_resource.node_hostnames, node['hostname'])
  nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])
  # stop server and nodeagent, will be started again later with createde start_nodeagent and start_server action
  stop_server(workflow_user, nodeIndex, serverName, workflow_group, new_resource.install_dir, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password)
end

# Create a group called peAdminGroup and put the DE admin into it
# @dmgr_only
# @std_only
action :create_case_group do
  # create group only once
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/create_case_group_done")

  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  return if new_resource.product_type == 'AdvancedOnly'

  # create the jython script
  jython_group = '/tmp/create_peadmin_group.jy'
  template jython_group do
    source 'wsadmin/create_peadmin_group.jy.erb'
    variables(
      pe_admin_group: 'peAdminGroup',
      bpm_admin_user: new_resource.deadmin_alias_user
    )
  end

  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  ruby_block 'wsadmin: create peadmin group and add bpmadmin' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", jython_group)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
  end

  file jython_group do
    action :delete
  end

  directory "#{new_resource.install_dir}/chef-state" do
    owner workflow_user
    group workflow_group
    action :create
  end

  # remember for later runs
  file "#{new_resource.install_dir}/chef-state/create_case_group_done" do
    owner workflow_user
    group workflow_group
    content ''
    action :create
  end
end

# setup case feature by creating a object store and run configmgr_cl
# @dmgr_only
# @std_only
action :setup_case do
  # setup only once
  return if ::File.exist?("#{new_resource.install_dir}/chef-state/setup_case_done")
  # no need to setup case for AdvancedOnly
  return if new_resource.product_type == 'AdvancedOnly'

  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  jython_tos = '/tmp/create_object_store.jy'

  template jython_tos do
    source 'wsadmin/create_object_store.jy.erb'
    variables(
      pe_admin_group: 'peAdminGroup',
      bpm_admin_user: new_resource.deadmin_alias_user,
      bpm_admin_password: new_resource.deadmin_alias_password,
      cluster_name: 'SingleCluster'
    )
    not_if { ::File.exist?("#{new_resource.install_dir}/chef-state/setup-case/create_object_store_done") }
  end

  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  # it is enough that create object store' is executed only one time on the node that is in same VM with the Dmgr
  node_hostname = new_resource.dmgr_hostname
  ruby_block 'wsadmin: create object store' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}/profiles/DmgrProfile", "#{node_hostname}", '8880', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", jython_tos)
      Chef::Log.info('wsadmin: ' + wsadmin_out)
    end
    not_if { ::File.exist?("#{new_resource.install_dir}/chef-state/setup-case/create_object_store_done") }
  end

  file jython_tos do
    action :delete
    not_if { ::File.exist?("#{new_resource.install_dir}/chef-state/setup-case/create_object_store_done") }
  end

  directory "#{new_resource.install_dir}/chef-state/setup-case" do
    owner workflow_user
    group workflow_group
    recursive true
    action :create
  end

  # remember for later runs, if customer meet 'timeout' issue for later setup case, they can re-run to setup case again.
  file "#{new_resource.install_dir}/chef-state/setup-case/create_object_store_done" do
    content ''
    owner workflow_user
    group workflow_group
    action :create
  end

  # determine the config file to use
  icm_config_folder_name =
    if new_resource.deployment_type == 'PS'
      'ICM_prod'
    else
      'ICM_dev'
    end
  icm_config_root = "#{new_resource.install_dir}/profiles/DmgrProfile/CaseManagement/De1/profiles/#{icm_config_folder_name}"

  # modify configibmbpm.xml(BPMServerHost/BPMServerPort) and registerbawplugin.xml(BPMWorkDashboardOrigin) file, replace corresponding values using IHS info
  # solution for RTC defect 306735
  ihs_hostname = new_resource.ihs_hostname
  ihs_https_port = new_resource.ihs_https_port

  ruby_block "case configmgr: modify configibmbpm.xml" do
    block do
      filename = "#{icm_config_root}/configibmbpm.xml"
      if ::File.exist?(filename)
        #chef_gem 'nokogiri'
        #require 'nokogiri'
        # TODO: chef_gem is not allowed for network issue.
        #       investigate if exist built-in xml parser, if yes, perfect following implementation
        require 'tempfile'
        p_dir = ::File.dirname(filename)
        temp_filename = ::File.basename(filename)
        temp_filename.prepend('.') # hide the temp file
        tempfile =
          begin
            Tempfile.new(temp_filename, p_dir)
          rescue
            Tempfile.new(temp_filename)
          end

        host_match = false
        port_match = false
        ::File.open(filename).each do |line|
          if line =~ /BPMServerHost/
            host_match = true
          elsif line =~ /BPMServerPort/
            port_match = true
          elsif host_match && line =~ /value/
            host_match = false
            line = line.gsub(/>.*</, ">#{ihs_hostname}<")
          elsif port_match && line =~ /value/
            port_match = false
            line = line.gsub(/>.*</, ">#{ihs_https_port}<")
          end

          tempfile.puts line
        end
        tempfile.fdatasync
        tempfile.close

        configibmbpm_file = ::File.stat(filename)
        FileUtils.chown configibmbpm_file.uid, configibmbpm_file.gid, tempfile.path
        FileUtils.chmod configibmbpm_file.mode, tempfile.path
        FileUtils.mv tempfile.path, filename
      end
    end
    only_if { new_resource.cluster_type != 'SingleCluster' && !ihs_hostname.nil? && !ihs_hostname.empty? }
    not_if { ::File.exist?("#{new_resource.install_dir}/chef-state/setup-case/modify_configibmbpm_done") }
  end

  # remember for later runs, if customer meet 'timeout' issue for later setup case, they can re-run to setup case again.
  file "#{new_resource.install_dir}/chef-state/setup-case/modify_configibmbpm_done" do
    content ''
    owner workflow_user
    group workflow_group
    action :create
  end

  ruby_block "case configmgr: modify registerbawplugin.xml" do
    block do
      filename = "#{icm_config_root}/registerbawplugin.xml"
      if ::File.exist?(filename)
        #chef_gem 'nokogiri'
        #require 'nokogiri'
        require 'tempfile'
        p_dir = ::File.dirname(filename)
        temp_filename = ::File.basename(filename)
        temp_filename.prepend('.') # hide the temp file
        tempfile =
          begin
            Tempfile.new(temp_filename, p_dir)
          rescue
            Tempfile.new(temp_filename)
          end

        match = false
        ::File.open(filename).each do |line|
          if line =~ /BPMWorkDashboardOrigin/
            match = true
          elsif match && line =~ /value/
            match = false
            line = line.gsub(/>.*</, ">https://#{ihs_hostname}:#{ihs_https_port}<")
          end

          tempfile.puts line
        end
        tempfile.fdatasync
        tempfile.close

        registerbawplugin_file = ::File.stat(filename)
        FileUtils.chown registerbawplugin_file.uid, registerbawplugin_file.gid, tempfile.path
        FileUtils.chmod registerbawplugin_file.mode, tempfile.path
        FileUtils.mv tempfile.path, filename
      end
    end
    only_if { new_resource.cluster_type != 'SingleCluster' && !ihs_hostname.nil? && !ihs_hostname.empty? }
    not_if { ::File.exist?("#{new_resource.install_dir}/chef-state/setup-case/modify_registerbawplugin_done") }
  end

  # remember for later runs, if customer meet 'timeout' issue for later setup case, they can re-run to setup case again.
  file "#{new_resource.install_dir}/chef-state/setup-case/modify_registerbawplugin_done" do
    content ''
    owner workflow_user
    group workflow_group
    action :create
  end

  # modify contentnavigatorserver.xml, replace corresponding values using IHS info
  # solution for RTC defect 313062
  ruby_block "case configmgr: modify contentnavigatorserver.xml" do
    block do
      filename = "#{icm_config_root}/contentnavigatorserver.xml"
      if ::File.exist?(filename)
        #chef_gem 'nokogiri'
        #require 'nokogiri'
        require 'tempfile'
        p_dir = ::File.dirname(filename)
        temp_filename = ::File.basename(filename)
        temp_filename.prepend('.') # hide the temp file
        tempfile =
          begin
            Tempfile.new(temp_filename, p_dir)
          rescue
            Tempfile.new(temp_filename)
          end

        match = false
        ::File.open(filename).each do |line|
          if line =~ /NexusWSIURL/
            match = true
          elsif match && line =~ /value/
            match = false
            line = line.gsub(/>.*</, ">https://#{ihs_hostname}:#{ihs_https_port}/navigator<")
          end

          tempfile.puts line
        end
        tempfile.fdatasync
        tempfile.close

        contentnavigatorserver_file = ::File.stat(filename)
        FileUtils.chown contentnavigatorserver_file.uid, contentnavigatorserver_file.gid, tempfile.path
        FileUtils.chmod contentnavigatorserver_file.mode, tempfile.path
        FileUtils.mv tempfile.path, filename
      end
    end
    only_if { new_resource.cluster_type != 'SingleCluster' && !ihs_hostname.nil? && !ihs_hostname.empty? }
    not_if { ::File.exist?("#{new_resource.install_dir}/chef-state/setup-case/modify_contentnavigatorserver_done") }
  end

  # remember for later runs, if customer meet 'timeout' issue for later setup case, they can re-run to setup case again.
  file "#{new_resource.install_dir}/chef-state/setup-case/modify_contentnavigatorserver_done" do
    content ''
    owner workflow_user
    group workflow_group
    action :create
  end

  # TODO: modify contentengineserver.xml, and also modify the CEServerWSIPort info in configibmbpm.xml
  # Runtime exception may be met after finishing above TODO, more details see 313062

  # determine the config file to use
  icm_config =
    if new_resource.deployment_type == 'PS'
      'ICM_prod/ICM_prod.cfgp'
    else
      'ICM_dev/ICM_dev.cfgp'
    end
  case_mgr_profile = "#{new_resource.install_dir}/profiles/DmgrProfile/CaseManagement/De1/profiles/#{icm_config}"

  execute "case configmgr: store passwords" do
    cwd "#{new_resource.install_dir}/CaseManagement/configure/"
    command %Q( export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; echo 'yes' | ./configmgr_cl storepasswords -force -silent -profile #{case_mgr_profile} -nl en)
    user workflow_user
    group workflow_group
    not_if { ::File.exist?("#{new_resource.install_dir}/chef-state/setup-case/store_passwords_done") }
  end

  # remember for later runs, if customer meet 'timeout' issue for later setup case, they can re-run to setup case again.
  file "#{new_resource.install_dir}/chef-state/setup-case/store_passwords_done" do
    content ''
    owner workflow_user
    group workflow_group
    action :create
  end

  # for CASE limitation, need leave only one node live for multiple nodes case
  # TODO: implement if more than 2 nodes defined in the customized template.
  serverName = compute_server_name(new_resource.node_hostnames, node['hostname'])
  nodeIndex = compute_node_index(new_resource.node_hostnames, node['hostname'])
  stop_server(workflow_user, nodeIndex, serverName, workflow_group, new_resource.install_dir, new_resource.celladmin_alias_user, new_resource.celladmin_alias_password) if new_resource.cluster_type != 'SingleCluster'

  execute "case configmgr: setup ICM" do
    cwd "#{new_resource.install_dir}/CaseManagement/configure/"
    command %Q( export LANG=en_US; export LANGUAGE=en_US; export LC_ALL=en_US; echo 'y' | ./configmgr_cl execute -force -silent -profile #{case_mgr_profile})
    user workflow_user
    group workflow_group
  end

  # for CASE need, need restart whole environment
  refresh_for_case_filename = "#{new_resource.install_dir}/bin/refresh_for_case.jy"

  template refresh_for_case_filename do
    source 'wsadmin/refresh_for_case.jy.erb'
    variables(
    )
  end

  ruby_block 'wsadmin: refresh DE for CASE' do
    block do
      wsadmin_out = WF::Helper.run_jython(workflow_user, "#{new_resource.install_dir}/profiles/DmgrProfile", "#{new_resource.dmgr_hostname}", '8879', "#{new_resource.deadmin_alias_user}", "#{new_resource.deadmin_alias_password}", refresh_for_case_filename)
      Chef::Log.info('wsadmin - create_ihs_virtualhost: ' + wsadmin_out)
    end
  end

  # remember for later runs
  file "#{new_resource.install_dir}/chef-state/setup_case_done" do
    content ''
    owner workflow_user
    group workflow_group
    action :create
  end
end

# import the PC signer cert to the online PS, update wsadmin cert to access dmgr
# @dmgr_only
action :ps_online_setup do
  # only for online PS
  return unless new_resource.deployment_type == 'PS'
  return unless new_resource.ps_offline == 'false'
  # only on Dmgr
  return unless ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile")

  workflow_user = new_resource.workflow_runas_user
  workflow_group = new_resource.workflow_runas_group

  execute 'Adjust ClientDefaultTrustStore on Dmgr' do
    cwd "#{new_resource.install_dir}/profiles/DmgrProfile/properties"
    command "sed -i.bak 's@^com.ibm.ssl.trustStore=\${user.root}/etc/trust.p12@com.ibm.ssl.trustStore=${user.root}/config/cells/PSCell1/trust.p12@' ssl.client.props"
    user workflow_user
    group workflow_group
    only_if { ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile/properties") }
  end

  execute 'Import signer certificate from remote PC Dmgr' do
    cwd "#{new_resource.install_dir}/profiles/DmgrProfile/bin"
    command "./retrieveSigners.sh CellDefaultTrustStore ClientDefaultTrustStore -host #{new_resource.ps_pc_hostname} -port 8879 -username #{new_resource.ps_pc_alias_user} -password #{new_resource.ps_pc_alias_password} -remoteAlias root -autoAcceptBootstrapSigner"
    user workflow_user
    group workflow_group
    only_if { ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile/bin") }
  end

  template '/tmp/exchange_signer_certs.py' do
    source 'wsadmin/exchange_signer_certs.py.erb'
    only_if { ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile/bin") }
  end

  execute 'Export signer certificate to remote PC Dmgr' do
    cwd "#{new_resource.install_dir}/profiles/DmgrProfile/bin"
    command "./wsadmin.sh -host #{new_resource.ps_pc_hostname} -port 8879 -lang jython -f /tmp/exchange_signer_certs.py -username #{new_resource.ps_pc_alias_user} -password #{new_resource.ps_pc_alias_password}"
    user workflow_user
    group workflow_group
    only_if { ::Dir.exist?("#{new_resource.install_dir}/profiles/DmgrProfile/bin") }
  end
end

# If the database is created
def database_created?
  # a remote database must be created before deploying BAW
  if new_resource.database_type != 'DB2' || new_resource.db2_install == 'false'
    true
  elsif new_resource.product_type == 'AdvancedOnly'
    processdb_created?
  else
    processdb_created? && cpedb_created?
  end
end

# If the process related database is created
def processdb_created?
  cmn_cmd_out = shell_out!("su - #{new_resource.db_alias_user} -c \"db2 list db directory | grep #{new_resource.db2_cmndb_name.upcase} || true\"")
  cmndb_created = cmn_cmd_out.stderr.empty? && (cmn_cmd_out.stdout =~ /#{new_resource.db2_cmndb_name.upcase}/)
  if new_resource.product_type == 'AdvancedOnly'
    cmndb_created
  else
    bpm_cmd_out = shell_out!("su - #{new_resource.db_alias_user} -c \"db2 list db directory | grep #{new_resource.db2_bpmdb_name.upcase} || true\"")
    bpmdb_created = bpm_cmd_out.stderr.empty? && (bpm_cmd_out.stdout =~ /#{new_resource.db2_bpmdb_name.upcase}/)
    pdw_cmd_out = shell_out!("su - #{new_resource.db_alias_user} -c \"db2 list db directory | grep #{new_resource.db2_pdwdb_name.upcase} || true\"")
    pdwdb_created = pdw_cmd_out.stderr.empty? && (pdw_cmd_out.stdout =~ /#{new_resource.db2_pdwdb_name.upcase}/)

    bpmdb_created && pdwdb_created && cmndb_created
  end
end

# If the cpe related database is created
def cpedb_created?
    cpedb_cmd_out = shell_out!("su - #{new_resource.db_alias_user} -c \"db2 list db directory | grep #{new_resource.db2_cpedb_name.upcase} || true\"")
    cpedb_created = cpedb_cmd_out.stderr.empty? && (cpedb_cmd_out.stdout =~ /#{new_resource.db2_cpedb_name.upcase}/)

    cpedb_created
end

# If createde action is executed successfully
def createde_success?
  createde_property_file = define_createde_property_file
  silent_createde_propfile_abspath = "#{new_resource.install_dir}/bin/#{createde_property_file}"
  str_createde_suc = "The 'BPMConfig.sh -create -de #{silent_createde_propfile_abspath}' command completed successfully."
  createde_cmd_out = shell_out!("grep \"#{str_createde_suc}\" #{new_resource.install_dir}/logs/config -r || true")
  createde_cmd_out.stderr.empty? && (createde_cmd_out.stdout =~ /#{str_createde_suc}/)
end

# Construct DE creation properties file name according to product_type, deployment_type and cluster_type.
def define_createde_property_file
  createde_property_file = ''

  product_type = new_resource.product_type
  deployment_type = new_resource.deployment_type
  cluster_type = new_resource.cluster_type
  database_type = new_resource.database_type
  Chef::Log.info("product_type:#{product_type}, deployment_type:#{deployment_type}, cluster_type:#{cluster_type}")

  case product_type
    when 'Advanced', 'Standard'
      createde_property_file = "#{product_type}-#{deployment_type}-#{cluster_type}-#{database_type}.properties"
    when 'AdvancedOnly'
      createde_property_file = "#{product_type}-#{cluster_type}-#{database_type}.properties"
    else
      # no way to go into this path, should be checked in previous step
  end
  Chef::Log.info("createde_property_file:#{createde_property_file}")

  createde_property_file
end

#Override Load Current Resource
def load_current_resource
  Chef.event_handler do
    on :run_failed do
      HandlerSensitiveFiles::Helper.new.remove_sensitive_files_on_run_failure
    end
  end

  @current_resource = Chef::Resource.resource_for_node(:workflow_createde, node).new(@new_resource.name)
  #@current_resource = Chef::Resource::WorkflowInstall.new(@new_resource.name)

  # take '!db2 || !db2_install' as database created
  @current_resource.database_created = database_created?

  @current_resource.de_created = createde_success?

=begin
  str_createde_suc = "The 'BPMConfig.sh -create -de #{silent_createde_propfile_abspath}' command completed successfully."
  createde_cmd_out = shell_out!("grep \"#{str_createde_suc}\" #{new_resource.install_dir}/logs/config -r || true")
  @current_resource.de_created = createde_cmd_out.stderr.empty? && (createde_cmd_out.stdout =~ /#{str_createde_suc}/)

  str_startde_suc = "The 'BPMConfig.sh -start #{silent_createde_propfile_abspath}' command completed successfully."
  startde_cmd_out = shell_out!("grep \"#{str_startde_suc}\" #{new_resource.install_dir}/logs/config -r || true")
  @current_resource.de_started = startde_cmd_out.stderr.empty? && (startde_cmd_out.stdout =~ /#{str_startde_suc}/)
=end

=begin
  im_install_dir = define_im_install_dir
  im_repo = define_im_repo
  user = define_user
  if new_resource.im_repo_user.nil?
    Chef::Log.info "im_repo_user not provided. Please make sure your IM repo is not secured.If your IM repo is secured you must provide im_repo_user and configure your chef vault for password"
  elsif im_installed?(im_install_dir, @new_resource.im_version, user)
    generate_storage_file
  end
  security_params = define_security_params

  @current_resource = Chef::Resource.resource_for_node(:workflow_install, node).new(@new_resource.name)
  #@current_resource = Chef::Resource::WorkflowInstall.new(@new_resource.name)
  #A common step is to load the current_resource instance variables with what is established in the new_resource.
  #What is passed into new_resouce via our recipes, is not automatically passed to our current_resource.
  @current_resource.user(user)
  @current_resource.im_version(@new_resource.im_version)
  @current_resource.im_install_dir(im_install_dir)
  @current_resource.offering_id(@new_resource.offering_id)
  @current_resource.offering_version(@new_resource.offering_version)

  #Get current state
  @current_resource.im_installed = im_installed?(im_install_dir, @new_resource.im_version, user)
  #@current_resource.fp_installed = im_fixpack_installed?(im_install_dir, im_repo, security_params, node['im']['fixpack_offering_id'] + '_' + @new_resource.im_version, user)
  @current_resource.installed = ibm_installed?(im_install_dir, @new_resource.offering_id, @new_resource.offering_version, user)
  remove_storage_file
=end
end
