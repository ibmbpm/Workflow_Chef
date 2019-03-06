#!/bin/bash
# set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
#
# Operating Systems Supported
# Ubuntu 16.04 LTS; Ubuntu 18.04 LTS
#
# This script deploys IBM Business Automation Workflow Enterprise V18 on two nodes.

# Topology
# Node 1, or WF01: IBM Business Automation Workflow Deployment Manager (Dmgr), Custom Node, one cluster member (Workflow01)
# Node 2, or WF02: IBM Business Automation Workflow Custom Node, one cluster member (Workflow02)


# Generate temporary dir (do not delete it by this program)
Create_Log_Dir () {

  local i=0 # The times which attempt to create temporary dir 
  local logdir=

  while ((++i <= 10)); do
  logdir=${LOG_DIR:="/var/log/baw_multinodes_noihs_chef/"}
  mkdir -m 755 -p "$LOG_DIR" 2>/dev/null && break
  done

  if ((i > 10)); then
  printf 'Could not create Log directory\n' >&2
  exit 1
  fi

  # echo "Log directory $logdir created"
}


Print_TopologyLogs () {

  echo
  echo "Logs for details are under $LOG_DIR directory"
  echo
  echo "The monitor"
  echo "  Log to $BAW_CHEF_LOG"
  echo
  echo "Topology"
  echo
  echo "  Node 1, Workflow01 or WF01: IBM Business Automation Workflow Deployment Manager (Dmgr), Custom Node, one cluster member,"
  echo "  Log to $WF01_LOG"
  echo
  echo "  Node 2, Workflow02 or WF02: IBM Business Automation Workflow Custom Node, one cluster member,"
  echo "  Log to $WF02_LOG"
  echo
}


# Upload all roles to the chef server
Upload_Roles () {

  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_INSTALL_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_UPGRADE_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_APPLYIFIX_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_CONFIG_FILE|| return 1
  # knife role from file $WF01_ROLE_WEBSERVER.json &&
  knife role from file $BAW_CHEF_TEMP_DIR/$WF01_ROLE_POSTDEV_FILE || return 1

  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_INSTALL_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_UPGRADE_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_APPLYIFIX_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_CONFIG_FILE || return 1
  knife role from file $BAW_CHEF_TEMP_DIR/$WF02_ROLE_POSTDEV_FILE
}

######## Monitor ########
Monitor () {

# $1: switch for enabling baw dependency logic, 0 for disable, others for enable 
# $2: tasks, an array including all task pids. tasks=( task1, task2, task3, ... ). 
# $3: the name of the task1, string
# $4: the name of the task2, string
# $5: the name of the task3, string

  local enable_baw_boolean=$1
  local tasks=( $2 )
  local task_tags=( $2 )
  local task1_name=$3
  local task2_name=$4
  local task3_name=$5

  local sleep_time=10
  local TOTAL_TASK_NU=${#tasks[*]}
  readonly TOTAL_TASK_NU

  # Define some tags to mark the exit status for each task
  local default_status=9999
  local task1_exit_status=$default_status
  local task2_exit_status=$default_status
  local task3_exit_status=$default_status

  # Define boolean tags to ensure each execute only once
  local trigger1=0
  local trigger2=0
  local trigger3=0

  local tasks_do_next_remaining=()

  while (( ${#task_tags[*]} )); do
     # echo Remaining tasks: "${task_tags[*]}"
      for tb in ${tasks[@]}; do
        if [ -n "$(ps -p $tb -o pid=)" ]; then
          case "$tb" in
            "${tasks[0]}") echo $(date -Iseconds), TASK: $task1_name with pid $tb, is still doing
            ;;
            "${tasks[1]}") echo $(date -Iseconds), TASK: $task2_name with pid $tb, is still doing
            ;;
            "${tasks[2]}") echo $(date -Iseconds), TASK: $task3_name with pid $tb, is still doing
            ;;
          esac
        else
            case "$tb" in
              "${tasks[0]}")
                 if [ -n "$(echo ${task_tags[*]} | grep $tb)" ]; then
                   # echo
                   # echo TASK: $task1_name with pid $tb exited, checking its exit status
                   unset "task_tags[0]"
                   wait $tb
                   task1_exit_status=$?
                   if [ $task1_exit_status -eq 0 ]; then
                     echo
                     echo $(date -Iseconds), SUCCESS: $task1_name with pid $tb was done successfully
                     echo
                   else
                     echo
                     echo $(date -Iseconds), ERROR: $task1_name with pid $tb error, with status $task1_exit_status.
                     echo
                   fi
                 fi
              ;;
              "${tasks[1]}")
                  if [ -n "$(echo ${task_tags[*]} | grep $tb)" ]; then
                    # echo
                    # echo TASK: $task2_name with pid $tb exited, checking its exit status
                    unset "task_tags[1]"
                    wait $tb
                    task2_exit_status=$?
                    if [ $task2_exit_status -eq 0 ]; then
                      echo
                      echo "$(date -Iseconds), SUCCESS: $task2_name with pid $tb was done successfully"
                      echo
                    else
                      echo
                      echo $(date -Iseconds), ERROR: $task2_name with pid $tb error occurred, with status $task2_exit_status.
                      echo
                    fi
                  fi
              ;;
              "${tasks[2]}")
                  if [ -n "$(echo ${task_tags[*]} | grep $tb)" ]; then
                    # echo TASK: $task3_name with pid $tb exited, checking its exit status
                    unset "task_tags[2]"
                    wait $tb
                    task3_exit_status=$?
                   if [ $task3_exit_status -eq 0 ]; then
                     echo
                     echo "$(date -Iseconds), SUCCESS: $task3_name with pid $tb was done successfully"
                     echo
                   else
                     echo
                     echo $(date -Iseconds), ERROR: $task3_name with pid $tb error, with status $task3_exit_status.
                     echo
                   fi
                 fi
              ;;
          esac
        fi
      done
      # When enable_baw_boolean is not 0, check the dependency for BAW
      # if [ $enable_baw_boolean -ne 0  -a $total_task_nu -ge 2 ]; then
      if [ $enable_baw_boolean -ne 0 ]; then
        # echo BAW dependency logic is enabled
        Monitor_Do_Next_Tasks
      fi
      sleep $sleep_time
  done

    # Return 1 when any one of them failed
    case $TOTAL_TASK_NU in
    1)
      if [ $task1_exit_status -eq 0 ]; then
        return 0
        else
        return 1
      fi
    ;;
    2)
      if [ $task1_exit_status -eq 0 -a $task2_exit_status -eq 0 ]; then
        return 0
        else
        return 1
      fi
    ;;
    3)
      if [ $task1_exit_status -eq 0 -a $task2_exit_status -eq 0 -a $task3_exit_status -eq 0 ]; then
        return 0
        else
        return 1
      fi
    ;;
  esac
}

