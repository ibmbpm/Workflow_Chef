#!/bin/bash
# set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
#
# Operating Systems Supported
# Ubuntu 16.04 LTS; Ubuntu 18.04 LTS
#
# IBM Business Automation Workflow Cookbook Project, https://github.com/IBM-CAMHub-Open/cookbook_ibm_workflow_multios
#
# This script work with IBM Business Automation Workflow Cookbook project to upgrade IBM Business Automation Workflow Enterprise with fix packs on a single host. 

# Topology
# Single host: IBM Business Automation Workflow Enterprise - Deployment Manager and Custom Node, one cluster member.


# Upload all roles to the chef server
Upload_Roles () {
  
    knife role from file $BAW_CHEF_TEMP_DIR/$SNODE_ROLE_UPGRADE_FILE || return 1
    knife role from file $BAW_CHEF_TEMP_DIR/$SNODE_ROLE_APPLYIFIX_FILE || return 1
    knife role from file $BAW_CHEF_TEMP_DIR/$SNODE_ROLE_POSTDEV_FILE
}


######## BAW Installation ########
BAW_Single_Node_Installation_Start () {
  # sequential

  echo
  echo "$(date -Iseconds), MTASK: $LOG_SNODE_NAME, there are 3 tasks to do: Upgrade, Applyifix, POST Action"

  knife node run_list set $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_UPGRADE_NAME]" || return 1
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$SNODE_ROLE_UPGRADE_NAME" -C "$SNODE_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" | Purification_Logs >> $SNODE_LOG &
  local TASK_SNODE_UPGRADE=$!
  readonly TASK_SNODE_UPGRADE
  Monitor 0 "$TASK_SNODE_UPGRADE" "$LOG_SNODE_NAME Upgrade(2 tasks left)" || return 1

  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_APPLYIFIX_NAME]" || return 1
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$SNODE_ROLE_APPLYIFIX_NAME" -C "$SNODE_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" | Purification_Logs >> $SNODE_LOG &
  local TASK_SNODE_APPLYIFIX=$!
  readonly TASK_SNODE_APPLYIFIX
  Monitor 0 "$TASK_SNODE_APPLYIFIX" "$LOG_SNODE_NAME Applyifix(1 task left)" || return 1

  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_POSTDEV_NAME]" || return 1
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" | Purification_Logs >> $SNODE_LOG &
  local TASK_SNODE_POSTDEV=$!
  readonly TASK_SNODE_POSTDEV
  Monitor 0 "$TASK_SNODE_POSTDEV" "$LOG_SNODE_NAME Post Action(0 tasks left)"
}


######## Start the program ########
BAW_Single_Nodes_Chef_Start () {

  Upload_Roles || return 1
  Create_Chef_Vaults_Singlenode || return 1
  BAW_Single_Node_Installation_Start
}

Main_Start () {

  echo
  echo
  Print_Start_Flag
  echo "Start to upgrade IBM Business Automation Workflow Enterprise with fix packs on one single host."
  echo
  
  Generate_Roles "upgrade_fixpack" || return 1

  ######## Prepare logs for nodes #######
  # The name for SNode in log printing
  # $SNODE_IP_ADDR depend on . "$MY_DIR/../libs/dynamic_roles_singlenode_script"
  LOG_SNODE_NAME="Host_${var_Workflow01_name}($SNODE_IP_ADDR), Workflow"  
  readonly LOG_SNODE_NAME
  SNODE_LOG="${LOG_DIR}/wf_${var_Workflow01_name}_${SNODE_IP_ADDR}_chef.log"
  readonly SNODE_LOG

  echo  >> $SNODE_LOG
  Print_Start_Flag >> $SNODE_LOG

  Print_TopologyLogs_Singlenode

  BAW_Single_Nodes_Chef_Start 
  Print_Main_Exist_Status "$?" || return 1

  Print_End_Flag >> $SNODE_LOG
  
  Print_TopologyLogs_Singlenode

  echo
  Print_End_Flag
  echo
  echo
}


######## Programs below ########

######## Include libs ########
MY_DIR=${0%/*}
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; readonly MY_DIR; fi
#echo current Dir is $MY_DIR

  . "$MY_DIR/../../libs/utilities_script" &&
  . "$MY_DIR/../../libs/dynamic_roles_script"  &&
  . "$MY_DIR/../../libs/dynamic_roles_singlenode_script" &&

  # Reference to properties dir
  readonly BAW_CHEF_PROPERTIES_DIR="$MY_DIR"
  # ./baw_singlenode.properties
  readonly BAW_CHEF_PROPERTIES_FILE="$BAW_CHEF_PROPERTIES_DIR/baw_singlenode_upgrade.properties"
  # Test if $BAW_CHEF_PROPERTIES_FILE exists 
  getValueFromPropFile $BAW_CHEF_PROPERTIES_FILE || exit 1

  Load_Host_Name_Singlenode || exit 1

  # Reference to templates dir
  readonly BAW_CHEF_TMPL_DIR=$MY_DIR/../../templates

######## Prepare logs #######
# define where to log
readonly REQUESTED_LOG_DIR="/var/log/baw_chef_shell_log/singlenode/host_${var_Workflow01_name}/upgrade"
readonly LOG_DIR="$( Create_Dir $REQUESTED_LOG_DIR )"
# echo "BAW LOG Dir created $LOG_DIR"
readonly BAW_CHEF_LOG="${LOG_DIR}/monitor_${var_Workflow01_name}.log"

 Main_Start 2>&1 | tee -a $BAW_CHEF_LOG