#!/usr/bin/env bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2019-12-27
## Modified： 2021-01-23
## Version： v1.0.0
## Description: Auto save|shutdown|update|restart dst.

screen_name_1=$"master";
screen_name_2=$"caves";
screen_name_3=$"test";

function exists_screen()
{
	err=$"--err.exists_screen:";
	log=$"--log.exists_screen:";
	if [ 1 -ne $# ];then
		echo -e "$err Must have one and only one parameter ";
		return 99;
	fi
	echo -e "$log input parameter1: $1";
	echo -e `screen -ls | grep -e "$1"`;
	## -n 非空真 The not null is true.  -z 空为真 The null is true.
	if [[ -n `screen -ls | grep -e "$1"`  ]];then
		echo -e "$log have screen: $1";
		return 0;
	else
		echo -e "$log dont have screen: $1";
		return 1;
	fi
}

function save_dst()
{
	err=$"--err.save_dst:";
	log=$"--log.save_dst:";
	cmd_save=$"c_save() \n";
	## Determine if the screen exists.
	exists_screen "$1";
	if [[ 0 -eq $? ]];then
		screen -S $1 -p 0 -X stuff "$cmd_save";
		echo -e "$log save $1";
		sleep 30s; ## This process sleeps for 30 seconds.
	fi
}

function shutdown_dst()
{
	err=$"--err.shutdown_dst:";
	log=$"--log.shutdown_dst:";
	cmd_shutdown=$"c_shutdown() \n";
	## Determine if the screen exists.
	exists_screen "$1";
	if [[ 0 -eq $? ]];then
		screen -S $1 -p 0 -X stuff "$cmd_shutdown";
	echo -e "$log shutdown $1";
		#tail_server_log "$1";
		#res1=$(screen -S $1 -p 0 -X stuff $"ls \n");
		#echo -e "$res1";
	fi
}

function send_announce()
{
	log=$"--log.send_announce:";
	cmd_announce=$"c_announce(\"10s后服务器更新重启 q群 \") \n";
	## Determine if the screen exists.
	exists_screen "$1";
	if [[ 0 -eq $? ]];then
		screen -S $1 -p 0 -X stuff "$cmd_announce";
		echo -e "$log $1 send $cmd_announce";
		#tail_server_log "$1";
		#res1=$(screen -S $1 -p 0 -X stuff $"ls \n");
		#echo -e "$res1";
	fi
}

function tail_server_log()
{
	err=$"--err.tail_server_log:";
	log=$"--log.tail_server_log:";
	master_server_log=$"/home/steamgame/dst/dst/World1/Master/server_log.txt";
	caves_server_log=$"/home/steamgame/dst/dst/World1/Caves/server_log.txt";
	server_log=$"/home/steamgame/dst/dst/World1/Master/server_log.txt";
	## Replace command
	if [ "$screen_name_1" = "$1" ];then
		server_log="$master_server_log";
	elif [ "$screen_name_2" = "$1" ];then
		server_log="$caves_server_log";
	else
		echo -e "$err Invalid paramter ";
		exit;
	fi

	if [ ! -e $server_log ];then
		echo -e "$log The file is not exist";
		return 99;
	fi
	echo -e "$log wait...";
	while true
	do
		if [[ -n `tail $server_log | grep 'Shutting down'` ]];then
			break;
		else
			#echo -e '--sleep';
			sleep 1s;
		fi
	done
	echo -e "$log the end";
}

function start_dst()
{
	err=$"--err.start_dst:";
	log=$"--log.start_dst:";
	cmd_cd=$"cd /home/steamgame/dst/bin/ \n";
	cmd_master=$"sh master_start.sh \n";
	cmd_caves=$"sh cave_start.sh \n";
	cmd_start_sh=$"ls \n";
	if [ 1 -gt $# ];then
		echo -e "$err At least one parameter ";
		exit;
	fi
	## Replace command
	if [ "$screen_name_1" = "$1" ];then
		cmd_start_sh="$cmd_master";
	elif [ "$screen_name_2" = "$1" ];then
		cmd_start_sh="$cmd_caves";
	else
		echo -e "$err Invalid paramter ";
		exit;
	fi
	## Determine if the screen exists
	exists_screen "$1";
	if [[ 0 -ne $? ]];then
		## create screen and detach it
		if [ "init" = "$2" ];then
			echo -e "$log create the screen: $1";
			screen -dmS $1;
		else
			echo -e "$log The screen is not exists and param is not init: $1 ";
			return 99;
		fi
	fi
	## Send commands to the offline screen
	screen -S $1 -p 0 -X stuff "$cmd_cd";
	screen -S $1 -p 0 -X stuff "$cmd_start_sh";
	echo -e "$log end";
}

function update_dst()
{
	sh /home/steamgame/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/steamgame/dst +app_update 343050 validate +quit
#	sh /home/steamgame/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/steamgame/dst +app_update 343050 validate +quit > ./dst_update.log
}

## The main menu

echo $(date +%F%n%T);
echo -e '--log.main: input parameter1: '$1;

if [ "initmaster" = "$1" ];then
	start_dst "$screen_name_1" init;
elif [ "initcaves" = "$1" ];then
	start_dst "$screen_name_2" init;
elif [ "restart" = "$1" ];then
	start_dst "$screen_name_2";
	start_dst "$screen_name_1";
elif [ "shutdown" = "$1" ];then
	send_announce "$screen_name_1";
	send_announce "$screen_name_2";
	sleep 10s;
	save_dst "$screen_name_1";
	shutdown_dst "$screen_name_2";
	shutdown_dst "$screen_name_1";
	tail_server_log "$screen_name_1";
	#echo -e 'The result:'$?;
elif [ "updatedst" = "$1" ];then
	update_dst;
elif [ "SUR" = "$1" ];then
	send_announce "$screen_name_1";
	send_announce "$screen_name_2";
	sleep 10s;
	save_dst "$screen_name_1";
	shutdown_dst "$screen_name_2";
	shutdown_dst "$screen_name_1";
	tail_server_log "$screen_name_1";
	sleep 10s;
	update_dst;
	start_dst "$screen_name_2";
	start_dst "$screen_name_1";
else
	echo -e "\033[33m \t--help.main: Parameter must be [ initmaster | initcaves | shutdown | updatedst | restart | SUR ] \033[0m";
	echo -e "\033[33m \t   SUR : shutdown and updatedst and restart \033[0m";
fi

echo $(date +%F%n%T);

