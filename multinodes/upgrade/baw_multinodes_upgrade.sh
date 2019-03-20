#!/bin/bash
# set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
#
# Operating Systems Supported
# Ubuntu 16.04 LTS; Ubuntu 18.04 LTS
#
# IBM Business Automation Workflow Cookbook Project, https://github.com/IBM-CAMHub-Open/cookbook_ibm_workflow_multios
#
# This script work with IBM Business Automation Workflow Cookbook project to upgrade IBM Business Automation Workflow Enterprise with fix packs on two hosts.

# Topology
# Host 1, Workflow01 or WF01: IBM Business Automation Workflow Deployment Manager (Dmgr), Custom Node, one cluster member
# Host 2, Workflow02 or WF02: IBM Business Automation Workflow Custom Node, one cluster member


Print_TopologyLogs () {

  echo
  echo "Logs for details are under $LOG_DIR directory"
  echo
  echo "The monitor"
  echo "  Log to $BAW_CHEF_LOG"
  echo
  echo "Topology"
  echo
  echo "  Host 1, Workflow01 or WF01: IBM Business Automation Workflow Deployment Manager (Dmgr), Custom Node, one cluster member,"
  echo "  Log to $WF01_LOG"
  echo
  echo "  Host 2, Workflow02 or WF02: IBM Business Automation Workflow Custom Node, one cluster member,"
  echo "  Log to $WF02_LOG"
  echo
}


# Upload all roles to the chef server
Upload_Roles () {

  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_UPGRADE_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_APPLYIFIX_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_POSTDEV_FILE || return 1

  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_UPGRADE_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_APPLYIFIX_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_POSTDEV_FILE
}


######## Define BAW multiple node installation dependency logic units #######

######## NODE Workflow01, WF01, step 1, 2 ########
WF01_step1 () {
  # sequential

  knife node run_list set $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_UPGRADE_NAME]" &&
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$WF01_ROLE_UPGRADE_NAME" -C "$WF01_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P "$WF01_ROOT_PW" >> $WF01_LOG &
  local TASK_WF01_UPGRADE=$!
  readonly TASK_WF01_UPGRADE
  Monitor 0 "$TASK_WF01_UPGRADE" "$LOG_WF01_NAME Upgrade(2 tasks left)" || return 1

  knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_APPLYIFIX_NAME]" &&
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$WF01_ROLE_APPLYIFIX_NAME" -C "$WF01_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P "$WF01_ROOT_PW" >> $WF01_LOG &
  local TASK_WF01_APPLYIFIX=$!
  readonly TASK_ WF01_APPLYIFIX
  Monitor 0 "$TASK_WF01_APPLYIFIX" "$LOG_WF01_NAME Applyifix(1 tasks left)" || return 1

  knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_POSTDEV_NAME]" &&
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P "$WF01_ROOT_PW" >> $WF01_LOG &
  local TASK_WF01_POSTDEV=$!
  readonly TASK_WF01_POSTDEV
  Monitor 0 "$TASK_WF01_POSTDEV" "$LOG_WF01_NAME Post Action(0 tasks left)"
}

WF01_step2 () {
  #   # sequential

  #   knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_POSTDEV_NAME]" &&
  #   knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P "$WF01_ROOT_PW" >> $WF01_LOG &
  #   local TASK_WF01_POSTDEV=$!
  #   readonly TASK_WF01_POSTDEV
  #   Monitor 0 "$TASK_WF01_POSTDEV" "$LOG_WF01_NAME Post Action(0 tasks left)"
  :
}


######## NODE Workflow02 WF02, step 1, 2 ########
WF02_step1 () {
  # sequential

  knife node run_list set $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_UPGRADE_NAME]" &&
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$WF02_ROLE_UPGRADE_NAME" -C "$WF02_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P "$WF02_ROOT_PW" >> $WF02_LOG &
  local TASK_WF02_UPGRADE=$!
  readonly TASK_WF02_UPGRADE
  Monitor 0 "$TASK_WF02_UPGRADE" "$LOG_WF02_NAME Upgrade(2 Tasks left)" || return 1

  knife node run_list add $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_APPLYIFIX_NAME]" &&
  knife vault update $BAW_CHEF_VAULT_NAME $BAW_CHEF_VAULT_ITEM -S "role:$WF02_ROLE_APPLYIFIX_NAME" -C "$WF02_ON_CHEF_SERVER" -M client || { echo "Error when updating chef vault"; return 1; }
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P "$WF02_ROOT_PW" >> $WF02_LOG &
  local TASK_WF02_APPLYIFIX=$!
  readonly TASK_WF02_APPLYIFIX
  Monitor 0 "$TASK_WF02_APPLYIFIX" "$LOG_WF02_NAME Applyifix(1 Task left)"
}