# When enable_baw_boolean is not 0, check the dependency for BAW
Monitor_Do_Next_Tasks () {
  # tasks_do_next_remaining=() # this var was moved to upper function
  case $TOTAL_TASK_NU in
    2)
      # parallel
      # WF01 step 2 depends on WF01 step 1 ("role[$WF01_ROLE_CONFIG_NAME]") complete
      if [ $trigger1 -eq 0 -a $task1_exit_status -eq 0 ]; then
        echo
        echo "$(date -Iseconds), MTASK: $LOG_WF01_NAME Step 2 of 2 starts, TASKS LIST: (Post Action)"
        echo
        WF01_step2 &
        local TASK_WF01_step2=$!
        readonly TASK_WF01_step2&
        tasks_do_next_remaining+=("$TASK_WF01_step2")
        trigger1=1
      fi

      # WF02 step 2 depends on WF02 step 1 "role[$WF02_ROLE_APPLYIFIX]" and WF01 step 1 ("role[$WF01_ROLE_CONFIG_NAME]") complete
      if [ $trigger2 -eq 0 -a $task2_exit_status -eq 0 -a $task1_exit_status -eq 0 ]; then
        echo
        echo "$(date -Iseconds), MTASK: $LOG_WF02_NAME Step 2 of 2 starts, TASKS List (Configuration, Post Action)"
        echo
        WF02_step2 &
        local TASK_WF02_step2=$!
        readonly TASK_WF02_step2&
        tasks_do_next_remaining+=("$TASK_WF02_step2")
        trigger2=1
      fi

      # Checking the all the remaining tasks complete before exit
      if [ $trigger3 -eq 0 -a $task1_exit_status -ne $default_status -a $task2_exit_status -ne $default_status ]; then
        #echo MTASK: # Checking the all the remaining tasks complete before exit
        Monitor 0 "${tasks_do_next_remaining[*]}" "$LOG_WF01_NAME Step 2 of 2" "$LOG_WF02_NAME Step 2 of 2" || return 1
        trigger3=1
      fi
    ;;
    3)
      # WF01 step 2 depends on IHS ("role[$IHS_ROLE_CONFIG]") complete
      if [ $trigger1 -eq 0 -a $task1_exit_status -eq 0 -a $task3_exit_status -eq 0 ]; then
        echo
        echo "$(date -Iseconds), MTASK: $LOG_WF01_NAME Step 2 of 2 starts, TASKS LIST: (Configure Web Server, Post Action)"
        echo
        WF01_step2 &
        local TASK_WF01_step2=$!
        readonly TASK_WF01_step2&
        tasks_do_next_remaining+=("$TASK_WF01_step2")
        trigger1=1
      fi

      # WF02 step 2 depends on WF01 step 1 ("role[$WF01_ROLE_CONFIG_NAME]") complete
      if [ $trigger2 -eq 0 -a $task2_exit_status -eq 0 -a $task1_exit_status -eq 0 ]; then
        echo
        echo "$(date -Iseconds), MTASK: $LOG_WF02_NAME Step 2 of 2 starts, TASKS List (Configuration, Post Action)"
        echo
        WF02_step2 &
        local TASK_WF02_step2=$!
        readonly TASK_WF02_step2&
        tasks_do_next_remaining+=("$TASK_WF02_step2")
        trigger2=1
      fi

      # Checking the all the remaining tasks complete before exit
      if [ $trigger3 -eq 0 -a $task1_exit_status -ne $default_status -a $task2_exit_status -ne $default_status -a $task3_exit_status -ne $default_status ]; then
        # echo "MTASK: Checking the last tasks before exit"
        Monitor 0 "${tasks_do_next_remaining[*]}" "$LOG_WF01_NAME Step 2 of 2" "$LOG_WF02_NAME Step 2 of 2" || return 1
        trigger3=1
      fi
    ;;
  esac
}


