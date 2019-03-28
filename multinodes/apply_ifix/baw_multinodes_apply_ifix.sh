#!/bin/bash
# set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
#
# Operating Systems Supported
# Ubuntu 16.04 LTS; Ubuntu 18.04 LTS
#
# IBM Business Automation Workflow Cookbook Project, https://github.com/IBM-CAMHub-Open/cookbook_ibm_workflow_multios
#
# This script work with IBM Business Automation Workflow Cookbook project to apply interim fix packs to IBM Business Automation Workflow Enterprise on two hosts.

# Topology
# Host 1, Workflow01 or WF01: IBM Business Automation Workflow Deployment Manager (Dmgr), Custom Node, one cluster member
# Host 2, Workflow02 or WF02: IBM Business Automation Workflow Custom Node, one cluster member


# Upload all roles to the chef server
Upload_Roles () {

  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_APPLYIFIX_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_POSTDEV_FILE || return 1

  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_APPLYIFIX_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_POSTDEV_FILE
}


######## Define BAW multiple node installation dependency logic units #######

######## NODE Workflow01, WF01, step 1, 2 ########
WF01_step1 () {
  # sequential


  knife node run_list set $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_APPLYIFIX_NAME]" &&
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$WF01_ROLE_APPLYIFIX_NAME" -C "$WF01_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -P "$WF01_ROOT_PW" | Purification_Logs >> $WF01_LOG &
  local TASK_WF01_APPLYIFIX=$!
  readonly TASK_WF01_APPLYIFIX
  Monitor 0 "$TASK_WF01_APPLYIFIX" "$LOG_WF01_NAME Applyifix(1 task left)" || return 1

  knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_POSTDEV_NAME]" &&
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -P "$WF01_ROOT_PW" | Purification_Logs >> $WF01_LOG &
  local TASK_WF01_POSTDEV=$!
  readonly TASK_WF01_POSTDEV
  Monitor 0 "$TASK_WF01_POSTDEV" "$LOG_WF01_NAME Post Action(0 tasks left)"
}

WF01_step2 () {
  # sequential

  # knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_WEBSERVER]" &&
  # knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -P "$WF01_ROOT_PW" | Purification_Logs >> $WF01_LOG &
  # local TASK_WF01_WEBSERVER=$!
  # readonly TASK_WF01_WEBSERVER
  # Monitor 0 "$TASK_WF01_WEBSERVER" "$LOG_WF01_NAME Configure Web Server" || return 1

  # knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_POSTDEV_NAME]" &&
  # knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -P "$WF01_ROOT_PW" | Purification_Logs >> $WF01_LOG &
  # local TASK_WF01_POSTDEV=$!
  # readonly TASK_WF01_POSTDEV
  # Monitor 0 "$TASK_WF01_POSTDEV" "$LOG_WF01_NAME Post Action(0 tasks left)"
  :
}


######## NODE Workflow02 WF02, step 1, 2 ########
WF02_step1 () {
  # sequential

  knife node run_list set $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_APPLYIFIX_NAME]" &&
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$WF02_ROLE_APPLYIFIX_NAME" -C "$WF02_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -P "$WF02_ROOT_PW" | Purification_Logs >> $WF02_LOG &
  local TASK_WF02_APPLYIFIX=$!
  readonly TASK_WF02_APPLYIFIX
  Monitor 0 "$TASK_WF02_APPLYIFIX" "$LOG_WF02_NAME Applyifix(1 task left)"
}

WF02_step2 () {
# sequential

  knife node run_list add $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_POSTDEV_NAME]" &&
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client -l info -L $LOCAL_CHEF_CLIENT_LOG" -P "$WF02_ROOT_PW"  | Purification_Logs >> $WF02_LOG &
  local TASK_WF02_POSTDEV=$!
  readonly TASK_WF02_POSTDEV
  Monitor 0 "$TASK_WF02_POSTDEV" "$LOG_WF02_NAME Post Action(0 tasks left)"
}


