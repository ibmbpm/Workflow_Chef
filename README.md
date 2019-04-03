# Workflow_Chef_Shell_Script

## Description

Use this script to work with Chef and the IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise automatically.

## Scenarios

### Single node scenario
This script works with IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise on a single host. <br> 

#### Single Node Topology:
Single host: IBM Business Automation Workflow Enterprise - Deployment Manager and Custom Node, one cluster member. <br>
#### Software Deployed
IBM WebSphere Application Server Network Deployment V8.5.5 <br>
IBM Business Automation Workflow Enterprise V19 <br>
IBM DB2 Enterprise Server Edition V11 <br>

### Multinode scenario
This script works with IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise on two hosts. <br>

#### Multinode Topology:
Host 1: IBM Business Automation Workflow Deployment Manager, Custom Node, one cluster member <br>
Host 2: IBM Business Automation Workflow Custom Node, one cluster member <br>
#### Software Deployed
IBM WebSphere Application Server Network Deployment V8.5.5 <br>
IBM Business Automation Workflow Enterprise V19 <br>

## Preparation

 1. Set up the Chef environment, Chef Server and Chef Workstation. For information about configuring the Chef Server and Chef Workstation, refers to https://docs.chef.io/chef_overview.html.

 2. Make sure that you have the latest version of the cookbooks. 
 <table>
   <tr>
     <th>Cookbook</th>
     <th>Download</th>
     <th>Version</th>
   </tr>
   <tr>
     <td>IBM Business Automation Workflow Cookbook</td>
     <td>https://github.com/IBM-CAMHub-Open/cookbook_ibm_workflow_multios</td>
     <td>3.0</td>
   </tr>
   <tr>
     <td>Linux Cookbook</td>
     <td>https://github.com/IBM-CAMHub-Open/cookbook_ibm_utils_linux</td>
     <td>2.0</td>
   </tr>
   <tr>  
     <td>Ibm_cloud_utils Cookbook</td>
     <td>https://github.com/IBM-CAMHub-Open/cookbook_ibm_cloud_utils_multios</td>
     <td>2.0</td>
   </tr>  
 </table>
 
 3. Upload the cookbooks to the Chef Server.<br>
    For example: 
    <pre>knife cookbook upload ibm_cloud_utils linux workflow</pre>

 4. Download Workflow_Chef project from https://github.ibm.com/bpm/Workflow_Chef to the Chef Workstation. Unzip it to the  "Workflow_Chef" directory under the "chef-repo" (https://docs.chef.io/chef_repo.html) directory, from where you can run the knife commands.
 
 5. Update the /etc/hosts file for all involved hosts with the Chef Server, Chef Workstations, and Chef Clients information. <br>
    For example:
    <pre>cat /etc/hosts
    #configuration for chef
    #Chef Server host
    10.0.15.107 chef-server.test.local chef-server
    #Chef Workstation host
    10.0.16.95 chef-workstation.test.local chef-workstation
    # Chef Client host, Workflow01, DMGR node
    10.0.16.195 kvm-018878.test.local kvm-018878
    #Chef Client host, Workflow02, managed node
    10.0.16.190 kvm-018877.test.local kvm-018877 
    #Chef Client host, Single node, BAW on single node
    10.0.15.4 kvm-018879.test.local kvm-018879
    </pre>
 6. Download the IBM Business Automation Workflow packages from https://www.ibm.com/software/passportadvantage/pao_customer.html. You need parts CNTA0ML, CNTA1ML, CNTA2ML.
 Download workflow.19001.delta.repository.zip, 8.5.5-WS-WAS-FP015-part1.zip; 8.5.5-WS-WAS-FP015-part2.zip and 8.5.5-WS-WAS-FP015-part3.zip from IBM Fix Central https://www-945.ibm.com/support/fixcentral/

 7. If you are installing IBM Business Automation Workflow using an Oracle database server, prepare one of the following JDBC drivers: ojdbc6.jar, ojdbc7.jar, ojdbc8.jar.
 
 8. Prepare the software repository.<br>
    Upload the IBM Business Automation Workflow installation images to the software repository. The permission for the software repository must be at least 755 for the deployment to succeed. You must include the mandatory fix pack packages and interim fixes.<br> 
    You can prepare the software repository in one of the following ways: 
    1. As a local software repository on each Chef Client
    2. As a remote HTTPS Server shared among the Chef Clients
    
    Before you run the shell script, configure the root path of software repository in the __properties files__ .<br>
    For example, for a local software repository: 
    <pre>ibm_sw_repo=file:///opt/swRepo 
    </pre>
    For example, for a remote HTTPS server: 
    <pre>ibm_sw_repo=https://9.180.111.29:9999/
    </pre>
     Two additional properties are required in the __properties files__ for remote authentication.<br>
     For example: <br>
      <pre>
      #Software Repository User Name: ibm_sw_repo_user can be empty when using local repo
      ibm_sw_repo_user=repouser
      #Software Repository User Password - Base 64 encoded: ibm_sw_repo_password can be empty when using local repo
      ibm_sw_repo_password=cGFzc3cwcmQ=</pre>

    The following table shows the required images and their required path.
    Notes: Replace [ibm_sw_repo] with the value of "ibm_sw_repo" defined in the properties files.

 <table>
   <tr>
     <th>Product</th>
     <th>Version</th>
     <th>Arch</th>
     <th>Repository Root</th>
     <th>File</th>
   </tr>
   <tr>
    <td><br>Websphere Application Server</br><br>IBM Business Automation Workflow</br>
     <td><br>8.5.5</br><br>19.0</br></td>
     <td>X86_64</td>
     <td>[ibm_sw_repo]/workflow</td>
     <td><br>BAW_18_0_0_1_Linux_x86_1_of_3.tar.gz</br><br>BAW_18_0_0_1_Linux_x86_2_of_3.tar.gz</br><br>BAW_18_0_0_1_Linux_x86_3_of_3.tar.gz</br></td>
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
     <td><br>The full names of Workflow, and/or WAS fix pack installation packages</br>
         <br>workflow.19001.delta.repository.zip </br>
         <br>8.5.5-WS-WAS-FP015-part1.zip; 8.5.5-WS-WAS-FP015-part2.zip; 8.5.5-WS-WAS-FP015-part3.zip</br>
     </td>
   </tr>
   <tr>
    <td><br>Database Drivers</br></td>
    <td></td>
    <td></td>
    <td>[ibm_sw_repo]/workflow/drivers</td>
    <td><br>The files of JDBC Drivers for connecting databases</br> <br>For example, the oracle jdbc driver: </br> ojdbc7.jar</td>
   </tr>
   <tr>
 </table>
 
 9. Check that you have the following prerequisites:
 
    __Database server__<br>
      For the IBM Business Automation Workflow Enterprise V19 on a single virtual machine scenario, you can install the database server before you install IBM Business Automation Workflow or as part of the product installation.<br>
      For the IBM Business Automation Workflow Enterprise V19 on multiple virtual machines scenario, you must install the database server before you install IBM Business Automation Workflow.<br>
      If you install the database server before you install IBM Business Automation Workflow, follow the instructions for your database type:<br>
 
    __DB2 database__<br>
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
Before you run a script(*.sh), ensure that you configure the appropriate properties in the corresponding properties files (\*.properties). The locations of the properties files and scripts are listed in the following sections.

    Notes: All passwords in properties file must be Base 64 encoded.