######## Bootstrap all nodes first ########
Bootstrap () {
  # parallel

  local task_bootstraps=( )

  knife bootstrap $WF01_IP_ADDR -N $WF01_ON_CHEF_SERVER -P $WF01_ROOT_PW -y > $WF01_LOG &
  local TASK_WF01_BOOTSTRAP=$!
  readonly TASK_WF01_BOOTSTRAP
  task_bootstraps+=("$TASK_WF01_BOOTSTRAP")
  echo
  echo "$(date -Iseconds), MTASK: $LOG_WF01_NAME Bootstrap starts"

  knife bootstrap $WF02_IP_ADDR -N $WF02_ON_CHEF_SERVER -P $WF02_ROOT_PW -y > $WF02_LOG  &
  local TASK_WF02_BOOTSTRAP=$!
  readonly TASK_WF02_BOOTSTRAP
  task_bootstraps+=("$TASK_WF02_BOOTSTRAP")
  echo "$(date -Iseconds), MTASK: $LOG_WF02_NAME Bootstrap starts"
  echo

  Monitor 0 "${task_bootstraps[*]}" "$LOG_WF01_NAME Bootstrap" "$LOG_WF02_NAME Bootstrap"
}


######## Define BAW multiple node installation dependency logic units #######

######## NODE Workflow01, WF01, step 1, 2 ########
WF01_step1 () {
  # sequential

  knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_INSTALL_NAME]" &&
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF01_ROOT_PW >> $WF01_LOG &
  local TASK_WF01_INSTALL=$!
  readonly TASK_WF01_INSTALL
  Monitor 0 "$TASK_WF01_INSTALL" "$LOG_WF01_NAME Installation" || return 1

  knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_UPGRADE_NAME]" &&
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF01_ROOT_PW >> $WF01_LOG &
  local TASK_WF01_UPGRADE=$!
  readonly TASK_WF01_UPGRADE
  Monitor 0 "$TASK_WF01_UPGRADE" "$LOG_WF01_NAME Upgrade" || return 1

  knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_APPLYIFIX_NAME]" &&
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF01_ROOT_PW >> $WF01_LOG &
  local TASK_WF01_APPLYIFIX=$!
  readonly TASK_ WF01_APPLYIFIX
  Monitor 0 "$TASK_WF01_APPLYIFIX" "$LOG_WF01_NAME Applyifix" || return 1

  knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_CONFIG_NAME]" &&
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF01_ROOT_PW >> $WF01_LOG &
  local TASK_WF01_CONFIG=$!
  readonly  TASK_WF01_CONFIG
  Monitor 0 "$TASK_WF01_CONFIG" "$LOG_WF01_NAME Configuration"
}

WF01_step2 () {
  # sequential

  # knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_WEBSERVER]" &&
  # knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF01_ROOT_PW >> $WF01_LOG &
  # local TASK_WF01_WEBSERVER=$!
  # readonly TASK_WF01_WEBSERVER
  # Monitor 0 "$TASK_WF01_WEBSERVER" "$LOG_WF01_NAME Configure Web Server" || return 1

  knife node run_list add $WF01_ON_CHEF_SERVER "role[$WF01_ROLE_POSTDEV_NAME]" &&
  knife ssh "name:$WF01_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF01_ROOT_PW >> $WF01_LOG &
  local TASK_WF01_POSTDEV=$!
  readonly TASK_WF01_POSTDEV
  Monitor 0 "$TASK_WF01_POSTDEV" "$LOG_WF01_NAME Post Action"
}


