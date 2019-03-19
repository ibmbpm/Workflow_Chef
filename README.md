# Workflow_Chef_Shell_Script

## Description

This script work with IBM Business Automation Workflow Cookbook project to automate IBM Business Automation Workflow Enterprise 

### Cookbook Supported
IBM Business Automation Workflow Cookbook Project Information: <br> 
Name: OpenContent/cookbook_ibm_workflow_multios <br>
URL: https://github.ibm.com/OpenContent/cookbook_ibm_workflow_multios <br>
Version: version 2.1, 2.2 <br>


### Single node 
#### Fresh install
baw_chef_shellscript/singlenode/baw_singlenode_fresh_install.sh
#### Single Node Topology:
  Single host: IBM Business Automation Workflow Enterprise - Deployment Manager and Custom Node, one cluster member.<br>
#### Software Deployed
IBM WebSphere Application Server Network Deployment V8.5.5 <br>
IBM Business Automation Workflow Enterprise V18 or V19.0 <br>
IBM DB2 Enterprise Server Edition V11 <br>
<br>


### Multinodes
#### Fresh install
baw_chef_shellscript/multinodes/baw_multinodes_fresh_install.sh
#### Multinodes Topology:
Host 1: IBM Business Automation Workflow Deployment Manager, Custom Node, one cluster member <br>
Host 2: IBM Business Automation Workflow Custom Node, one cluster member <br>
#### Software Deployed
IBM WebSphere Application Server Network Deployment V8.5.5 <br>
IBM Business Automation Workflow Enterprise V18 or V19.0 <br>
<br>