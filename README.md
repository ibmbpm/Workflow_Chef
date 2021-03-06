IBM Business Automation Workflow Chef Deployment
============

## Description

Use this script to work with Chef and the IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise automatically.

Requirements
------------

### Platform:

* Ubuntu 16.04 LTS
* Ubuntu 18.04 LTS
* Red Hat Enterprise Linux (RHEL) Server 6.8
* Red Hat Enterprise Linux (RHEL) Server 7.4

### Database:
* DB2
* Oracle

### Chef:
Latest stable release:
* Chef Infra Server 13.0.17
* Chef Workstation 0.7.4
* Chef Infra Client 15.2.20

### Cookbooks:

* [workflow](https://github.com/ibmbpm/Workflow_Chef/tree/master/cookbook/cookbook_ibm_workflow_multios)
* [linux](https://github.com/IBM-CAMHub-Open/cookbook_ibm_utils_linux)
* [ibm_cloud_utils](https://github.com/IBM-CAMHub-Open/cookbook_ibm_cloud_utils_multios)

## Scenarios

### Single node scenario
This script works with the IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise on a single host. <br> 

#### Single Node Topology:
Single host: IBM Business Automation Workflow Enterprise - Deployment Manager and Custom Node, one cluster member. 
#### Software Deployed
IBM WebSphere Application Server Network Deployment V8.5.5.15 <br>
IBM Business Automation Workflow Enterprise V19.0.0.2 <br>
IBM DB2 Enterprise Server Edition V11 <br>

#### Single Node Structure
##### Installation and configuration
Install and configure IBM Business Automation Workflow Enterprise on a single host. <br>
<pre>
&lt;Project_ROOT&gt;/singlenode/baw_singlenode_fresh_install.properties
&lt;Project_ROOT&gt;/singlenode/baw_singlenode_fresh_install.sh
</pre>
##### Upgrade
Upgrade IBM Business Automation Workflow Enterprise with fix packs on a single host. <br>
<pre>
&lt;Project_ROOT&gt;/singlenode/upgrade/baw_singlenode_upgrade.properties
&lt;Project_ROOT&gt;/singlenode/upgrade/baw_singlenode_upgrade.sh
</pre>
##### Apply interim fix
Apply interim fix packs to IBM Business Automation Workflow Enterprise on one single host. <br>
<pre>
&lt;Project_ROOT&gt;/singlenode/apply_ifix/baw_singlenode_apply_ifix.properties
&lt;Project_ROOT&gt;/singlenode/apply_ifix/baw_singlenode_apply_ifix.sh
</pre>

### Multinode scenario
This script works with the IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise on two hosts. <br>

#### Multinode Topology:
Host 1: IBM Business Automation Workflow Deployment Manager, Custom Node, one cluster member. <br>
Host 2: IBM Business Automation Workflow Custom Node, one cluster member.
#### Software Deployed
IBM WebSphere Application Server Network Deployment V8.5.5.15 <br>
IBM Business Automation Workflow Enterprise V19.0.0.2

#### Multiple Nodes Structure
##### Installation and configuration
Install and configure IBM Business Automation Workflow Enterprise on two hosts.<br>
<pre>
&lt;Project_ROOT&gt;/multinodes/baw_multinodes_fresh_install.properties
&lt;Project_ROOT&gt;/multinodes/baw_multinodes_fresh_install.sh
</pre>
##### Upgrade
Upgrade IBM Business Automation Workflow Enterprise on two hosts.
<pre>
&lt;Project_ROOT&gt;/multinodes/upgrade/baw_multinodes_upgrade.properties
&lt;Project_ROOT&gt;/multinodes/upgrade/baw_multinodes_upgrade.sh
</pre>
##### Apply interim fix
Apply interim fix packs to IBM Business Automation Workflow Enterprise on two hosts. <br>
<pre>
&lt;Project_ROOT&gt;/multinodes/apply_ifix/baw_multinodes_apply_ifix.properties
&lt;Project_ROOT&gt;/multinodes/apply_ifix/baw_multinodes_apply_ifix.sh
</pre>
----------

## Preparation

 1. Prepare hosts for the Chef Server and Chef Workstation and set up the Chef environment. <br>
    1.1 Prepare hosts for the Chef Server and Chef Workstation. <br>
        You can install the Chef Server and the Chef Workstation on a single host or two separate hosts. <br>
    1.2 Prepare hosts (as Chef Client nodes) for Business Automation Workflow installation.<br>
        A host must have one of the supported platforms installed. The number of hosts depends on your needs and the topology you choose: one host for a Single Node Topology, two hosts for a Multinode Topology. <br>
        If a host has internet access, the Chef Clients are automatically installed. If a host doesn’t have internet access, you must manually install the Chef Clients. <br>
    1.3 Configure the /etc/hosts file on all hosts in the topology with the Chef Server, Chef Workstation, and Chef Clients information. <br>
         
        Notes: 
        Include the following information for each host:
        [IP_address] [your_host_fully_qualified_domain_name] [your_host_short_name]
        
    For example,
    <pre>tail /etc/hosts
    
    # Configuration for BAW Chef
    
    # Chef Server and Chef Workstation host
    10.0.16.101 hostname1.example.org hostname1
    
    # Multinode scenario
    # Chef Client host, Workflow01, DMGR node
    10.0.16.102 hostname2.example.org hostname2
    # Chef Client host, Workflow02, Managed node
    10.0.16.103 hostname3.example.org hostname3 
    
    # Single node scenario
    # Chef Client host, Single node
    10.0.16.104 hostname4.example.org hostname4
    </pre> 
    
        Notes: 
        Replace "10.0.16.101, 10.0.16.102, 10.0.16.103, 10.0.16.104" with your hosts' IP address.
        Replace "hostname1, hostname2, hostname3, hostname4" with your host short names. 
        Replace "example.org" with your domain name.
    
    1.4  Set up the Chef environment. For information about configuring the Chef Server and Chef Workstation, refer to https://docs.chef.io/chef_overview.html.

 2. On the Chef Workstation host. <br>
    2.1 Download the cookbook projects with the branch name listed in the following table and unzip them if necessary.<br>
    2.2 Find the __workflow, linux__, and __ibm_cloud_utils__ cookbooks in the __&lt;Project_ROOT&gt;/chef/cookbooks/__ folder for each project and copy them to the cookbook folder configured in your Chef configuration file with "__cookbook_path__" attribute (see https://docs.chef.io/config_rb.html). <br>
    2.3 Download this IBM Business Automation Workflow Chef Deployment (__Workflow_Chef__) project to the "__chef-repo__" (see https://docs.chef.io/chef_repo.html) directory, from where you can run the knife commands.<br>
 
  <table>
   <tr>
     <th>Cookbook</th>
     <th>Download</th>
     <th>Branch</th>
   </tr>
   <tr>
     <td>IBM Business Automation Workflow Cookbook:<br> Cookbook Path: &lt;Project_ROOT&gt;/chef/cookbooks/workflow</td>
	<td>https://github.com/ibmbpm/Workflow_Chef/tree/master/cookbook/cookbook_ibm_workflow_multios<br><b>OR</b> &lt;Workflow_Chef_Project_ROOT&gt;/cookbook/cookbook_ibm_workflow_multios</td>
     <td>3.0</td>
   </tr>
   <tr>
     <td>Linux Cookbook: <br> Cookbook Path:&lt;Project_ROOT&gt;/chef/cookbooks/linux</td>
     <td>https://github.com/IBM-CAMHub-Open/cookbook_ibm_utils_linux</td>
     <td>2.0</td>
   </tr>
   <tr>  
     <td>Ibm_cloud_utils Cookbook: <br> Cookbook Path: &lt;Project_ROOT&gt;/chef/cookbooks/ibm_cloud_utils</td>
     <td>https://github.com/IBM-CAMHub-Open/cookbook_ibm_cloud_utils_multios</td>
     <td>2.0</td>
   </tr>  
 </table>
 
 3. Make sure the "__cookbook_path__" in your Chef configuration file points to the cookbooks you downloaded in Step 2, then upload the required cookbooks to the Chef Server.<br>
    For example: 
    <pre>knife cookbook upload ibm_cloud_utils linux workflow</pre>
    
 4. Download the IBM Business Automation Workflow 18.0.0.1 installation packages from https://www.ibm.com/software/passportadvantage/pao_customer.html.
 Download workflow.19002.delta.repository.zip, 8.5.5-WS-WAS-FP015-part1.zip; 8.5.5-WS-WAS-FP015-part2.zip and 8.5.5-WS-WAS-FP015-part3.zip from IBM Fix Central https://www-945.ibm.com/support/fixcentral/

 5. If you are installing IBM Business Automation Workflow using an Oracle database server, prepare one of the following JDBC drivers: ojdbc6.jar, ojdbc7.jar, ojdbc8.jar.
 
 6. Prepare the software repository.<br>
    Upload the IBM Business Automation Workflow installation images to the software repository. The permission for the software repository must be at least 755 for the deployment to succeed. You must include the mandatory fix pack packages and interim fixes.<br> 
    You can prepare the software repository in one of the following ways: 
    * As a local software repository on each Chef Client
    * As a remote HTTPS Server shared among the Chef Clients
    <br>
    Before you run the shell script, configure the root path of the software repository in the properties files.<br>
    For example, for a local software repository: 
    <pre>ibm_sw_repo=file:///opt/swRepo 
    </pre>
    For example, for a remote HTTPS server: 
    <pre>ibm_sw_repo=https://9.180.111.29:9999
    </pre>
     To enable authentication on the remote HTTPS server, you must also add the user name and password properties to the properties files.<br>
     For example: <br>
      <pre>
      #Software Repository User Name: ibm_sw_repo_user can be empty when using local repository
      ibm_sw_repo_user=repouser
      #Software Repository User Password - Base 64 encoded: ibm_sw_repo_password can be empty when using local repository
      ibm_sw_repo_password=cGFzc3cwcmQ=</pre>

    The following table shows the required images with their required names and paths.<br>
     
        Notes: The [ibm_sw_repo] is the software repository root.

 <table>
   <tr>
     <th>Product</th>
     <th>Version</th>
     <th>Arch</th>
     <th>Required path</th>
     <th>File</th>
   </tr>
   <tr>
    <td><br>IBM Business Automation Workflow</br><br>(Websphere Application Server included)</br>
     <td><br>18.0.0.1</br><br>8.5.5</br></td>
     <td>X86_64</td>
     <td>[ibm_sw_repo]/workflow</td>
     <td><br>BAW_18_0_0_1_Linux_x86_1_of_3.tar.gz</br><br>BAW_18_0_0_1_Linux_x86_2_of_3.tar.gz</br><br>BAW_18_0_0_1_Linux_x86_3_of_3.tar.gz</br></br>Notes: To ensure that the downloaded images are recognized by the scripts, they must be named the same as the *.tar.gz files.</td>
   </tr>
   <tr>
     <td>Interim fixes</td>
     <td> </td>
     <td>X86_64</td>
     <td>[ibm_sw_repo]/workflow/ifixes</td>
     <td></td>
   </tr>
   <tr>
     <td>Fix packs</td>
     <td> </td>
     <td>X86_64</td>
     <td>[ibm_sw_repo]/workflow/fixpacks</td>
     <td><br>The full names of the Workflow and WAS fix pack installation packages</br>
         <br>workflow.19002.delta.repository.zip </br>
         <br>8.5.5-WS-WAS-FP015-part1.zip; 8.5.5-WS-WAS-FP015-part2.zip; 8.5.5-WS-WAS-FP015-part3.zip</br>
     </td>
   </tr>
   <tr>
    <td><br>Database Drivers</br></td>
    <td></td>
    <td></td>
    <td>[ibm_sw_repo]/workflow/drivers</td>
    <td><br>The JDBC drivers for your Oracle database server, such as ojdbc6.jar, ojdbc7.jar, or ojdbc8.jar.</br> <br>For example, the oracle jdbc driver: </br> ojdbc7.jar</td>
   </tr>
   <tr>
 </table>
 
 7. Check that you have the following prerequisites:
 
    __Database server__<br>
      For the IBM Business Automation Workflow Enterprise V19 on a single virtual machine scenario, you can install the database server before you install IBM Business Automation Workflow or as part of the product installation.<br>
      For the IBM Business Automation Workflow Enterprise V19 on multiple virtual machines scenario, you must install the database server before you install IBM Business Automation Workflow.<br>
      If you install the database server before you install IBM Business Automation Workflow, follow the instructions for your database type:<br>
      __DB2 database__<br>
      To create the required databases, follow the instructions in [Creating Db2 databases](https://www.ibm.com/support/knowledgecenter/en/SS8JB4/com.ibm.wbpm.imuc.doc/topics/db_typ_nd_lin_db2.html):<br>
    
    <table>
      <tr>
        <th>Database</th>
        <th>Database name</th>
      </tr>
      <tr>
        <td>Common database</td>
        <td>CMNDB</td>
      </tr>
      <tr>
        <td>Process database</td>
        <td>BPMDB</td>
      </tr>
      <tr>
        <td>Performance Data Warehouse database</td>
        <td>PDWDB</td>
      </tr>
      <tr>
        <td>Content database</td>
        <td>CPEDB</td>
      </tr>
    </table>
    
    <table>
      <tr>
        <th>Schema/Table space</th>
        <th>Schema/Table space name</th>
      </tr>
      <tr>
        <td>The schema for IBM Content Navigator (ICN)</td>
        <td>ICNSA</td>
      </tr>
      <tr>
        <td>The table space for IBM Content Navigator (ICN)</td>
        <td>WFICNTS</td>
      </tr>
      <tr>
        <td>The schema for the design object store (DOS)</td>
        <td>DOSSA</td>
      </tr>
      <tr>
        <td>The data table space for the design object store (DOS)</td>
        <td>DOSSA_DATA_TS</td>
      </tr>
      <tr>
        <td>The large object table space for the design object store (DOS)</td>
        <td>DOSSA_LOB_TS</td>
      </tr>
      <tr>
        <td>The index table space for the design object store (DOS)</td>
        <td>DOSSA_IDX_TS</td>
      </tr>
      <tr>
        <td>The schema for the target object store (TOS)</td>
        <td>TOSSA</td>
      </tr>
      <tr>
        <td>The data table space for the target object store (TOS)</td>
        <td>TOSSA_DATA_TS</td>
      </tr>
      <tr>
        <td>The large object table space for the target object store (TOS)</td>
        <td>TOSSA_LOB_TS</td>
      </tr>
      <tr>
        <td>The index table space for the target object store (TOS)</td>
        <td>TOSSA_IDX_TS</td>
      </tr>
    </table>
    
    __Oracle database__<br>
     To create the following required databases and users, follow the instructions in [Running the generated Oracle database scripts](https://www.ibm.com/support/knowledgecenter/SS8JB4/com.ibm.wbpm.imuc.doc/topics/bpmcfg_db_run_win_orcl_man.html):<br>
     
 
    <table>
      <tr>
        <th>Database</th>
        <th>Schema/Database users</th>
      </tr>
      <tr>
        <td>Shared database</td>
        <td>cmnuser</td>
      </tr>
      <tr>
        <td>Cell database</td>
        <td>celluser</td>
      </tr>
      <tr>
        <td>Process Server database</td>
        <td>psuser</td>
      </tr>
      <tr>
        <td>Performance Data Warehouse database</td>
        <td>pdwuser</td>
      </tr>
      <tr>
        <td>IBM Content Navigator database</td>
        <td>icnuser</td>
      </tr>
      <tr>
        <td>Design Object Store database</td>
        <td>dosuser</td>
      </tr>
      <tr>
        <td>Target Object Stare database</td>
        <td>tosuser</td>
      </tr>
    </table>
    
    <table>
      <tr>
        <th>Table space</th>
        <th>Table space name</th>
      </tr>
      <tr>
        <td>The table space for IBM Content Navigator (ICN)</td>
        <td>WFICNTS</td>
      </tr>
      <tr>
        <td>The data table space for the design object store (DOS)</td>
        <td>DOSSA_DATA_TS</td>
      </tr>
      <tr>
        <td>The data table space for the target object store (TOS)</td>
        <td>TOSSA_DATA_TS</td>
      </tr>
    </table>
    For the AdvancedOnly Configuration Product Type, you need only the SharedDb and CellOnlyDb schemas.

## Running the script
Script root directory: 
<pre>
&lt;Your chef-repo directory&gt;/Workflow_Chef
</pre>

### Prepare properties
Before you run a script (*.sh), you must configure the password encryptioon method you are using in the properties files (\*.properties). You can use one of the following methods: 

 * Fill in the Base64-encrypted passwords in the properties file. The program generates and uses the Chef vault with those passwords automatically at runtime.
 * Use an existing Chef Vault on the Chef server. You do not need fill in the passwords in the properties file but you must create a Chef vault and fill the information in the __Optional: Existing Chef Vault__ section in the properties file manually ahead of time. Use one of the following JSON templates to create the Chef vault: <br> 
    
    * Template for a fresh installation: 

        <Workflow_Chef_ROOT>/templates/chef_vault_json/workflow_secrets_fresh_install.json

    * Template for applying an interim fix or an upgrade: 

        <Workflow_Chef_ROOT>/templates/chef_vault_json/workflow_secrets_applyifix_upgrade.json

    Replace the JSON vault with your own passwords (do not delete any JSON keys), then use the following knife vault to create the Chef vault on the Chef Server:<br>  
<pre>
    knife vault create &lt;workflow_chef_vault_name&gt; &lt;workflow_chef_vault_item&gt; --json &lt;the json file like workflow_secrets_fresh_install.json&gt; --mode client
    knife vault delete &lt;workflow_chef_vault_name&gt; &lt;workflow_chef_vault_item&gt; --mode client
</pre>
   More information about Chef vault: https://docs.chef.io/chef_vault.html 


### Running the scripts
After you prepare the properties file, you can run the corresponding shell script (*.sh).<br>

    Notes: The execute permission for the shell script (*.sh) must be granted in advance.
    
For example: 
<pre>
&lt;Project_ROOT&gt;/singlenode/baw_singlenode_fresh_install.sh
</pre>

## Generated roles and logs
    Notes: "hostname2, hostname3, hostname4, hostname5, hostname6, hostname7" are examples, they should be the host short names which you used for the deployment.

### The directory structure of the generated roles
<pre>/tmp/baw_chef_shell_tmp/
├── multinodes
│   ├── hosts_hostname2_hostname3_roles
│   │   ├── apply_ifix
│   │   ├── fresh_install
│   │   └── upgrade
│   └── hosts_hostname5_hostname6_roles
│       ├── apply_ifix
│       ├── fresh_install
│       └── upgrade
└── singlenode
    ├── host_hostname4_roles
    │   ├── apply_ifix
    │   ├── fresh_install
    │   └── upgrade
    └── host_hostname7_roles
        ├── apply_ifix
        ├── fresh_install
        └── upgrade
</pre>

### The directory structure of the generated logs

<pre>/var/log/baw_chef_shell_log/
├── multinodes_noihs
│   ├── hosts_hostname2_hostname3
│   │   ├── apply_ifix
│   │   ├── fresh_install
│   │   └── upgrade
│   └── hosts_hostname5_hostname6
│       ├── apply_ifix
│       ├── fresh_install
│       └── upgrade
└── singlenode
    ├── host_hostname4
    │   ├── apply_ifix
    │   ├── fresh_install
    │   └── upgrade
    └── host_hostname7
        ├── apply_ifix
        ├── fresh_install
        └── upgrade
</pre>

## License Information

See the License folder for more information about how this project is licensed.
