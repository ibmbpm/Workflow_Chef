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

actions :check_attrs, :prepare, :create, :restore_isc, :config_ihs, :start_dmgr, :create_case_group, :case_tune, :start_nodeagent, :enable_metering, :start_server, :setup_case, :restore_case_tune, :stop_nodeagent, :stop_server, :ps_online_setup
default_action :prepare

# <> The repository to search.
property :sw_repo, String

# <> The installation root directory for the Business Automation Workflow.
property :install_dir, String, required: true

# <> The type of product configuration: Express, Standard, Advanced, or AdvancedOnly.
property :product_type, String, required: true

# <> The type of deployment environment: PC or PS. Use 'PC' to create a Workflow Center deployment environment and 'PS' to create a Workflow Server deployment environment.
property :deployment_type, String

# <> The type of cluster: SingleCluster, SingleClusters or ThreeClusters(support later).
property :cluster_type, String, required: true

# <> The workflow runas user
property :workflow_runas_user, String, required: true

# <> The workflow runas group
property :workflow_runas_group, String, required: true

# <> The user name of the DE administrator.
property :deadmin_alias_user, String, required: true

# <> The password of the DE administrator.
property :deadmin_alias_password, String, required: true

# <> The user name of the cell administrator.
property :celladmin_alias_user, String, required: true

# <> The password of the cell administrator.
property :celladmin_alias_password, String, required: true

# <> The fully qualified domain name of the deployment manager to federate this node to.
property :dmgr_hostname, String, required: true

# <> The fully qualified domain names of all node, format like "node01_hostname, node02_hostname, node03_hostname"
property :node_hostnames, String

# <> The ip and fully qualified domain names mappings for all VMs under same environment
property :ip_hostname_pairs, Hash

# <> The fully qualified host name of IHS.
property :ihs_hostname, String

# <> The https port number of the IHS.
property :ihs_https_port, String

# <> The case management network shared directory for multiple nodes
property :case_network_shared_dir, String

# <> The local mount point for case management network shared directory
property :local_case_network_shared_dir, String

# <> The database type, 'DB2' or 'Oracle'
property :database_type, String, required: true

# <> Whether to install DB2 locally
property :db2_install, String

# TODO: renaming following properties to enable other databases support
# <> The fully qualified domain name of DB2 database.
property :db2_hostname, String

# <> The port number of the DB2 database.
property :db2_port, String

# <> The username of the DB2 database which will be used to create database user authentication alias.
property :db_alias_user, String

# <> The password of the DB2 database which will be used to create database user authentication alias.
property :db_alias_password, String

# <> The database name of Business Automation Workflow ProcessServerDb.
property :db2_bpmdb_name, String

# <> The database name of Business Automation Workflow PerformanceDb.
property :db2_pdwdb_name, String

# <> The database name of Business Automation Workflow CommonDB.
property :db2_cmndb_name, String

# <> The database name of Business Automation Workflow IcnDb/DosDb/TosDb.
property :db2_cpedb_name, String

# <> The schema name of the IcnDb database.
property :cpedb_icndb_schema, String

# <> The table space name of the IcnDb database.
property :cpedb_icndb_tsicn, String

# <> The schema name of the DosDb database.
property :cpedb_dosdb_schema, String

# <> The data table space name of the DosDb database.
property :cpedb_dosdb_tsdosdata, String

# <> The lob table space name of the DosDb database.
property :cpedb_dosdb_tsdoslob, String

# <> The idx table space name of the DosDb database.
property :cpedb_dosdb_tsdosidx, String

# <> The schema name of the TosDb database.
property :cpedb_tosdb_schema, String

# <> The data table space name of the TosDb database.
property :cpedb_tosdb_tstosdata, String

# <> The lob table space name of the TosDb database.
property :cpedb_tosdb_tstoslob, String

# <> The idx table space name of the TosDb database.
property :cpedb_tosdb_tstosidx, String

# <> The database data directory path.
property :db2_data_dir, String

