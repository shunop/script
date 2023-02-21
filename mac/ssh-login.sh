#!/bin/bash

## 登陆信息配置
## 每个登陆信息为一个数组
## 第一个登陆信息的变量名称必须是「LOGIN_INFO_1」，多条登陆信息时需要是 1 的连续整数

## 用户名@主机,端口,密码或密钥文件的绝对路径,密码方式,备注信息
## root@192.168.255.10,22,/Users/admin/.ssh/id_rsa,key,公司开发服务器")
## root@192.168.255.11,22,123456,pwd,本地虚拟机个人环境")

#################### 配置文件-开始 ####################
#config=$(cat <<- EOF
##build-test@172.16.46.41,22,build-test,pwd,cmft-ci
#fc-capital@172.16.46.36,22,Cpyfzx@321,pwd,cmft-sit##资方中心
#fc-capital@172.16.48.186,22,fc-capital,pwd,cmft-uat##资方中心
#EOF
#)
#################### 配置文件-结束 ####################


LOGIN_TAG_START=1
def_length=5

index_user_ip=0 # 用户名@主机
index_port=1 # 端口
index_pwd=2 # 密码 或者 密钥文件的绝对路径
index_type=3 # 登陆方式。key：密钥方式；pwd：密码方式
index_remark=4 # 备注信息

log_blue(){ echo -e "\033[34m\033[01m$*\033[0m";}
log_green(){ echo -e "\033[32m\033[01m$*\033[0m";}
log_red(){ echo -e "\033[31m\033[01m$*\033[0m";}
log_yellow(){ echo -e "\033[33m\033[01m$*\033[0m";}
log_bred(){ echo -e "\033[31m\033[01m\033[05m$*\033[0m";}
log_byellow(){ echo -e "\033[33m\033[01m\033[05m$*\033[0m";}

log_red2(){ printf "\e[31m\e[01m $* \e[0m \n";}
log_blue2(){ printf "\e[34m\e[01m $* \e[0m \n";}


config=''
load_config() {
  local v_config_type="$1"
  if [[ "fmg" == "$v_config_type" ]]; then
    log_blue2 'fmg'
    source ssh-login-config-fmg.sh
    config=$config_out
  elif [[ "cmg" == "$v_config_type" ]]; then
    log_blue2 'cmg'
    source ssh-login-config-cmg.sh
    config=$config_out
  else
    log_red2 '需要传入 cmg 或 fmg'
    exit 1
  fi

}
load_config $@

