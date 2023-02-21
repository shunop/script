#!/bin/bash

## 登陆信息配置
## 每个登陆信息为一个数组
## 第一个登陆信息的变量名称必须是「LOGIN_INFO_1」，多条登陆信息时需要是 1 的连续整数

##                  用户名@主机            端口 密码或密钥文件的绝对路径          密码方式 备注信息
LOGIN_INFO_0_demo=( "root@192.168.255.10" 22 "/Users/admin/.ssh/id_rsa" "key" "公司开发服务器")
LOGIN_INFO_1_demo=( "root@192.168.255.11" 22 "123456" "pwd" "本地虚拟机 个人环境")
## 服务器配置
LOGIN_INFO_0=( "root@192.168.255.11" 22 "123456" "pwd" "样例")

#################### 配置文件-开始 ####################

#################### 配置文件-结束 ####################


LOGIN_TAG_START=1
def_length=5

index_user_ip=0 # 用户名@主机
#index_ip=1 # 主机
index_port=1 # 端口
index_pwd=2 # 密码 或 密钥文件的绝对路径
#index_key=3 # 密钥文件的绝对路径
index_type=3 # 登陆方式。key：密钥方式；pwd：密码方式
index_remark=4 # 备注信息

log_blue(){ echo -e "\033[34m\033[01m$*\033[0m";}
log_green(){ echo -e "\033[32m\033[01m$*\033[0m";}
log_red(){ echo -e "\033[31m\033[01m$*\033[0m";}
log_yellow(){ echo -e "\033[33m\033[01m$*\033[0m";}
log_bred(){ echo -e "\033[31m\033[01m\033[05m$*\033[0m";}
log_byellow(){ echo -e "\033[33m\033[01m\033[05m$*\033[0m";}

login_info_configure_check() {
  local LOCAL_LOGIN_TAG_START=${LOGIN_TAG_START}

  # 第一个登陆配置数组不存在
  if [ ! $(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}}) ]; then
    log_red '错误！登陆数组：LOGIN_INFO_'${LOCAL_LOGIN_TAG_START}' 不存在'
    exit 1
  fi

  while [ $(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}}) ]; do

    # 获得配置数组的元素总数
    local length=$(eval echo "\${#LOGIN_INFO_${LOCAL_LOGIN_TAG_START}[*]}")

    if [ ${def_length} -ne ${length} ]; then
      log_red 'LOGIN_INFO_'${LOCAL_LOGIN_TAG_START}' 配置项必须是 ${def_length} 项。脚本停止检查、终止执行、退出！'
      exit 1
    fi

    if [[ 'pwd' != "$(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}[${index_type}]})" ]] && [[ 'key' != "$(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}[${index_type}]})" ]]; then
      log_red 'LOGIN_INFO_'${LOCAL_LOGIN_TAG_START}' 配置登陆方式错误，脚本停止检查、终止执行、退出！'
      exit 1
    fi

    if [[ 'key' == "$(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}[${index_type}]})" ]] && [[ ! "$(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}[${index_pwd}]})" ]]; then
      log_red 'LOGIN_INFO_'${LOCAL_LOGIN_TAG_START}' 配置为密钥登陆，但是没有配置密钥文件，脚本停止检查、终止执行、退出！'
      exit 1
    fi

    for i in $(seq 0 "$((length - 1))"); do
      if [ 3 -eq "${i}" ] || [ 4 -eq "${i}" ]; then
        continue
      fi

      if [ ! "$(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}[${i}]})" ]; then
        local LOGIN_INFO_CONFIGURE_NUM=$((i + 1))
        log_red 'LOGIN_INFO_'${LOCAL_LOGIN_TAG_START}' 第 '${LOGIN_INFO_CONFIGURE_NUM}' 项配置不能为空'
        exit 1
      fi
    done
    ((LOCAL_LOGIN_TAG_START++))
  done

}

# 调用登陆用户配置数组的检查
login_info_configure_check

screen_echo() {

  printf "%-8s |" '序号'
  printf " %-40s |" 'user@ip'
  printf " %-30s\n" '说明'

  local LOCAL_LOGIN_TAG_START=${LOGIN_TAG_START}

  while [ $(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}}) ]; do

    printf "\e[31m %-5s\e[0m |" "${LOCAL_LOGIN_TAG_START}" # 颜色为红色
    printf "\e[32m %-40s\e[0m |" "$(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}[${index_user_ip}]})"
    printf " %-30s\n" "$(eval echo \${LOGIN_INFO_${LOCAL_LOGIN_TAG_START}[${index_remark}]})"
    # 服务器总数
    USER_SUM=${LOCAL_LOGIN_TAG_START}
    ((LOCAL_LOGIN_TAG_START++))
  done

}

# 调用屏幕输出信息函数
screen_echo

while true; do

  # 让使用者选择所需要登陆服务器的所属序号
  read -p '请输入要登陆的服务器所属序号: ' LOGIN_NUM

  if [[ "${LOGIN_NUM}" =~ [^0-9]+ ]]; then
    log_red '序号是数字'
    continue
  fi

  if [ ! ${LOGIN_NUM} ]; then
    log_red '请输入序号'
    continue
  fi

  if [[ "${LOGIN_NUM}" =~ ^0 ]]; then
    log_red '序号不能以 0 开头'
    continue
  fi

  # 用户选择的序号 > 服务器总数、用户选择的序号 < 服务器总数。则提示错误并且重新循环
  if [ ${LOGIN_NUM} -gt ${USER_SUM} ] || [ ${LOGIN_NUM} -lt ${LOGIN_TAG_START} ]; then
    log_red '请输入存在的序号'
    continue
  fi

  break
done

# 登陆的函数

login_exec() {
  # 当登陆方式是密码时
  if [ 'pwd' == "$(eval echo \${LOGIN_INFO_${LOGIN_NUM}[${index_type}]})" ]; then
    local mima=$(eval echo \${LOGIN_INFO_${LOGIN_NUM}[${index_pwd}]})

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
switch $(eval echo \${LOGIN_INFO_${LOGIN_NUM}[${index_type}]}) {
    \"pwd\" {
        spawn -noecho ssh -o ConnectTimeout=15 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 $(eval echo \${LOGIN_INFO_${LOGIN_NUM}[${index_user_ip}]}) -p $(eval echo \${LOGIN_INFO_${LOGIN_NUM}[${index_port}]})
        expect {
            *yes/no* { send yes\r exp_continue }
            *denied* { exit }
            *password* { send ${mima}\r }
            *Password* { send ${mima}\r }
        }
        interact
    }
    \"key\" {
        spawn -noecho ssh -o ConnectTimeout=15 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -i $(eval echo \${LOGIN_INFO_${LOGIN_NUM}[${index_pwd}]}) $(eval echo \${LOGIN_INFO_${LOGIN_NUM}[${index_user_ip}]}) -p $(eval echo \${LOGIN_INFO_${LOGIN_NUM}[${index_port}]})
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
