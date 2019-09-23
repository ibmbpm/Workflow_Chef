IBM Business Automation Workflow Cookbook
============

Installs and configures IBM Business Automation Workflow.

Requirements
------------

### Platform:

* Ubuntu16 (>= 16.04)

### Cookbooks:

* ibm_cloud_utils
* linux


Attributes
----------

<table>
  <tr>
    <td>Attribute</td>
    <td>Description</td>
    <td>Default</td>
  </tr>
  <tr>
    <td><code>node['ibm']['sw_repo']</code></td>
    <td>The location to download the installation images from.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['ibm']['ifix_repo']</code></td>
    <td>The location to download the interim fixes from.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['ibm']['log_dir']</code></td>
    <td>The log directory for all log files that are generated during installation and configuration.</td>
    <td><code>/var/log/ibm_cloud</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['install_mode']</code></td>
    <td>The mode to install IBM Business Automation Workflow in.</td>
    <td><code>admin</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['os_users']['workflow']['name']</code></td>
    <td>The operating system user identifier that you use to install the product. This identifier is created if it does not exist.</td>
    <td><code>wfuser</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['os_users']['workflow']['gid']</code></td>
    <td>The name of the operating system group that will be allocated to the product installation.</td>
    <td><code>wfgrp</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['os_users']['workflow']['comment']</code></td>
    <td>A comment that you can add when you create the user identifier.</td>
    <td><code>Business Automation Workflow OS user</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['os_users']['workflow']['home']</code></td>
    <td>The home directory for the operating system user, to be used for product installation.</td>
    <td><code>/home/wfuser</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['os_users']['workflow']['shell']</code></td>
    <td>The default shell for the operating system user identifier.</td>
    <td><code>/bin/bash</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['version']</code></td>
    <td>The release and fix pack level of the IBM Business Automation Workflow package you are installing. For example, 18.0.0.1 for version 18.0.0.1.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['install_dir']</code></td>
    <td>The installation root directory for IBM Business Automation Workflow.</td>
    <td><code>/opt/IBM/Workflow</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['im_version']</code></td>
    <td>The Installation Manager version number that is included in Workflow installation images.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['ifix_names']</code></td>
    <td>The interim fix list in string format. For example "ifix1.zip, ifix2.zip, ifix3.zip"</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['features']</code></td>
    <td>The IBM Business Automation Workflow feature, for example 'WorkflowEnterprise.Production' or 'WorkflowEnterprise.NonProduction'.</td>
    <td><code>WorkflowEnterprise.Production</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['offering_id']</code></td>
    <td>The product identifier of the IBM Business Automation Workflow offering.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['offering_version']</code></td>
    <td>The IBM Business Automation Workflow offering version value.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['profile_id']</code></td>
    <td>The profile information that will be put into the response file and used to install IBM Business Automation Workflow.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['product_type']</code></td>
    <td>The product types: Express, Standard, Advanced, or AdvancedOnly.</td>
    <td><code>Advanced</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['deployment_type']</code></td>
    <td>The type of the deployment environment: PC or PS. Use 'PC' to create a Workflow Center deployment environment and 'PS' to create a Workflow Server deployment environment.</td>
    <td><code>PC</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cluster_type']</code></td>
    <td>The type of cluster: SingleCluster, SingleClusters, or ThreeClusters (not yet supported).</td>
    <td><code>SingleCluster</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['deadmin_alias_user']</code></td>
    <td>The user name of the deployment environment administrator.</td>
    <td><code>deadmin</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['deadmin_alias_password']</code></td>
    <td>The password of the deployment environment administrator.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['celladmin_alias_user']</code></td>
    <td>The user name of the cell administrator.</td>
    <td><code>admin</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['celladmin_alias_password']</code></td>
    <td>The password of the cell administrator.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['dmgr_hostname']</code></td>
    <td>The fully qualified domain name of the deployment manager to federate this node to.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['ip_hostname_pairs']</code></td>
    <td>The IPv4 address and fully qualified domain name pairs for all provisioned virtual machines.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['node_hostnames']</code></td>
    <td>The fully qualified domain names of all nodes in the deployment environment.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['node_hostname']</code></td>
    <td>The fully qualified domain name of this node.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ihs_hostname']</code></td>
    <td>The fully qualified domain name of the IBM HTTP Server.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ihs_https_port']</code></td>
    <td>The port number of the IBM HTTP Server.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['case_network_shared_dir']</code></td>
    <td>The network shared directory (NFS type only), which is shared among multiple nodes in the deployment environment. Required for the Advanced product type with multiple nodes.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['database_type']</code></td>
    <td>The database type, DB2 or Oracle.</td>
    <td><code>DB2</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db2_install']</code></td>
    <td>A flag to determine whether Db2 is installed as the embedded database system.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db2_hostname']</code></td>
    <td>The fully qualified domain name of the Db2 database.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db2_port']</code></td>
    <td>The port number of the Db2 database.</td>
    <td><code>50000</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db_alias_user']</code></td>
    <td>The user name of the Db2 database that will be used to create the database user authentication alias.</td>
    <td><code>db2inst1</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db_alias_password']</code></td>
    <td>The password of the Db2 database that will be used to create the database user authentication alias.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db2_bpmdb_name']</code></td>
    <td>The name of the Process database.</td>
    <td><code>BPMDB</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db2_pdwdb_name']</code></td>
    <td>The name of the Performance Data Warehouse database.</td>
    <td><code>PDWDB</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db2_cmndb_name']</code></td>
    <td>The name of the Common database.</td>
    <td><code>CMNDB</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['db2_cpedb_name']</code></td>
    <td>The name of the Content database.</td>
    <td><code>CPEDB</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['icndb']['schema']</code></td>
    <td>The schema for IBM Content Navigator (ICN).</td>
    <td><code>ICNSA</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['icndb']['tsicn']</code></td>
    <td>The table space for IBM Content Navigator (ICN).</td>
    <td><code>WFICNTS</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['dosdb']['schema']</code></td>
    <td>The schema for the design object store (DOS).</td>
    <td><code>DOSSA</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['dosdb']['tsdosdata']</code></td>
    <td>The data table space for the design object store (DOS).</td>
    <td><code>DOSSA_DATA_TS</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['dosdb']['tsdoslob']</code></td>
    <td>The large object table space for the design object store (DOS).</td>
    <td><code>DOSSA_LOB_TS</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['dosdb']['tsdosidx']</code></td>
    <td>The index table space for the design object store (DOS).</td>
    <td><code>DOSSA_IDX_TS</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['tosdb']['schema']</code></td>
    <td>The schema for the target object store (TOS).</td>
    <td><code>TOSSA</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['tosdb']['tstosdata']</code></td>
    <td>The data table space for the target object store (TOS).</td>
    <td><code>TOSSA_DATA_TS</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['tosdb']['tstoslob']</code></td>
    <td>The large object table space for the target object store (TOS).</td>
    <td><code>TOSSA_LOB_TS</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['cpedb']['tosdb']['tstosidx']</code></td>
    <td>The index table space for the target object store (TOS).</td>
    <td><code>TOSSA_IDX_TS</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['hostname']</code></td>
    <td>The hostname of the Oracle database.</td>
    <td><code></code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['port']</code></td>
    <td>The port number of the Oracle database.</td>
    <td><code>1521</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['database_name']</code></td>
    <td>The name of the Oracle database.</td>
    <td><code>orcl</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['jdbc_driver']</code></td>
    <td>The name of the Oracle JDBC Driver.</td>
    <td><code></code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['shareddb']['username']</code></td>
    <td>The user name of the Shared database.</td>
    <td><code>cmnuser</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['shareddb']['password']</code></td>
    <td>The user password of the Shared database.</td>
    <td><code></code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['cellonlydb']['username']</code></td>
    <td>The user name of the Cell database.</td>
    <td><code>celluser</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['cellonlydb']['password']</code></td>
    <td>The user password of the Cell database.</td>
    <td><code></code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['psdb']['username']</code></td>
    <td>The user name of the Process Server database.</td>
    <td><code>psuser</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['psdb']['password']</code></td>
    <td>The user password of the Process Server database.</td>
    <td><code></code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['icndb']['username']</code></td>
    <td>The user name of the IBM Content Navigator (ICN) database.</td>
    <td><code>icnuser</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['icndb']['password']</code></td>
    <td>The user password of the IBM Content Navigator (ICN) database.</td>
    <td><code></code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['icndb']['tsicn']</code></td>
    <td>The table space for IBM Content Navigator (ICN).</td>
    <td><code>WFICNTS</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['dosdb']['username']</code></td>
    <td>The user name of the Design Object Store (DOS) database.</td>
    <td><code>dosuser</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['dosdb']['password']</code></td>
    <td>The user password of the Design Object Store (DOS) database.</td>
    <td><code></code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['dosdb']['tsdosdata']</code></td>
    <td>The data table space for the Design Object Store (DOS).</td>
    <td><code>DOSSA_DATA_TS</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['tosdb']['username']</code></td>
    <td>The user name of the Target Object Store (TOS) database.</td>
    <td><code>tosuser</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['tosdb']['password']</code></td>
    <td>The user password of the Target Object Store (TOS) database.</td>
    <td><code></code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['tosdb']['tstosdata']</code></td>
    <td>The data table space for the Target Object Store (TOS) database.</td>
    <td><code>TOSSA_DATA_TS</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['pdwdb']['username']</code></td>
    <td>The user name of the Performance Data Warehouse database.</td>
    <td><code>pdwuser</code></td>
  </tr>
   <tr>
    <td><code>node['oracle']['config']['pdwdb']['password']</code></td>
    <td>The user password of the Performance Data Warehouse database.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ps_environment_purpose']</code></td>
    <td>The purpose of this Workflow Server deployment environment: Development, Test, Staging, or Production.</td>
    <td><code>Development</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ps_offline']</code></td>
    <td>The valid values are true or false. Use false if the Workflow Server is online and can be connected to the Workflow Center.</td>
    <td><code>false</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ps_pc_transport_protocol']</code></td>
    <td>The valid values are http or https. The transport protocol for communicating with the Workflow Center environment.</td>
    <td><code>https</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ps_pc_hostname']</code></td>
    <td>The host name of the Workflow Center environment.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ps_pc_port']</code></td>
    <td>The port number of the Workflow Center environment.</td>
    <td><code>9443</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ps_pc_contextroot_prefix']</code></td>
    <td>The context root prefix of the Workflow Center environment. If set, the context root prefix must start with a forward slash character (/).</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ps_pc_alias_user']</code></td>
    <td>The user name of the Workflow Center authentication alias (which is used by online Workflow Server environments to connect to Workflow Center).</td>
    <td><code>admin</code></td>
  </tr>
  <tr>
    <td><code>node['workflow']['config']['ps_pc_alias_password']</code></td>
    <td>The password of the Workflow Center authentication alias (which is used by online Workflow Server environments to connect to Workflow Center).</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['was']['offering_id']</code></td>
    <td>The product ID of the WebSphere Application Server offering.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['db2']['install']</code></td>
    <td>Whether to install Db2 as the embedded database system.</td>
    <td><code>true</code></td>
  </tr>
  <tr>
    <td><code>node['db2']['offering_id']</code></td>
    <td>The product ID of the IBM Business Automation Workflow embedded Db2 offering.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['db2']['offering_version']</code></td>
    <td>The IBM Business Automation Workflow embedded Db2 offering version value.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['db2']['port']</code></td>
    <td>The port number of the Db2 database.</td>
    <td><code>50000</code></td>
  </tr>
  <tr>
    <td><code>node['db2']['username']</code></td>
    <td>The user name for the Db2 database.</td>
    <td><code>db2inst1</code></td>
  </tr>
  <tr>
    <td><code>node['db2']['password']</code></td>
    <td>The password for the Db2 database.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['db2']['das_newuser']</code></td>
    <td>Whether to create a new Db2 administration server user.</td>
    <td><code>true</code></td>
  </tr>
  <tr>
    <td><code>node['db2']['fenced_newuser']</code></td>
    <td>Whether to create a new fenced user.</td>
    <td><code>true</code></td>
  </tr>
  <tr>
    <td><code>node['db2']['fenced_username']</code></td>
    <td>The fenced user name for the Db2 database.</td>
    <td><code>db2fenc1</code></td>
  </tr>
  <tr>
    <td><code>node['db2']['fenced_password']</code></td>
    <td>The fenced password for the Db2 database.</td>
    <td><code></code></td>
  </tr>
  <tr>
    <td><code>node['db2']['das_username']</code></td>
    <td>The user name for the Db2 administration server.</td>
    <td><code>dasusr1</code></td>
  </tr>
  <tr>
    <td><code>node['db2']['das_password']</code></td>
    <td>The password for the Db2 administration server.</td>
    <td><code></code></td>
  </tr>
</table>


Recipes
-------

### workflow::prereq.rb

Adds the prerequisites that need to be added to the environment before you install Business Automation Workflow, including
adding users, packages, and kernel configuration.

### workflow::prereq_check.rb

Checks the environment before the software is installed.

### workflow::install.rb

Installs IBM Business Automation Workflow.

### workflow::applyifix.rb

Applies interim fixes to IBM Business Automation Workflow.

### workflow::cleanup.rb

Removes all unwanted files, such as installation media and temporary files.

### workflow::create_singlecluster.rb

Creates an IBM Business Automation Workflow Single Cluster topology.

### workflow::create_singleclusters.rb

Creates an IBM Business Automation Workflow Single Cluster on Multiple Nodes topology.

### workflow::ihs.rb

Configures IBM HTTP Server.

### workflow::webserver.rb

Creates a web server in the IBM Business Automation Workflow environment.

License and Author
------------------

Author:: IBM Corp (<>)

Copyright:: 2018, IBM Corp

License:: Copyright IBM Corp. 2018