######## BAW Installation, WF01, WF02 ########
BAW_Multiple_Nodes_Installation_Start () {
# parallel

  local tasks_baw_multinodes_install=()

  WF01_step1 &
  tasks_baw_multinodes_install+=("$!")
  echo
  # echo "$(date -Iseconds), MTASK: $LOG_WF01_NAME Step 1 of 2 starts, TASKS List (Installation, Upgrade, Applyifix, Configuration)"
  echo "$(date -Iseconds), MTASK: $LOG_WF01_NAME, there are 2 tasks to do: Applyifix, Post Action"

  WF02_step1 &
  tasks_baw_multinodes_install+=("$!")
  # echo "$(date -Iseconds), MTASK: $LOG_WF02_NAME Step 1 of 2 starts, TASKS List (Installation, Upgrade, Applyifix)"
  echo "$(date -Iseconds), MTASK: $LOG_WF02_NAME, there are 2 tasks to do: Applyifix, Post Action"
  echo

  # Monitor 1 "${tasks_baw_multinodes_install[*]}" "$LOG_WF01_NAME Step 1 of 2" "$LOG_WF02_NAME Step 1 of 2"
  Monitor 1 "${tasks_baw_multinodes_install[*]}"
}

  
######## Start the program ########
BAW_Multiple_Nodes_Chef_Start () {
# sequential

  Upload_Roles  || return 1
  Create_Chef_Vaults_Multinodes || return 1
  BAW_Multiple_Nodes_Installation_Start
}

Main_Start () {

  echo
  echo "Start to apply interim fix packs to IBM Business Automation Workflow Enterprise on two hosts."
  echo
  echo "BAW Chef Shell Starting at: $(date -Iseconds)"
  echo

  Generate_Roles "apply_ifix" || return 1

  ######## Prepare logs for nodes #######
  # $WF01_IP_ADDR depend on . "$MY_DIR/../libs/dynamic_roles_singlenode_script"
  # The name for WF01 in log printing
  LOG_WF01_NAME="Host_${var_Workflow01_name}($WF01_IP_ADDR), Workflow01"  
  readonly LOG_WF01_NAME
  # The name for WF02 in log printing
  LOG_WF02_NAME="Host_${var_Workflow02_name}($WF02_IP_ADDR), Workflow02"
  readonly LOG_WF02_NAME

  WF01_LOG="${LOG_DIR}/wf01_${var_Workflow01_name}_${WF01_IP_ADDR}_chef.log"
  readonly WF01_LOG
  WF02_LOG="${LOG_DIR}/wf02_${var_Workflow02_name}_${WF02_IP_ADDR}_chef.log"
  readonly WF02_LOG

  echo  >> $WF01_LOG
  echo "BAW Chef Shell Starting at: $(date -Iseconds)" >> $WF01_LOG
  echo  >> $WF02_LOG
  echo "BAW Chef Shell Starting at: $(date -Iseconds)" >> $WF02_LOG

  Print_TopologyLogs_Multinodes

  BAW_Multiple_Nodes_Chef_Start
  local task_main_exit_status=$?

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

  echo "BAW Chef Shell Done at: $(date -Iseconds)" >> $WF01_LOG
  echo "BAW Chef Shell Done at: $(date -Iseconds)" >> $WF02_LOG
  
  Print_TopologyLogs_Multinodes

  echo
  echo "BAW Chef Shell Done at: $(date -Iseconds)"
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
  . "$MY_DIR/../../libs/dynamic_roles_multinodes_script" &&

  # The properties file path 
  readonly BAW_CHEF_PROPERTIES_DIR="$MY_DIR"
  # ./baw_singlenode.properties
  readonly BAW_CHEF_PROPERTIES_FILE="$BAW_CHEF_PROPERTIES_DIR/baw_multinodes_apply_ifix.properties"
  # Test if $BAW_CHEF_PROPERTIES_FILE exists 
  getValueFromPropFile $BAW_CHEF_PROPERTIES_FILE || exit 1

  Load_Host_Name_Multinodes || exit 1

  # Reference to templates dir
  readonly BAW_CHEF_TMPL_DIR=$MY_DIR/../../templates

######## Prepare logs #######
# define where to log
readonly REQUESTED_LOG_DIR="/var/log/baw_chef_shell_log/multinodes_noihs/hosts_${var_Workflow01_name}_${var_Workflow02_name}/apply_ifix"
readonly LOG_DIR="$( Create_Dir $REQUESTED_LOG_DIR )"
# echo "BAW LOG Dir created $LOG_DIR"
readonly BAW_CHEF_LOG="${LOG_DIR}/monitor_${var_Workflow01_name}_${var_Workflow02_name}.log"

  Main_Start 2>&1 | tee -a $BAW_CHEF_LOG  