WF02_step2 () {
# sequential

  knife node run_list add $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_POSTDEV_NAME]" &&
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P "$WF02_ROOT_PW" >> $WF02_LOG &
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
  echo "$(date -Iseconds), MTASK: $LOG_WF01_NAME, there are 3 tasks to do: Upgrade, Applyifix, Post Action"

  WF02_step1 &
  tasks_baw_multinodes_install+=("$!")
  # echo "$(date -Iseconds), MTASK: $LOG_WF02_NAME Step 1 of 2 starts, TASKS List (Installation, Upgrade, Applyifix)"
  echo "$(date -Iseconds), MTASK: $LOG_WF02_NAME, there are 3 tasks to do: Upgrade, Applyifix, Post Action"
  echo

  # Monitor 1 "${tasks_baw_multinodes_install[*]}" "$LOG_WF01_NAME Step 1 of 2" "$LOG_WF02_NAME Step 1 of 2"
  Monitor 1 "${tasks_baw_multinodes_install[*]}"
}

  
######## Start the program ########
BAW_Multiple_Nodes_Chef_Start () {
# sequential

  Upload_Roles  || return 1
  Create_Chef_Vaults_WF01_WF02 || return 1
  BAW_Multiple_Nodes_Installation_Start
}

Main_Start () {

  echo
  echo "Start to upgrade IBM Business Automation Workflow Enterprise on two hosts."
  echo
  echo "Starting at: $(date -Iseconds)"
  echo

  Generate_Roles "upgrade_fixpack"

  ######## Prepare logs for nodes #######
  # $WF01_IP_ADDR depend on . "$MY_DIR/../libs/dynamic_roles_singlenode_script"
  # The name for WF01 in log printing
  LOG_WF01_NAME="Host_${var_Workflow01_name}($WF01_IP_ADDR), Workflow01"  
  readonly LOG_WF01_NAME
  # The name for WF02 in log printing
  LOG_WF02_NAME="Host_${var_Workflow02_name}($WF02_IP_ADDR), Workflow02"
  readonly LOG_WF02_NAME

  WF01_LOG="${LOG_DIR}/WF01_${var_Workflow01_name}_${WF01_IP_ADDR}_chef.log"
  readonly WF01_LOG
  WF02_LOG="${LOG_DIR}/WF02_${var_Workflow02_name}_${WF02_IP_ADDR}_chef.log"
  readonly WF02_LOG

  Print_TopologyLogs

  BAW_Multiple_Nodes_Chef_Start
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
  . "$MY_DIR/../../libs/dynamic_roles_multinodes_script" &&

    # The properties file path 
    readonly BAW_CHEF_PROPERTIES_DIR="$MY_DIR"
    # ./baw_singlenode.properties
    readonly BAW_CHEF_PROPERTIES_FILE="$BAW_CHEF_PROPERTIES_DIR/baw_multinodes_upgrade.properties"
    # Test if $BAW_CHEF_PROPERTIES_FILE exists 
    getValueFromPropFile $BAW_CHEF_PROPERTIES_FILE || return 1

    # "node_hostname": "kvm-018074.test.local",
    var_Workflow01_FQDN=$(getValueFromPropFile $BAW_CHEF_PROPERTIES_FILE workflow_host01_fqdn_name)
    var_Workflow01_name=$(echo $var_Workflow01_FQDN | cut -d '.' -f1)
    if [ ! -z $(echo $var_Workflow01_FQDN | grep '\.' ) ]
    then
      var_Workflow01_domain=$(echo $var_Workflow01_FQDN | cut -d '.' -f2-)
    fi

    # "node_hostname": "kvm-018075.test.local",
    var_Workflow02_FQDN=$(getValueFromPropFile $BAW_CHEF_PROPERTIES_FILE workflow_host02_fqdn_name)
    var_Workflow02_name=$(echo $var_Workflow02_FQDN | cut -d '.' -f1)
    if [ ! -z $(echo $var_Workflow02_FQDN | grep '\.' ) ]
    then
      var_Workflow02_domain=$(echo $var_Workflow02_FQDN | cut -d '.' -f2-)
    fi

    if [ ! -z "$var_Workflow01_name" -a ! -z "$var_Workflow01_domain" ]
    then
      if [ ! -z "$var_Workflow02_name" -a ! -z "$var_Workflow02_domain" ]
      then
        local_node_hostnames="$var_Workflow01_name.$var_Workflow01_domain,$var_Workflow02_name.$var_Workflow02_domain"
      else
        local_node_hostnames="$var_Workflow01_name.$var_Workflow01_domain"
      fi
    else
      local_node_hostnames="$var_Workflow02_name.$var_Workflow02_domain"
    fi

  # Reference to templates dir
  readonly BAW_CHEF_TMPL_DIR=$MY_DIR/../../templates

######## Prepare logs #######
# define where to log
readonly REQUESTED_LOG_DIR="/var/log/baw_chef_shell_log/multinodes_noihs/hosts_${var_Workflow01_name}_${var_Workflow02_name}/upgrade"
readonly LOG_DIR="$( Create_Dir $REQUESTED_LOG_DIR )"
# echo "BAW LOG Dir created $LOG_DIR"
readonly BAW_CHEF_LOG="${LOG_DIR}/Monitor_${var_Workflow01_name}_${var_Workflow02_name}.log"

  Main_Start 2>&1 | tee $BAW_CHEF_LOG  