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


Print_TopologyLogs () {

  echo
  echo "Logs for details are under $LOG_DIR directory"
  echo
  echo "The monitor"
  echo "  Log to $BAW_CHEF_LOG"
  echo
  echo "Topology"
  echo
  echo "  Single Host: IBM Business Automation Workflow Enterprise - Deployment Manager and Custom Node, one cluster member."
  echo "  Log to $SNODE_LOG"
  echo
}


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
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" >> $SNODE_LOG &
  local TASK_SNODE_UPGRADE=$!
  readonly TASK_SNODE_UPGRADE
  Monitor 0 "$TASK_SNODE_UPGRADE" "$LOG_SNODE_NAME Upgrade(2 tasks left)" || return 1

  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_APPLYIFIX_NAME]" || return 1
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$SNODE_ROLE_APPLYIFIX_NAME" -C "$SNODE_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" >> $SNODE_LOG &
  local TASK_SNODE_APPLYIFIX=$!
  readonly TASK_ SNODE_APPLYIFIX
  Monitor 0 "$TASK_SNODE_APPLYIFIX" "$LOG_SNODE_NAME Applyifix(1 task left)" || return 1

  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_POSTDEV_NAME]" || return 1
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" >> $SNODE_LOG &
  local TASK_SNODE_POSTDEV=$!
  readonly TASK_SNODE_POSTDEV
  Monitor 0 "$TASK_SNODE_POSTDEV" "$LOG_SNODE_NAME Post Action(0 tasks left)"
}


######## Start the program ########
BAW_Single_Nodes_Chef_Start () {

  Upload_Roles || return 1
  Create_Chef_Vaults_SNode || return 1
  BAW_Single_Node_Installation_Start
}

Main_Start () {

  echo
  echo "Start to upgrade IBM Business Automation Workflow Enterprise with fix packs on one single host."
  echo
  echo "Starting at: $(date -Iseconds)"
  echo
  
  Generate_Roles "upgrade_fixpack"

  ######## Prepare logs for nodes #######
  # The name for SNode in log printing
  # $SNODE_IP_ADDR depend on . "$MY_DIR/../libs/dynamic_roles_singlenode_script"
  LOG_SNODE_NAME="Host_${var_Workflow01_name}($SNODE_IP_ADDR), Workflow"  
  readonly LOG_SNODE_NAME
  SNODE_LOG="${LOG_DIR}/WF_${var_Workflow01_name}_${WF01_IP_ADDR}_chef.log"
  readonly SNODE_LOG

  Print_TopologyLogs

  BAW_Single_Nodes_Chef_Start 
  local task_main_exit_status=$?

  echo
  echo "Done at: $(date -Iseconds)"
  echo

  if [ $task_main_exit_status -eq 0 ]
  then
      echo
      echo "All Tasks Complete successfully."
      echo
  else
      echo
      echo "Failed, There may be errors occurred."
      echo
  fi

  Print_TopologyLogs
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
  getValueFromPropFile $BAW_CHEF_PROPERTIES_FILE || return 1

  # Get basic info
  var_Workflow01_FQDN=$(getValueFromPropFile $BAW_CHEF_PROPERTIES_FILE workflow_host01_fqdn_name)
  var_Workflow01_name=$(echo $var_Workflow01_FQDN | cut -d '.' -f1)

  # Reference to templates dir
  readonly BAW_CHEF_TMPL_DIR=$MY_DIR/../../templates

######## Prepare logs #######
# define where to log
readonly REQUESTED_LOG_DIR="/var/log/baw_chef_shell_log/singlenode/host_${var_Workflow01_name}/upgrade"
readonly LOG_DIR="$( Create_Dir $REQUESTED_LOG_DIR )"
# echo "BAW LOG Dir created $LOG_DIR"
readonly BAW_CHEF_LOG="${LOG_DIR}/Monitor_${var_Workflow01_name}.log"

 Main_Start 2>&1 | tee $BAW_CHEF_LOG