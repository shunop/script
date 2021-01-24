#!/usr/bin/env bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2021-01-23
## Modified： 2021-01-23
## Version： v1.0.0

## 管理员列表(选填):KU_abcd
v_adminlist=""
## token(必填):pds-abcd
v_cluster_token="your_dst_token"
## 服务器配置(必填)
v_cluster_ini="[STEAM]
steam_group_admins = true
steam_group_id = 36356463
steam_group_only = false

[GAMEPLAY]
### survival  endless
game_mode = survival
max_players = 6
pvp = false
pause_when_empty = true

[NETWORK]
lan_only_cluster = false
cluster_intention = cooperative
cluster_password =
cluster_description = dst 群组 cave q群=?
cluster_name = welcome dst test (on script)
offline_cluster = false
cluster_language = zh
whitelist_slots = 1

[MISC]
console_enabled = true

[SHARD]
shard_enabled = true
bind_ip = 127.0.0.1
master_ip = 127.0.0.1
master_port = 10888
cluster_key = defaultPass"

## su steamgame
## 1.(手动操作)创建用户 steamgame 并切换到该用户下

## 2.下载steamcmd
mkdir ~/steamcmd &&
  cd ~/steamcmd &&
  echo "====[2/5] download steamcmd====" &&
  wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz &&
  tar -zxf steamcmd_linux.tar.gz &&

  ## 3.安装dstserver
  ## +login anonymous 匿名登录
  ## +force_install_dir /home/steamgame/dstserver 强制安装目录
  ## +app_update 343050 安装的id为343050的app
  ## validate 校验完整性
  ## +quit 退出
  echo "====[3/5] download dst====" &&
  sh ~/steamcmd/steamcmd.sh +login anonymous +force_install_dir ~/dstserver +app_update 343050 validate +quit &&

  ## 检查依赖完整性
  echo "====[3.2/5] download dst====" &&
  ldd dontstarve_dedicated_server_nullrenderer &&
  ## 报错解决
  ## ln -s /usr/lib/libcurl.so.4 ~/dst/bin/lib32/libcurl-gnutls.so.4

  ## 4.创建启动脚本
  echo "====[4/5] create start script====" &&
  cd ~/dstserver/bin &&
  echo "sh ~/dstserver/bin/dontstarve_dedicated_server_nullrenderer -console -persistent_storage_root ~/dstserver -conf_dir dstconfig -cluster World1 -shard Master" >master_start.sh &&
  echo "sh ~/dstserver/bin/dontstarve_dedicated_server_nullrenderer -console -persistent_storage_root ~/dstserver -conf_dir dstconfig -cluster World1 -shard Caves" >cave_start.sh &&
  chmod u+x cave_start.sh master_start.sh &&

  ## 5.创建配置文件
  echo "====[5/5] create config file====" &&
  mkdir -p ~/dstserver/dstconfig/World1/ &&
  cd ~/dstserver/dstconfig/World1/ &&
  ##
  touch adminlist.txt blocklist.txt cluster.ini cluster_token.txt &&
  echo "${v_adminlist}" >adminlist.txt &&
  echo "${v_cluster_ini}" >cluster.ini &&
  echo "${v_cluster_token}" >cluster_token.txt &&
  echo "install successful
Use the command to start the dst service
sh ~/dstserver/bin/master_start.sh
sh ~/dstserver/bin/cave_start.sh"

## 安装后台服务
#yum -y install screen
#screen -S master
#screen -r master
#screen -ls

## 安装sz rz命令
#yum -y install lrzsz

## 查看防火墙列表
#firewall-cmd --list-all