######## NODE Workflow02 WF02, step 1, 2 ########
WF02_step1 () {
  # sequential

  knife node run_list add $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_INSTALL_NAME]" &&
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF02_ROOT_PW >> $WF02_LOG &
  local TASK_WF02_INSTALL=$!
  readonly TASK_WF02_INSTALL
  Monitor 0 "$TASK_WF02_INSTALL" "$LOG_WF02_NAME Installation" || return 1

  knife node run_list add $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_UPGRADE_NAME]" &&
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF02_ROOT_PW >> $WF02_LOG &
  local TASK_WF02_UPGRADE=$!
  readonly TASK_WF02_UPGRADE
  Monitor 0 "$TASK_WF02_UPGRADE" "$LOG_WF02_NAME Upgrade" || return 1

  knife node run_list add $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_APPLYIFIX_NAME]" &&
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF02_ROOT_PW >> $WF02_LOG &
  local TASK_WF02_APPLYIFIX=$!
  readonly TASK_WF02_APPLYIFIX
  Monitor 0 "$TASK_WF02_APPLYIFIX" "$LOG_WF02_NAME Applyifix"
}

WF02_step2 () {
# sequential

  knife node run_list add $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_CONFIG_NAME]" &&
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF02_ROOT_PW >> $WF02_LOG &
  local TASK_WF02_CONFIG=$!
  readonly  TASK_WF02_CONFIG
  Monitor 0 "$TASK_WF02_CONFIG" "$LOG_WF02_NAME Configuration" || return 1

  knife node run_list add $WF02_ON_CHEF_SERVER "role[$WF02_ROLE_POSTDEV_NAME]" &&
  knife ssh "name:$WF02_ON_CHEF_SERVER" -a ipaddress "sudo chef-client" -P $WF02_ROOT_PW >> $WF02_LOG &
  local TASK_WF02_POSTDEV=$!
  readonly TASK_WF02_POSTDEV
  Monitor 0 "$TASK_WF02_POSTDEV" "$LOG_WF02_NAME Post Action"
}


######## BAW Installation, WF01, WF02 ########
BAW_Multiple_Nodes_Installation_Start () {
# parallel

  local tasks_baw_multinodes_install=()

  WF01_step1 &
  tasks_baw_multinodes_install+=("$!")
  echo
  echo "$(date -Iseconds), MTASK: $LOG_WF01_NAME Step 1 of 2 starts, TASKS List (Installation, Upgrade, Applyifix, Configuration)"

  WF02_step1 &
  tasks_baw_multinodes_install+=("$!")
  echo "$(date -Iseconds), MTASK: $LOG_WF02_NAME Step 1 of 2 starts, TASKS List (Installation, Upgrade, Applyifix)"
  echo

  Monitor 1 "${tasks_baw_multinodes_install[*]}" "$LOG_WF01_NAME Step 1 of 2" "$LOG_WF02_NAME Step 1 of 2"
}


######## Programs below ########

######## Include libs ########
MY_DIR=${0%/*}
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; readonly MY_DIR; fi
#echo current Dir is $MY_DIR


######## Start the program ########
BAW_Multiple_Nodes_Chef_Start () {
# sequential

  Upload_Roles  || return 1
  Bootstrap  || return 1
  BAW_Multiple_Nodes_Installation_Start
}

Main_Start () {

  echo
  echo "Start to install and configure IBM Business Automation Workflow Enterprise V18 on two nodes."
  echo
  echo "Starting at: $(date -Iseconds)"
  echo

  . "$MY_DIR/../libs/dynamic_roles_multinodes_script" &&

  ######## Prepare logs for nodes #######
  # $WF01_IP_ADDR depend on . "$MY_DIR/../libs/dynamic_roles_singlenode_script"
  # The name for WF01 in log printing
  LOG_WF01_NAME="Node Workflow01 ($WF01_IP_ADDR)"  
  readonly LOG_WF01_NAME
  # The name for WF02 in log printing
  LOG_WF02_NAME="Node Workflow02 ($WF02_IP_ADDR)"
  readonly LOG_WF02_NAME

  WF01_LOG="${LOG_DIR}/WF01_${WF01_IP_ADDR}_chef.log"
  readonly WF01_LOG
  WF02_LOG="${LOG_DIR}/WF02_${WF02_IP_ADDR}_chef.log"
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

######## Prepare logs #######
# define where to log
LOG_DIR="/var/log/baw_multinodes_noihs_chef"
BAW_CHEF_LOG="${LOG_DIR}/BAW_CHEF_SCRIPT_chef.log"
readonly BAW_CHEF_LOG
Create_Log_Dir

Main_Start 2>&1 | tee $BAW_CHEF_LOG  