init_config() {
  local v_config_type="$1"
#  config=$(echo $config | tr ' ' '\n' | sort -n)
  config=$(echo $config | tr ' ' '\n' | sort -t',' -k5)
  declare -i index=0
  for line in $config; do
    if [[ "#" == $(echo $line | cut -c1) ]]; then
      continue
    fi
    ((++index))
    # arr=(`echo $line | tr ',' ' '`)
    LOGIN_INFO_ARR[${index}]=$line
  done

  if [[ 0 -eq ${#LOGIN_INFO_ARR[*]} ]];then
    log_red2 "${v_config_type}配置的服务器数量为0"
    exit 1
  fi

  log_blue2 "${v_config_type}配置共 ${#LOGIN_INFO_ARR[*]} 个服务器"
}
init_config $@


login_info_configure_check() {
#  local LOCAL_LOGIN_TAG_START=${LOGIN_TAG_START}

  # 第一个登陆配置数组不存在
#  if [ ! $(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}}) ]; then
#    log_red '错误！登陆数组：LOGIN_INFO_'${LOCAL_LOGIN_TAG_START}' 不存在'
#    exit 1
#  fi

#  while [ $(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}}) ]; do
  for index in "${!LOGIN_INFO_ARR[@]}"; do
    local LOGIN_INFO_LINE=(`echo ${LOGIN_INFO_ARR[$index]} | tr ',' ' '`)

    # 获得配置数组的元素总数
    local length=$(eval echo "\${#LOGIN_INFO_LINE[*]}")

    if [ ${def_length} -ne ${length} ]; then
      log_red2 "${LOGIN_INFO_LINE[*]} 配置项必须是 ${def_length} 项。脚本停止检查、终止执行、退出！"
      exit 1
    fi

    if [[ 'pwd' != "$(eval echo \${LOGIN_INFO_LINE[${index_type}]})" ]] && [[ 'key' != "$(eval echo \${LOGIN_INFO_LINE[${index_type}]})" ]]; then
      log_red2 "${LOGIN_INFO_LINE[0]} 配置登陆方式错误，脚本停止检查、终止执行、退出！"
      exit 1
    fi

    if [[ 'key' == "$(eval echo \${LOGIN_INFO_LINE[${index_type}]})" ]] && [[ ! "$(eval echo \${LOGIN_INFO_LINE[${index_pwd}]})" ]]; then
      log_red2 "${LOGIN_INFO_LINE[0]} 配置为密钥登陆，但是没有配置密钥文件，脚本停止检查、终止执行、退出！"
      exit 1
    fi

    for i in $(seq 0 "$((length - 1))"); do
      if [ 3 -eq "${i}" ] || [ 4 -eq "${i}" ]; then
        continue
      fi

      if [ ! "$(eval echo \${LOGIN_INFO_LINE[${i}]})" ]; then
        local LOGIN_INFO_CONFIGURE_NUM=$((i + 1))
        log_red2 "${LOGIN_INFO_LINE[0]} 第 ${LOGIN_INFO_CONFIGURE_NUM} 项配置不能为空"
        exit 1
      fi
    done
#    ((LOCAL_LOGIN_TAG_START++))
  done

}

# 调用登陆用户配置数组的检查
login_info_configure_check

max_colum_user_ip=1
max_colum_remark=1
calculate_column_max_length() {
  for index in "${!LOGIN_INFO_ARR[@]}"; do
    local LOGIN_INFO_LINE=(`echo ${LOGIN_INFO_ARR[index]} | tr ',' ' '`)
    if [ ${max_colum_user_ip} -lt ${#LOGIN_INFO_LINE[${index_user_ip}]} ];then
      max_colum_user_ip=${#LOGIN_INFO_LINE[${index_user_ip}]}
    fi
    if [ ${max_colum_user_ip} -lt ${#LOGIN_INFO_LINE[${index_remark}]} ];then
      max_colum_remark=${#LOGIN_INFO_LINE[${index_remark}]}
    fi
  done
  max_colum_user_ip=`expr $max_colum_user_ip + 3`
  max_colum_remark=`expr $max_colum_remark + 3`
#  echo "${max_colum_user_ip} ---- ${max_colum_remark}"
}
#计算列最大值
calculate_column_max_length

screen_echo_colum_color() {
#  printf "%-8s |" '序号'
  printf " %-40s |" 'user@ip'
  printf " %-2s|" '序号'
  printf " %-40s\n" '说明'
  local LOCAL_LOGIN_TAG_START=${LOGIN_TAG_START}

  for index in "${!LOGIN_INFO_ARR[@]}"; do
    local LOGIN_INFO_LINE=(`echo ${LOGIN_INFO_ARR[index]} | tr ',' ' '`)

#    printf "\e[31m %-5s\e[0m |" "${index}" # 颜色为红色
    printf "\e[32m %-40s\e[0m |" "$(eval echo \${LOGIN_INFO_LINE[${index_user_ip}]})"
    printf "\e[31m %-3s\e[0m |" "${index}"
    printf " %-40s\n" "$(eval echo \${LOGIN_INFO_LINE[${index_remark}]})"
  done
  # 服务器总数
  USER_SUM=${#LOGIN_INFO_ARR[*]}

}

screen_echo_line_color() {
  local LOCAL_LOGIN_TAG_START=${LOGIN_TAG_START}

#  printf "%-8s |" '序号'
  printf " %-${max_colum_user_ip}s |" 'user@ip'
  printf " %-2s|" '序号'
  printf " %-${max_colum_remark}s\n" '说明'

  for index in "${!LOGIN_INFO_ARR[@]}"; do
    local LOGIN_INFO_LINE=(`echo ${LOGIN_INFO_ARR[index]} | tr ',' ' '`)

    if [ `expr ${index} % 2` -eq 0 ]; then
      printf "\e[32m %-${max_colum_user_ip}s | %-3s ｜ %-${max_colum_remark}s \e[0m\n" "$(eval echo \${LOGIN_INFO_LINE[${index_user_ip}]})" "${index}" "$(eval echo \${LOGIN_INFO_LINE[${index_remark}]})"
    else
      printf "\e[0m %-${max_colum_user_ip}s | %-3s ｜ %-${max_colum_remark}s \e[0m\n" "$(eval echo \${LOGIN_INFO_LINE[${index_user_ip}]})" "${index}" "$(eval echo \${LOGIN_INFO_LINE[${index_remark}]})"
    fi
  done
  # 服务器总数
  USER_SUM=${#LOGIN_INFO_ARR[*]}
}

color_flag=1 # 1是不开启颜色 0是开启
screen_echo_line_color2() {
  local LOCAL_LOGIN_TAG_START=${LOGIN_TAG_START}

#  printf "%-8s |" '序号'
  printf " %-${max_colum_user_ip}s |" 'user@ip'
  printf " %-2s|" '序号'
  printf " %-${max_colum_remark}s\n" '说明'

  for index in "${!LOGIN_INFO_ARR[@]}"; do
    local LOGIN_INFO_LINE=(`echo ${LOGIN_INFO_ARR[index]} | tr ',' ' '`)

    if [ `expr ${index} % 2` -eq 0 ]; then
      if [ ${color_flag} -eq 1 ];then
        color_flag=0
        printf "\e[32m"
      else
        color_flag=1
        printf "\e[0m"
      fi
    fi
      printf " %-${max_colum_user_ip}s | %-3s ｜ %-${max_colum_remark}s \n" "$(eval echo \${LOGIN_INFO_LINE[${index_user_ip}]})" "${index}" "$(eval echo \${LOGIN_INFO_LINE[${index_remark}]})"
  done
  printf "\e[0m %s \e[0m \n" ""
  # 服务器总数
  USER_SUM=${#LOGIN_INFO_ARR[*]}
}

# 调用屏幕输出信息函数
screen_echo_line_color2

while true; do

  # 让使用者选择所需要登陆服务器的所属序号
  read -p '请输入要登陆的服务器所属序号: ' LOGIN_NUM

  if [[ "${LOGIN_NUM}" =~ [^0-9]+ ]]; then
    log_red2 '序号是数字'
    continue
  fi

  if [ ! ${LOGIN_NUM} ]; then
    log_red2 '请输入序号'
    continue
  fi

  if [[ "${LOGIN_NUM}" =~ ^0 ]]; then
    log_red2 '序号不能以 0 开头'
    continue
  fi

  # 用户选择的序号 > 服务器总数、用户选择的序号 < 服务器总数。则提示错误并且重新循环
  if [ ${LOGIN_NUM} -gt ${USER_SUM} ] || [ ${LOGIN_NUM} -lt ${LOGIN_TAG_START} ]; then
    log_red2 '请输入存在的序号'
    continue
  fi

  LOGIN_INFO_SELECT=(`echo ${LOGIN_INFO_ARR[LOGIN_NUM]} | tr ',' ' '`)
  break
done

# 登陆的函数

login_exec() {
  # 当登陆方式是密码时
  if [ 'pwd' == "$(eval echo \${LOGIN_INFO_SELECT[${index_type}]})" ]; then
    local mima=$(eval echo \${LOGIN_INFO_SELECT[${index_pwd}]})

    # 密码长度非 0 时
    if [[ -n ${mima} ]]; then
      # 对 } 转义
      local mima=${mima//\}/\\\}}
      # 对 ; 转义
      local mima=${mima//\;/\\;}

    fi
  fi

  # spawn -noecho 不显示登陆信息
  # 当登陆后出现「*yes/no*」是，回应「yes」
  # ConnectTimeout 连接时超时时间；ConnectionAttempts 连接失败时的重试次数；StrictHostKeyChecking 不提示认证；ServerAliveInterval 客户端每多少秒向服务器发送请求；ServerAliveCountMax 客户端向服务器发送请求失败时的重试次数
  # 「exp_continue」继续执行下面的匹配
  # 「interact」留在远程终端上面。如果不写此语句，自动退出服务器
  expect -c "
switch $(eval echo \${LOGIN_INFO_SELECT[${index_type}]}) {
    \"pwd\" {
        spawn -noecho ssh -o ConnectTimeout=15 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 $(eval echo \${LOGIN_INFO_SELECT[${index_user_ip}]}) -p $(eval echo \${LOGIN_INFO_SELECT[${index_port}]})
        expect {
            *yes/no* { send yes\r exp_continue }
            *denied* { exit }
            *password* { send ${mima}\r }
            *Password* { send ${mima}\r }
        }
        interact
    }
    \"key\" {
        spawn -noecho ssh -o ConnectTimeout=15 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -i $(eval echo \${LOGIN_INFO_SELECT[${index_pwd}]}) $(eval echo \${LOGIN_INFO_SELECT[${index_user_ip}]}) -p $(eval echo \${LOGIN_INFO_SELECT[${index_port}]})
        interact
    }
    default {
        puts \"error\"
    }
}
"

  return 0

}

# 调用登陆执行函数
login_exec