# <> The database name of Business Automation Workflow ShardDB.
property :db2_shareddb_name, String

# <> The database name of Business Automation Workflow CellOnlyDB.
property :db2_cellonlydb_name, String

# <> The database schema of Business Automation Workflow.
property :db2_schema, String

# <> Oracle attributes
# <> The fully qualified domain name of Oracle database.
property :oracle_hostname, String

# <> The port number of the Oracle database.
property :oracle_port, String

# <> The name of the Oracle database.
property :oracle_database_name, String

# <> The Oracle JDBC driver path.
property :oracle_jdbc_driver_path, String

# <> The Oracle JDBC driver name.
property :oracle_jdbc_driver, String

# <> The user name of the Oracle common database which will be used to create database user authentication alias.
property :oracle_cmndb_username, String

# <> The password of the Oracle common database which will be used to create database user authentication alias.
property :oracle_cmndb_password, String

# <> The user name of the Oracle cellonly database which will be used to create database user authentication alias.
property :oracle_cellonlydb_username, String

# <> The password of the Oracle cellonly database which will be used to create database user authentication alias.
property :oracle_cellonlydb_password, String

# <> The user name of the Oracle Process Server database which will be used to create database user authentication alias.
property :oracle_psdb_username, String

# <> The password of the Oracle Process Server database which will be used to create database user authentication alias.
property :oracle_psdb_password, String

# <> The user name of the Oracle ICN database which will be used to create database user authentication alias.
property :oracle_icndb_username, String

# <> The password of the Oracle ICN database which will be used to create database user authentication alias.
property :oracle_icndb_password, String

# <> The table space name of Oracle ICN database
property :oracle_icndb_tsicn, String

# <> The user name of the Oracle design object store (DOS) database which will be used to create database user authentication alias.
property :oracle_dosdb_username, String

# <> The password of the Oracle design object store (DOS) database which will be used to create database user authentication alias.
property :oracle_dosdb_password, String

# <> The data table space name of Oracle design object store (DOS) database
property :oracle_dosdb_tsdosdata, String

# <> The user name of the Oracle target object store (TOS) database which will be used to create database user authentication alias.
property :oracle_tosdb_username, String

# <> The password of the Oracle target object store (TOS) database which will be used to create database user authentication alias.
property :oracle_tosdb_password, String

# <> The data table space name of Oracle target object store (TOS) database
property :oracle_tosdb_tstosdata, String

# <> The user name of the Oracle Performance database which will be used to create database user authentication alias.
property :oracle_pdwdb_username, String

# <> The password of the Oracle Performance database which will be used to create database user authentication alias.
property :oracle_pdwdb_password, String

# <> PS attributes
# <> The purpose of this Process Server environment: Development, Test, Staging, or Production, necessary for Process Server deployment environment.
property :ps_environment_purpose, String

# <> Options: true or false. Set to false if the Process Server is online and can be connected to the Process Center.
property :ps_offline, String

# <> Options: http or https. The transport protocol for communicating with the Process Center environment.
property :ps_pc_transport_protocol, String

# <> The host name of the Process Center environment.
property :ps_pc_hostname, String

# <> The port number of the Process Center environment.
property :ps_pc_port, String

# <> The context root prefix of the Process Center environment. If set, the context root prefix must start with a forward slash character (/).
property :ps_pc_contextroot_prefix, String

# <> The user name of the Process Center authentication alias (which is used by online Process Server environments to connect to Process Center).
property :ps_pc_alias_user, String

# <> The password of the Process Center authentication alias (which is used by online Process Server environments to connect to Process Center).
property :ps_pc_alias_password, String

# <> metering enablement (by leveraging WAS usage metering) attributes
# <> The group name which will shown under 'External Workloads' to express the setup uniquely
property :metering_identifier_name, String

# <> The apikey which is used to register the metering
property :metering_apikey, String

# <> The service URL which is used to register the metering
property :metering_url, String

attr_accessor :database_created
attr_accessor :de_created
attr_accessor :de_started
