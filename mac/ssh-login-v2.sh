#!/bin/bash


g_conf_file="~/ssh-login.conf"
def_length=8

index_user_ip=0 # 用户名@主机
index_port=1 # 端口
index_pwd=2 # 密码 或者 密钥文件的绝对路径
index_type=3 # 登陆方式。key：密钥方式；pwd：密码方式
index_remark=4 # 备注信息

flag_auth_type_Password="Password"
flag_auth_type_PrivateKey="PrivateKey"
flag_field_empty="null"

#            0        ,  1     ,   2    , 3  ,  4           , 5      ,       6        ,  7
# Format2: environment,username,hostname,port,authentication,password,private_key_file,title

idx_environment=0
idx_username=1
idx_hostname=2
idx_port=3
idx_authentication=4
idx_password=5
idx_private_key_file=6
idx_title=7

max_colum_user_ip=1 # user@host 列的最大宽度
max_colum_remark=1 # remark 列的最大宽度

environment_arr=()  # 环境列表信息
environment_pickup=""  # 用户选择的环境


log_red2(){ printf "\e[31m\e[01m $* \e[0m \n";}
log_blue2(){ printf "\e[34m\e[01m $* \e[0m \n";}

#
# UTF8编码下，汉字通常是3个byte，通过它来判断【中英常见字符组成的字符串】中汉字的数量
# 一个汉字占位是两个英文字符
# 一个汉字替代了三个空格，但是字宽是个两个空格。
# 计算中文的个数，中文显示两个字宽（所以统计最大列宽时，需要统计两次中文字符），但是占用三个空格（所以在打印时，遇到中文需要再前面的基础上补一次中文的个数）
#
function count_zh_char() {
    local zh_str="${1}"
    local byte_count
    local char_count
    local zh_count
    byte_count=$(printf "${zh_str}" | wc -c)
    char_count=$(printf "${zh_str}" | wc -m)
    zh_count=$(((byte_count - char_count) / 2))
    echo ${zh_count}
}

#  需求是生成一个完成度较高的shell脚本，可以根据传入的参数进行ssh登录，我们把多个服务器的配置信息放到一个配置文件中，
#  需要注意 bash的运行环境是 GNU bash, version 3.2.57(1)-release
# 请设计这样一个配置文件，里面保存多个服务器的登录信息，环境组，用户名，ip，端口，认证方式，密码，私钥文件位置，标题 等信息， 用shell脚本读取该配置文件，可以根据用户选择登录到对应的服务器