#### Single node 
##### Installation and configuration
Install and configure IBM Business Automation Workflow Enterprise on a single host. <br>
<pre>
./singlenode/baw_singlenode_fresh_install.properties
./singlenode/baw_singlenode_fresh_install.sh
</pre>
##### Upgrade
Upgrade IBM Business Automation Workflow Enterprise with fix packs on a single host. <br>
<pre>
./singlenode/upgrade/baw_singlenode_upgrade.properties
./singlenode/upgrade/baw_singlenode_upgrade.sh
</pre>
##### Apply interim fix
Apply interim fix packs to IBM Business Automation Workflow Enterprise on one single host. <br>
<pre>
./singlenode/apply_ifix/baw_singlenode_apply_ifix.properties
./singlenode/apply_ifix/baw_singlenode_apply_ifix.sh
</pre>

#### Multiple nodes
##### Installation and configuration
Install and configure IBM Business Automation Workflow Enterprise on two hosts.<br>
<pre>
./multinodes/baw_multinodes_fresh_install.properties
./multinodes/baw_multinodes_fresh_install.sh
</pre>
##### Upgrade
Upgrade IBM Business Automation Workflow Enterprise on two hosts.
<pre>
./multinodes/upgrade/baw_multinodes_upgrade.properties
./multinodes/upgrade/baw_multinodes_upgrade.sh
</pre>
##### Apply interim fix
Apply interim fix packs to IBM Business Automation Workflow Enterprise on two hosts. <br>
<pre>
./multinodes/apply_ifix/baw_multinodes_apply_ifix.properties
./multinodes/apply_ifix/baw_multinodes_apply_ifix.sh
</pre>

### Running the scripts
After you prepare the properties file, you can run the corresponding shell script (*.sh).<br>
For example: 
<pre>
./singlenode/baw_singlenode_fresh_install.sh
</pre>

### Generated roles and logs
    Notes: "kvm-018784, kvm-018785, kvm-018786, kvm-018787, kvm-018788, kvm-018789" are host short names

#### The directory structure of the generated roles
<pre>/tmp/baw_chef_shell_tmp/
├── multinodes
│   ├── hosts_kvm-018786_kvm-018785_roles
│   │   ├── apply_ifix
│   │   ├── fresh_install
│   │   └── upgrade
│   └── hosts_kvm-018788_kvm-018787_roles
│       ├── apply_ifix
│       ├── fresh_install
│       └── upgrade
└── singlenode
    ├── host_kvm-018784_roles
    │   ├── apply_ifix
    │   ├── fresh_install
    │   └── upgrade
    └── host_kvm-018789_roles
        ├── apply_ifix
        ├── fresh_install
        └── upgrade
</pre>

#### The directory structure of the generated logs

<pre>/var/log/baw_chef_shell_log/
├── multinodes_noihs
│   ├── hosts_kvm-018786_kvm-018785
│   │   ├── apply_ifix
│   │   ├── fresh_install
│   │   └── upgrade
│   └── hosts_kvm-018788_kvm-018787
│       ├── apply_ifix
│       ├── fresh_install
│       └── upgrade
└── singlenode
    ├── host_kvm-018784
    │   ├── apply_ifix
    │   ├── fresh_install
    │   └── upgrade
    └── host_kvm-018789
        ├── apply_ifix
        ├── fresh_install
        └── upgrade
</pre>
