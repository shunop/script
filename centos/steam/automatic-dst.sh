#!/usr/bin/env bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2019-12-27
## Modified： 2021-01-23
## Version： v1.0.0
## Description: Auto save|shutdown|update|restart dst.

v_screen_master=$"master"
v_screen_caves=$"caves"

function f_exists_screen() {
  v_screen_name="$1"
  echo $(screen -ls | grep -e "$v_screen_name")
  ## -n 非空真 The not null is true.  -z 空为真 The null is true.
  if [[ -n $(screen -ls | grep -e "$v_screen_name") ]]; then
    echo "have screen: $v_screen_name"
    return 0
  else
    echo "dont have screen: $v_screen_name"
    return 1
  fi
}

function f_save_dst() {
  v_screen_name="$1"
  v_cmd_save=$"c_save() \n"
  ## Determine if the screen exists.
  f_exists_screen "$v_screen_name"
  if [[ 0 -eq $? ]]; then
    screen -S $v_screen_name -p 0 -X stuff "$v_cmd_save"
    echo "save: $v_screen_name"
    sleep 30s ## This process sleeps for 30 seconds.
  fi
}

function f_shutdown_dst() {
  v_screen_name="$1"
  v_cmd_shutdown=$"c_shutdown() \n"
  ## Determine if the screen exists.
  f_exists_screen "$v_screen_name"
  if [[ 0 -eq $? ]]; then
    screen -S $v_screen_name -p 0 -X stuff "$v_cmd_shutdown"
    echo "shutdown: $v_screen_name"
    #f_tail_server_log "$v_screen_name";
    #res1=$(screen -S $v_screen_name -p 0 -X stuff $"ls \n");
    #echo -e "$res1";
  fi
}

function f_send_announce() {
  v_screen_name="$1"
  v_cmd_announce=$"c_announce(\"10s后服务器更新重启 q群 \") \n"
  ## Determine if the screen exists.
  f_exists_screen "$v_screen_name"
  if [[ 0 -eq $? ]]; then
    screen -S $v_screen_name -p 0 -X stuff "$v_cmd_announce"
    echo "send: $v_screen_name $v_cmd_announce"
    #f_tail_server_log "$v_screen_name";
    #res1=$(screen -S $v_screen_name -p 0 -X stuff $"ls \n");
    #echo -e "$res1";
  fi
}

function f_tail_server_log() {
  v_screen_name="$1"
  v_server_log_file=$"/home/steamgame/dst/dst/World1/Master/server_log.txt"
  ## Replace command
  if [ "$v_screen_caves" = "$v_screen_name" ]; then
    v_server_log_file="/home/steamgame/dst/dst/World1/Caves/server_log.txt"
  fi
  ## check file
  if [ ! -f $v_server_log_file ]; then
    echo "[$v_server_log_file]The file is not exist"
    return 99
  fi

  echo -e "wait..."
  ## 获取从1970-01-01 00:00:00 UTC到现在的秒数
  ## v_cur_sec=$(date '+%s')

  ## 300s overtime
  for i in $(seq 1 300); do
    if [[ -n $(tail $v_server_log_file | grep -i 'Shutting down') ]]; then
      break
    else
      sleep 1s
    fi
  done
  echo -e "the end"
}

function f_start_dst() {
  v_screen_name="$1"
  cmd_cd=$"cd /home/steamgame/dst/bin/ \n"
  cmd_master=$"sh master_start.sh \n"
  cmd_caves=$"sh cave_start.sh \n"
  cmd_start_sh=$"ls \n"

  ## Replace command
  if [ "$v_screen_master" = "$v_screen_name" ]; then
    cmd_start_sh="$cmd_master"
  elif [ "$v_screen_caves" = "$v_screen_name" ]; then
    cmd_start_sh="$cmd_caves"
  else
    echo -e "$err Invalid paramter "
    exit 1
  fi
  ## Determine if the screen exists
  f_exists_screen "$v_screen_name"
  if [[ 0 -ne $? ]]; then
    ## create screen and detach it
    if [ "init" = "$2" ]; then
      echo -e "create the screen: $v_screen_name"
      screen -dmS $v_screen_name
    else
      echo -e "The screen is not exists and param is not init: $v_screen_name "
      exit 1
    fi
  fi
  ## Send commands to the offline screen
  screen -S $v_screen_name -p 0 -X stuff "$cmd_cd"
  screen -S $v_screen_name -p 0 -X stuff "$cmd_start_sh"
  echo -e "end"
}

function update_dst() {
  sh /home/steamgame/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/steamgame/dst +app_update 343050 validate +quit
  #	sh /home/steamgame/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/steamgame/dst +app_update 343050 validate +quit > ./dst_update.log
}

## The main menu

echo $(date +%F%n%T)
echo -e '--log.main: input parameter1: '$1

if [ "initmaster" = "$1" ]; then
  f_start_dst "$v_screen_master" init
elif [ "initcaves" = "$1" ]; then
  f_start_dst "$v_screen_caves" init
elif [ "restart" = "$1" ]; then
  f_start_dst "$v_screen_caves"
  f_start_dst "$v_screen_master"
elif [ "shutdown" = "$1" ]; then
  f_send_announce "$v_screen_master"
  f_send_announce "$v_screen_caves"
  sleep 10s
  f_save_dst "$v_screen_master"
  f_shutdown_dst "$v_screen_caves"
  f_shutdown_dst "$v_screen_master"
  f_tail_server_log "$v_screen_master"
  #echo -e 'The result:'$?;
elif [ "updatedst" = "$1" ]; then
  update_dst
elif [ "SUR" = "$1" ]; then
  f_send_announce "$v_screen_master"
  f_send_announce "$v_screen_caves"
  sleep 10s
  f_save_dst "$v_screen_master"
  f_shutdown_dst "$v_screen_caves"
  f_shutdown_dst "$v_screen_master"
  f_tail_server_log "$v_screen_master"
  sleep 10s
  update_dst
  f_start_dst "$v_screen_caves"
  f_start_dst "$v_screen_master"
else
  echo -e "\033[33m \t--help.main: Parameter must be [ initmaster | initcaves | shutdown | updatedst | restart | SUR ] \033[0m"
  echo -e "\033[33m \t   SUR : shutdown and updatedst and restart \033[0m"
fi

echo $(date +%F%n%T)