function f_load_csv_config_file() {
  local v_file_path="$1"

  while read -r line; do
    # 判断如果行是空的或以 '#' 开头或整行都是空白字符则跳过
    if [[ -z "${line}" || "${line}" =~ ^[[:space:]]*$ || "${line}" =~ ^# ]]; then
      continue
    fi
    # 在这里添加需要处理的代码，例如输出非空行
    echo "${line}"
  done < "${v_file_path}"
}

# 首先按照IP地址的四个数字进行升序排序，如果IP地址的四个数字相同，就按照用户名进行排序。
function f_sort_csv_config_file() {
  local v_csv_data="$@"
  # environment,username,hostname,port,authentication,password,private_key_file,title
  #   1        ,  2     , 3.4.5.6, 7  , 8
  local sorted=$(echo "$v_csv_data" | tr ' ' '\n' | awk -F '[,.]' '{print $1,$3,$4,$5,$6,$2,$0}'| sort -k1,1 -k2,2n -k3,3n -k4,4n -k5,5n -k6,6 | cut -d ' ' -f7-)
  echo "${sorted}"
}

# 检查配置文件
function f_login_info_configure_check() {

  if [[ 0 -eq ${#LOGIN_INFO_ARR[*]} ]]; then
    log_red2 "${g_conf_file}配置的环境[${environment_pickup}]服务器数量为0"
    exit 1
  fi

  log_blue2 "${g_conf_file}配置的环境[${environment_pickup}]共 ${#LOGIN_INFO_ARR[*]} 个服务器"

  for index in "${!LOGIN_INFO_ARR[@]}"; do
    local LOGIN_INFO_LINE_STR="${LOGIN_INFO_ARR[$index]}"
    # 字符串转为数组
    local LOGIN_INFO_LINE=(`echo ${LOGIN_INFO_ARR[$index]} | tr ',' ' '`)

    # 获得配置数组的元素总数
    local length=$(eval echo "\${#LOGIN_INFO_LINE[*]}")

    #-lt，小于
    #-le，小于等于
    #-eq，等于
    #-ge，大于等于
    #-gt，大于
    #-ne，不等于
    if [[ ${length} -ne ${def_length} ]]; then
      log_red2 "${LOGIN_INFO_LINE_STR} \n\t配置项必须是 ${def_length} 项，目前是 ${length} 项。脚本停止检查、终止执行、退出！"
      exit 1
    fi

    if [[ "${flag_auth_type_Password}" != "$(eval echo \${LOGIN_INFO_LINE[${idx_authentication}]})" ]] && [[ "${flag_auth_type_PrivateKey}" != "$(eval echo \${LOGIN_INFO_LINE[${idx_authentication}]})" ]]; then
      log_red2 "${LOGIN_INFO_LINE_STR} \n\t配置登陆方式错误，脚本停止检查、终止执行、退出！"
      exit 1
    fi

    if [[ "${flag_auth_type_PrivateKey}" == "$(eval echo \${LOGIN_INFO_LINE[${idx_authentication}]})" ]]; then
      if [[ ! "$(eval echo \${LOGIN_INFO_LINE[${idx_private_key_file}]})" ]] || [[ "${flag_field_empty}" == "$(eval echo \${LOGIN_INFO_LINE[${idx_private_key_file}]})" ]] ; then
        log_red2 "${LOGIN_INFO_LINE_STR} \n\t配置为密钥登陆，但是没有配置密钥文件，脚本停止检查、终止执行、退出！"
        exit 1
      fi
    fi

    if [[ "${flag_auth_type_PrivateKey}" == "$(eval echo \${LOGIN_INFO_LINE[${idx_authentication}]})" ]]; then
      if [ ! -f "${idx_private_key_file}" ]; then
        log_red2 "配置行 ${LOGIN_INFO_LINE_STR} \n\t里的密钥文件 ${idx_private_key_file} not exist"
        exit 1
      fi
    fi
    # 检查不能为空的项目
    for i in $(seq 0 "$((length - 1))"); do
      if [ 5 -eq "${i}" ] || [ 6 -eq "${i}" ]|| [ 7 -eq "${i}" ] ; then
        continue
      fi

      if [ ! "$(eval echo \${LOGIN_INFO_LINE[${i}]})" ]; then
        local LOGIN_INFO_CONFIGURE_NUM=$((i + 1))
        log_red2 "${LOGIN_INFO_LINE_STR} \n\t第 ${LOGIN_INFO_CONFIGURE_NUM} 项配置不能为空"
        exit 1
      fi
    done
  done

}

function f_screen_echo_environment_arr() {
  log_blue2 "环境列表信息："
  flag_line="$(printf "%17s" "*")"
  flag_line=${flag_line// /*}
  log_blue2 "${flag_line}"
  local format_title=$(printf " %2s | %s" "id" "environment")
#  printf " \e[37;41m%s\e[0m \n" "${format_title}"
  printf " %s \n" "${format_title}"
#  log_blue2 "${flag_line}"
  for index in "${!environment_arr[@]}"; do
    printf "  %2s | %s  \n" "${index}" "${environment_arr[${index}]}"
  done
  log_blue2 "${flag_line}"


}

function f_choice_environment() {
  while true; do

    # 让使用者选择所需要登陆服务器的所属序号
    read -p '请输入环境id进行选择(输入 q 退出 )： ' CHOICE_ENV_NUM

    if [[ "${CHOICE_ENV_NUM}" == "q" ]]; then
      log_red2 '退出'
      exit 0
    fi

    if [[ "${CHOICE_ENV_NUM}" =~ [^0-9]+ ]]; then
      log_red2 '序号是数字'
      continue
    fi

    if [ ! ${CHOICE_ENV_NUM} ]; then
      log_red2 '请输入序号'
      continue
    fi

    if [[ "${CHOICE_ENV_NUM}" =~ ^0 ]] && [[ "${CHOICE_ENV_NUM}" -ne 0 ]]; then
      log_red2 '序号不能以 0 开头'
      continue
    fi

    # 用户选择的序号 > 环境总数、用户选择的序号 < 0。则提示错误并且重新循环
    if [[ ${CHOICE_ENV_NUM} -ge ${#environment_arr[@]} ]] || [[ ${CHOICE_ENV_NUM} -lt 0 ]]; then
      log_red2 '请输入存在的序号'
      continue
    fi

    environment_pickup=${environment_arr[${CHOICE_ENV_NUM}]}
    environment_pickup=$(echo "$environment_pickup" | cut -d ',' -f1)
    log_blue2 "选择的环境是 ${environment_pickup}"
    break
  done

}

function f_choice_server() {
  while true; do

    # 让使用者选择所需要登陆服务器的所属序号
    read -p '请输入服务器id进行选择(输入 q 退出 )： ' CHOICE_SEVRICE_NUM

    if [[ "${CHOICE_SEVRICE_NUM}" == "q" ]]; then
      log_red2 '退出'
      exit 0
    fi

    if [[ "${CHOICE_SEVRICE_NUM}" =~ [^0-9]+ ]]; then
      log_red2 '序号是数字'
      continue
    fi

    if [ ! ${CHOICE_SEVRICE_NUM} ]; then
      log_red2 '请输入序号'
      continue
    fi

    if [[ "${CHOICE_SEVRICE_NUM}" =~ ^0 ]] && [[ "${CHOICE_SEVRICE_NUM}" -ne 0 ]]; then
      log_red2 '序号不能以 0 开头'
      continue
    fi

    # 用户选择的序号 > 服务器总数、用户选择的序号 < 服务器总数。则提示错误并且重新循环
    if [[ ${CHOICE_SEVRICE_NUM} -ge ${#LOGIN_INFO_ARR[@]} ]] || [[ ${CHOICE_SEVRICE_NUM} -lt 0 ]]; then
      log_red2 '请输入存在的序号'
      continue
    fi
    LOGIN_INFO_SELECT=(`echo ${LOGIN_INFO_ARR[LOGIN_NUM]} | tr ',' ' '`)
    log_blue2 "选择的是 环境【${LOGIN_INFO_SELECT[${idx_environment}]}】\n 服务器【${LOGIN_INFO_SELECT[${idx_username}]}@${LOGIN_INFO_SELECT[${idx_hostname}]}】\n 标题【${LOGIN_INFO_SELECT[${idx_title}]}】 "
    printf " \e[30;40m 密码【%s】 \e[0m \n" "${LOGIN_INFO_SELECT[${idx_password}]}"
    break
  done

}

function f_login_info_configure_filter() {
  local v_csv_data="$@"
  local filtered=$(echo "$v_csv_data" | tr ' ' '\n' | awk -F '[,]' -v envirment_flag="${environment_pickup}" '{if($1==envirment_flag){print $0}}')
  echo "${filtered}"
}


# 计算列的最大宽度
function f_calculate_column_max_length() {
  for index in "${!LOGIN_INFO_ARR[@]}"; do
    local LOGIN_INFO_LINE=(`echo ${LOGIN_INFO_ARR[index]} | tr ',' ' '`)
    local user_ip_length=`expr ${#LOGIN_INFO_LINE[${idx_username}]} + 1 + ${#LOGIN_INFO_LINE[${idx_hostname}]}`
#    log_blue2 "${user_ip_length}  ${LOGIN_INFO_LINE[${idx_username}]}  ${LOGIN_INFO_LINE[${idx_hostname}]}"
    if [ ${max_colum_user_ip} -lt ${user_ip_length} ];then
      max_colum_user_ip=${user_ip_length}
    fi
    # 计算中文的个数，中文显示两个字宽（所以统计最大列宽时，需要统计两次中文字符），但是占用三个空格（所以在打印时，遇到中文需要再前面的基础上补一次中文的个数）
    local hint_zh_count=$(count_zh_char "${LOGIN_INFO_LINE[${idx_title}]}")
    local remark_length=${#LOGIN_INFO_LINE[${idx_title}]}
    remark_length=`expr ${remark_length} + ${hint_zh_count}`
    if [[ ${max_colum_remark} -lt ${remark_length} ]];then
      max_colum_remark=${remark_length}
    fi
  done
  max_colum_user_ip=`expr $max_colum_user_ip + 3`
  max_colum_remark=`expr $max_colum_remark + 3`
}


# 每两行字体变色
function f_screen_echo_2line_background_color() {

  # 处理中文字符占位符为2的问题
  # 计算中文的个数，中文显示两个字宽（所以统计最大列宽时，需要统计两次中文字符），但是占用三个空格（所以在打印时，遇到中文需要再前面的基础上补一次中文的个数）
  local hint_zh_count=$(count_zh_char "说明")
  local hint_width=$((hint_zh_count + ${max_colum_remark}))
  printf "|\e[37;41m %${max_colum_user_ip}s | %-3s | %-${hint_width}s \e[0m| \n" 'user@host' 'id' '说明'

  local color_flag=1 # 1是不开启颜色 0是开启
  _font_blue_background_write="\e[34;47m"
  _font_purple_background_write="\e[35;47m"
  _font_black_background_write="\e[30;47m"
  _font_blue_background_cyan="\e[34;46m"

# 0 _font_black _background_black
# 1 _font_red _background_red
# 2 _font_green _background_green
# 3 _font_yellow _background_yellow
# 4 _font_blue _background_blue
# 5 _font_purple _background_purple
# 6 _font_cyan _background_cyan
# 7 _font_white _background_white
## 显示shell的前景色和背景色
## for i in {0..7}; do for j in {0..7}; do print "\033[3${i};4${j}m文字色值 3${i}, 背景色值 4${j}\033[0m"; done ;done

  head_color_1=${_font_black_background_write}
  head_color_2=${_font_blue_background_cyan}

  head_color=${head_color_1}

  for index in "${!LOGIN_INFO_ARR[@]}"; do
    local LOGIN_INFO_LINE=(`echo ${LOGIN_INFO_ARR[index]} | tr ',' ' '`)

    # 处理中文字符占位符为2的问题
    # 计算中文的个数，中文显示两个字宽（所以统计最大列宽时，需要统计两次中文字符），但是占用三个空格（所以在打印时，遇到中文需要再前面的基础上补一次中文的个数）
    local hint_zh_count=$(count_zh_char "${LOGIN_INFO_LINE[${idx_title}]}")
    local hint_width=$((hint_zh_count + ${max_colum_remark}))

    printf "|${head_color} %${max_colum_user_ip}s | %-3s | %-${hint_width}s \e[0m| " "${LOGIN_INFO_LINE[${idx_username}]}@${LOGIN_INFO_LINE[${idx_hostname}]}" "${index}" "${LOGIN_INFO_LINE[${idx_title}]}"
    printf " \e[30;40m%-18s| \e[0m \n" "${LOGIN_INFO_LINE[${idx_password}]}"

    if [ `expr ${index} % 2` -eq 0 ]; then
      if [ ${color_flag} -eq 1 ];then
        color_flag=0
        head_color=${head_color_2}
      else
        color_flag=1
        head_color=${head_color_1}
      fi
    fi


  done
  printf "\e[0m %s \e[0m \n" ""
  # 服务器总数
  USER_SUM=${#LOGIN_INFO_ARR[*]}
}




# 登陆的函数
function f_login_exec() {

  select_username="${LOGIN_INFO_SELECT[${idx_username}]}"
  select_hostname="${LOGIN_INFO_SELECT[${idx_hostname}]}"
  select_port="${LOGIN_INFO_SELECT[${idx_port}]}"
  select_authentication="${LOGIN_INFO_SELECT[${idx_authentication}]}"
  select_password="${LOGIN_INFO_SELECT[${idx_password}]}"
  select_private_key_file="${LOGIN_INFO_SELECT[${idx_private_key_file}]}"

  select_user_ip="${select_username}@${select_hostname}"

  # 当登陆方式是密码时
  if [ "${flag_auth_type_Password}" == "$(eval echo \${select_authentication})" ]; then
    local mima=$(eval echo \${select_password})

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
switch $(eval echo \${select_authentication}) {
    \"${flag_auth_type_Password}\" {
        spawn -noecho ssh -o ConnectTimeout=15 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 $(eval echo \${select_user_ip}) -p $(eval echo \${select_port})
        expect {
            *yes/no* { send yes\r exp_continue }
            *denied* { exit }
            *password* { send ${mima}\r }
            *Password* { send ${mima}\r }
        }
        interact
    }
    \"${flag_auth_type_PrivateKey}\" {
        spawn -noecho ssh -o ConnectTimeout=15 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -i $(eval echo \${select_private_key_file}) $(eval echo \${select_user_ip}) -p $(eval echo \${select_port})
        interact
    }
    default {
        puts \"error\"
    }
}
"

  return 0

}


function f_main() {
  # 加载配置文件
  file_data=$(f_load_csv_config_file "${g_conf_file}")
  # 排序
  file_data=$(f_sort_csv_config_file "${file_data}")
  # 提取环境列表
  local environments=$(echo "${file_data}" | tr ' ' '\n' | awk -F ',' '{print $1}' | sort | uniq -c |awk '{print $2","$1}' |tr '\n' ' ' )
  # 转为数组
  environment_arr=(${environments})
  # 打印环境列表信息
  f_screen_echo_environment_arr
  # 选择环境信息
  f_choice_environment
  # 依据环境信息进行过滤
  file_data=$(f_login_info_configure_filter "${file_data}")
  # 转为数组
  LOGIN_INFO_ARR=(${file_data}) # LOGIN_INFO_ARR[] 的每一项就是配置文件的一行
  # 检查配置项
  f_login_info_configure_check

  #echo "索引为0的项： ${LOGIN_INFO_ARR[0]}"
  #echo "索引为1的项： ${LOGIN_INFO_ARR[1]}"
  #echo "数组的所有项： ${LOGIN_INFO_ARR[*]}"
  #echo "数组的个数： ${#LOGIN_INFO_ARR[*]}"
  # 计算列最大值
  f_calculate_column_max_length
  # 打印服务器列表
  f_screen_echo_2line_background_color
  f_choice_server
  f_login_exec
}


f_main $@