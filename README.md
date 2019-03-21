# Workflow_Chef_Shell_Script

## Description

This script work with IBM Business Automation Workflow Cookbook project to automate IBM Business Automation Workflow Enterprise 

### Cookbook Supported
IBM Business Automation Workflow Cookbook Project Information: <br> 
Name: OpenContent/cookbook_ibm_workflow_multios <br>
URL: https://github.com/IBM-CAMHub-Open/cookbook_ibm_workflow_multios <br>
Version: version 2.0.4 <br>


### Single node 
This script work with IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise on a single host. <br> 

#### Single Node Topology:
Single host: IBM Business Automation Workflow Enterprise - Deployment Manager and Custom Node, one cluster member. <br>
#### Software Deployed
IBM WebSphere Application Server Network Deployment V8.5.5 <br>
IBM Business Automation Workflow Enterprise V18 <br>
IBM DB2 Enterprise Server Edition V11 <br>

#### Fresh install
Start to install and configure IBM Business Automation Workflow Enterprise on one single host. <br>

./singlenode/baw_singlenode_fresh_install.properties  <br>
./singlenode/baw_singlenode_fresh_install.sh  <br>
#### Upgrade
Start to upgrade IBM Business Automation Workflow Enterprise with fix packs on one single host. <br>

./singlenode/upgrade/baw_singlenode_upgrade.properties  <br>
./singlenode/upgrade/baw_singlenode_upgrade.sh  <br>
#### Apply interim fix
Start to apply interim fix packs to IBM Business Automation Workflow Enterprise on one single host. <br>

./singlenode/apply_ifix/baw_singlenode_apply_ifix.properties  <br>
./singlenode/apply_ifix/baw_singlenode_apply_ifix.sh  <br>

<br>


### Multinodes
This script work with IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise on two hosts. <br>

#### Multinodes Topology:
Host 1: IBM Business Automation Workflow Deployment Manager, Custom Node, one cluster member <br>
Host 2: IBM Business Automation Workflow Custom Node, one cluster member <br>
#### Software Deployed
IBM WebSphere Application Server Network Deployment V8.5.5 <br>
IBM Business Automation Workflow Enterprise V18 <br>

#### Fresh install
Start to install and configure IBM Business Automation Workflow Enterprise on two hosts.<br>

./multinodes/baw_multinodes_fresh_install.properties  <br>
./multinodes/baw_multinodes_fresh_install.sh  <br>
#### Upgrade
Start to upgrade IBM Business Automation Workflow Enterprise on two hosts.

./multinodes/upgrade/baw_multinodes_upgrade.properties  <br>
./multinodes/upgrade/baw_multinodes_upgrade.sh  <br>
#### Apply interim fix
Start to apply interim fix packs to IBM Business Automation Workflow Enterprise on two hosts. <br>

./multinodes/apply_ifix/baw_multinodes_apply_ifix.properties  <br>
./multinodes/apply_ifix/baw_multinodes_apply_ifix.sh  <br>

<br>

### The generated roles and logs

Notes: "kvm-018784, kvm-018785, kvm-018786, kvm-018787, kvm-018788, kvm-018789" are host short names  <br>

#### The roles generated directory structure
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

#### The logs generated directory structure

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