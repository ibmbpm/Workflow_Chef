#!/bin/bash
# set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
#
# Operating Systems Supported
# Ubuntu 16.04 LTS; Ubuntu 18.04 LTS
#
# IBM Business Automation Workflow Cookbook Project, https://github.com/IBM-CAMHub-Open/cookbook_ibm_workflow_multios
#
# This script work with IBM Business Automation Workflow Cookbook project to deploy IBM Business Automation Workflow Enterprise on a single host. 

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
  
    knife role from file $BAW_CHEF_TEMP_DIR/$SNODE_ROLE_INSTALL_FILE || return 1
    knife role from file $BAW_CHEF_TEMP_DIR/$SNODE_ROLE_UPGRADE_FILE || return 1
    knife role from file $BAW_CHEF_TEMP_DIR/$SNODE_ROLE_APPLYIFIX_FILE || return 1
    knife role from file $BAW_CHEF_TEMP_DIR/$SNODE_ROLE_CONFIG_FILE || return 1
    knife role from file $BAW_CHEF_TEMP_DIR/$SNODE_ROLE_POSTDEV_FILE
}

# # Upload all roles to the chef server
# Upload_ALL_Roles_From_Dir () {

#     knife role from file $BAW_CHEF_TEMP_DIR/*
# }

######## Bootstrap first ########
Bootstrap () {
  # sequentia

  local task_bootstraps=( )

  knife bootstrap $SNODE_IP_ADDR -N $SNODE_ON_CHEF_SERVER -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" -y > $SNODE_LOG &
  local TASK_SNODE_BOOTSTRAP=$!
  readonly TASK_SNODE_BOOTSTRAP
  task_bootstraps+=("$TASK_SNODE_BOOTSTRAP")
  echo
  echo "$(date -Iseconds), MTASK: $LOG_SNODE_NAME Bootstrap starts"

  Monitor 0 "${task_bootstraps[*]}" "$LOG_SNODE_NAME Bootstrap"
}


Create_Chef_Vaults () {

  # Generate_CHEFVAULT 
  WORKFLOW_SECRETS_TMPL_FILE=$workflow_secrets_TMPL_FILE
  Auto_Create_WORKFLOW_SECRETS || return 1
  # RUNTIME_WORKFLOW_SECRETS_JSON

  if [ $( eval "knife vault list -M client | grep ^$BAW_CHEF_VAULT_NAME$" ) ]; then
    knife vault delete $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -M client -y 
  fi
  knife vault create $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM "$RUNTIME_WORKFLOW_SECRETS_JSON" -C "$SNODE_ON_CHEF_SERVER" -M client || { echo "Error when creating chef vault"; return 1; } 
}


######## BAW Installation ########
BAW_Single_Node_Installation_Start () {
  # sequential

  echo
  echo "$(date -Iseconds), MTASK: $LOG_SNODE_NAME, there are 5 tasks to do: Installation, Upgrade, Applyifix, Configuration, POST Action"

  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_INSTALL_NAME]" || return 1
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$SNODE_ROLE_INSTALL_NAME" -C "$SNODE_ON_CHEF_SERVER" -M client  2>/dev/null || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" >> $SNODE_LOG &
  local TASK_SNODE_INSTALL=$!
  readonly TASK_SNODE_INSTALL
  Monitor 0 "$TASK_SNODE_INSTALL" "$LOG_SNODE_NAME Installation ( 4 tasks left )" || return 1

  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_UPGRADE_NAME]" || return 1
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$SNODE_ROLE_UPGRADE_NAME" -C "$SNODE_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" >> $SNODE_LOG &
  local TASK_SNODE_UPGRADE=$!
  readonly TASK_SNODE_UPGRADE
  Monitor 0 "$TASK_SNODE_UPGRADE" "$LOG_SNODE_NAME Upgrade ( 3 tasks left )" || return 1

  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_APPLYIFIX_NAME]" || return 1
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$SNODE_ROLE_APPLYIFIX_NAME" -C "$SNODE_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" >> $SNODE_LOG || return 1
  local TASK_SNODE_APPLYIFIX=$!
  readonly TASK_ SNODE_APPLYIFIX
  Monitor 0 "$TASK_SNODE_APPLYIFIX" "$LOG_SNODE_NAME Applyifix ( 2 tasks left )" || return 1


  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_CONFIG_NAME]" || return 1
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$SNODE_ROLE_CONFIG_NAME" -C "$SNODE_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" >> $SNODE_LOG &
  local TASK_SNODE_CONFIG=$!
  readonly  TASK_SNODE_CONFIG
  Monitor 0 "$TASK_SNODE_CONFIG" "$LOG_SNODE_NAME Configuration ( 1 task left )" || return 1

  knife node run_list add $SNODE_ON_CHEF_SERVER "role[$SNODE_ROLE_POSTDEV_NAME]" || return 1
  knife ssh "name:$SNODE_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -x $SNODE_ROOT_USERNAME -P "$SNODE_ROOT_PW" >> $SNODE_LOG &
  local TASK_SNODE_POSTDEV=$!
  readonly TASK_SNODE_POSTDEV
  Monitor 0 "$TASK_SNODE_POSTDEV" "$LOG_SNODE_NAME Post Action ( 0 tasks left )"
}


######## Programs below ########

######## Include libs ########
MY_DIR=${0%/*}
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; readonly MY_DIR; fi
#echo current Dir is $MY_DIR


######## Start the program ########
BAW_Single_Nodes_Chef_Start () {

  Upload_Roles || return 1
  Bootstrap || return 1
  Create_Chef_Vaults || return 1
  BAW_Single_Node_Installation_Start
}

Main_Start () {

  echo
  echo "Start to install and configure IBM Business Automation Workflow Enterprise on one single host."
  echo
  echo "Starting at: $(date -Iseconds)"
  echo
  
  . "$MY_DIR/../libs/dynamic_roles_singlenode_script" &&

  ######## Prepare logs for nodes #######
  # The name for SNode in log printing
  # $SNODE_IP_ADDR depend on . "$MY_DIR/../libs/dynamic_roles_singlenode_script"
  LOG_SNODE_NAME="Single Host($SNODE_IP_ADDR), Workflow"  
  readonly LOG_SNODE_NAME
  SNODE_LOG="${LOG_DIR}/SNODE_${SNODE_IP_ADDR}_chef.log"
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

  . "$MY_DIR/../libs/utilities_script" &&
######## Prepare logs #######
# define where to log
readonly REQUESTED_LOG_DIR="/var/log/baw_singlenode_chef"
readonly LOG_DIR="$( Create_Dir $REQUESTED_LOG_DIR )"
# echo "BAW LOG Dir created $LOG_DIR"
readonly BAW_CHEF_LOG="${LOG_DIR}/BAW_CHEF_SHELL_SCRIPT.log"

 Main_Start 2>&1 | tee $BAW_CHEF_LOG