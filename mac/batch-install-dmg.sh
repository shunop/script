#!/bin/bash
# author: shunop
# version: 1.0.1
# todo: 安装前校验dmg文件是否存在
# todo: 需要密码的dmg文件怎么处理
# todo: 检查目标文件夹是否存在,否则创建
declare v_author="shunop"
declare v_name="batch-install-dmg.sh"
declare v_version="1.0.1"

# ## 声明路径映射关系
declare v_path_map_arr
v_path_map_arr[0]="/Applications"
v_path_map_arr[1]="/Applications/0-dragInstallation"
v_path_map_arr[2]="$HOME/Desktop/bidsh_test"

## 校验用的常量
declare v_head_flag_true="#!#DO_INSTALL=TRUE"
declare v_head_flag_false="#!#DO_INSTALL=FALSE"
declare v_version_flag="#!#VERSION=${v_version}"

#### 安装dmg的方法: 挂载dmg, 把里面的app拷贝到指定目录, 推出dmg
#### open -> install -> close
function f_do_dmg_install() {
  v_dmg_path=$1
  v_dest_path=$2
  ## 1.非空校验
  if [[ -z "$v_dmg_path" ]] || [[ -z "$v_dest_path" ]]; then
    echo "\\t⚠️ ⚡️  安装包:[${v_dmg_path}],目标路径:[${v_dest_path}] 有一个为空"
    return
  fi

  ## 2.挂载并获取挂载的路径
  ## v_VOLUME=`hdiutil attach "$v_dmg_path" | grep Volumes | awk '{print $3}'`
  v_VOLUME=$(hdiutil attach "$v_dmg_path" | grep Volumes)
  ## 截取字符串Volumes右侧的全部
  v_VOLUME=${v_VOLUME#*\/Volumes}
  v_VOLUME="/Volumes$v_VOLUME"
  ## 去掉转义字符
  v_VOLUME=$(echo -e "$v_VOLUME")
  ## 说明:由于路径可能带空格,所以作为参数使用的时候要 "$v_VOLUME"

  ## 3.校验包下有几个 .app 文件
  ## 统计里面有几个 .app 文件
  v_count_app=$(ls -al "$v_VOLUME" | grep ".app$" | wc -l)
  ## 要打印的包内内容
  v_str=$(ls -al "$v_VOLUME" | grep ".app$")

  echo -e "\\t💽  挂载路径:$v_VOLUME\\t🈶 包下有["$v_count_app"]个.app"
  echo -e "\\t打印: $v_str"
  v_isok_installcheck="TRUE"
  ## 校验
  if [ $v_count_app != 1 ]; then
    v_isok_installcheck="FALSE"
    echo -e "\\t⚠️ ⚡️  安装包下.app数量不对"
  else
    v_app_name=$(ls "$v_VOLUME" | grep ".app$")
    v_count_dest_same_name_app=$(ls -a "$v_dest_path" | grep -i "$v_app_name" | wc -l)
    if [ $v_count_dest_same_name_app != 0 ]; then
      v_isok_installcheck="FALSE"
      echo -e "\\t⚠️ ⚡️ 目标路径[${v_dest_path}]下已存在名字为[${v_app_name}](不区分大小写)"
    fi
  fi
  ## 进行安装
  if [[ "TRUE" == "$v_isok_installcheck" ]]; then
    v_format_datetime="$(date "+%Y%m%d_%H%M%S")"
    # v_log_path=
    echo -e "\\t✅ ☀️  执行安装动作 time: ${v_format_datetime}"
    echo "${v_format_datetime}:${v_name}:${v_version}:copy:\"${v_app_name}\":\"${v_dmg_path}\"" >>"$v_dest_path"/batch-install-dmg.log

    cp -rf "${v_VOLUME}/"*.app "$v_dest_path"
    ### cp -rf $v_VOLUME/*.app /Applications
    ### cp -rf $v_VOLUME/*.app /Applications/0-dragInstallation
  else
    echo -e "\\t⚠️ ⚡️  跳过安装动作"
  fi
  ## 延时1s
  # sleep 1s
  hdiutil detach "$v_VOLUME"
}

## 批量安装处理
function f_batch_install() {
  ## v_config_path:配置文件位置
  v_config_path=$1
  v_dir_path=$(dirname "$v_config_path")
  while read -r line; do
    ## 1. 非空校验;字符串是空串 或者 以#开头就跳过
    if [[ -z "$line" ]] || [[ ${line:0:1} == \# ]]; then
      continue
    fi
    ## 2.提取dmg文件所在位置
    v_dmg_path=$(echo $line | awk -F ':' '{print $1}')
    v_dmg_path="${v_dir_path}/${v_dmg_path}"
    ## 去掉转义字符
    v_dmg_path=$(echo -e "$v_dmg_path")
    ## 说明:由于路径可能带空格,所以作为参数使用的时候要 "$v_dmg_path"

    ## 3.提取要安装的路径
    v_dest_path=$(echo $line | awk -F ':' '{print $2}')
    v_dest_path=${v_path_map_arr[$v_dest_path]}
    echo "安装包:["$v_dmg_path"],目标路径["$v_dest_path"]."

    ## 4.安装
    f_do_dmg_install "$v_dmg_path" "$v_dest_path"
  done <"$v_config_path"
}

## 安装前校验函数
function f_check_config() {
  v_dir_path=$1
  v_config_name=$2
  ## v_config_path:配置文件位置
  v_config_path="${v_dir_path}/${v_config_name}"
  ## 校验是不是文件
  if [ ! -f $v_config_path ]; then
    echo "⚠️ [${v_config_path}]文件不存在"
    echo -e "\t 需要先创建文件: bash ${v_name} -c -d ${v_dir_path}"
    exit 1
  fi
  ## 检查配置是不是允许安装
  v_isok_version="FALSE"
  v_isok_head="FALSE"
  while read -r line; do
    if [[ "$line" == "$v_head_flag_false" ]]; then
      echo "⚠️  修改默认配置[${v_head_flag_false}]为[${v_head_flag_true}],才能执行安装"
      exit 1
    elif [[ "$line" == "$v_head_flag_true" ]]; then
      v_isok_head="TRUE"
    elif [[ "$line" == "$v_version_flag" ]]; then
      v_isok_version="TRUE"
    fi
    ## 检查都通过则 return 0
    if [[ "TRUE" == "$v_isok_version" ]] && [[ "TRUE" == "$v_isok_head" ]]; then
      return 0
    fi

  done <"$v_config_path"
  ## 执行到这里是非预期的需要终止
  if [[ "TRUE" != "$v_isok_head" ]]; then
    ## 这个分支只有在文件中没有开关的时候才会走到
    echo "⚠️  需要把文件首行修改为[$v_head_flag_true],才能执行安装"
  fi
  if [[ "TRUE" != "$v_isok_version" ]]; then
    echo "⚠️  配置文件的版本和脚本的版本不对应,"
    echo "⚠️  请重新生成配置文件 bash batch-install-dmg.sh -c -d $v_dir_path"
  fi

  exit 1
}

## 生成配置文件的方法
function f_build_config() {
  v_dir_path=$1
  v_config_name=$2
  # ## 校验配置文件夹是否存在
  # if [[ ! -d $v_dir_path ]]
  # then
  # 	echo "⚠️  [${v_dir_path}]此路径不存在,或者不是文件夹"
  # 	exit 1
  # fi

  v_config_path="${v_dir_path}/${v_config_name}"
  # v_format_datetime="$(date "+%Y-%m-%d %H:%M:%S")"
  v_format_datetime="$(date "+%Y%m%d_%H%M%S")"

  ### echo "#\!#DO_INSTALL=FALSE" > batch-install-dmg.properties && ls ~/Downloads | grep -i ".dmg$" | sort -f | sed "s/$/&\\:D/g" >> batch-install-dmg.properties

  v_text="#!#DO_INSTALL=FALSE
#!#VERSION=${v_version}
###$v_format_datetime
# 确保指定的安装目录下没有同名的软件,否则会掉跳过安装
# 支持行首带'#'的注释,安装时自动跳过注释行
# ':'后可指定的参数'0|1|2'
# '0'是安装到默认目录[${v_path_map_arr[0]}]
# '1'是安装到脚本自定义目录[${v_path_map_arr[1]}]
# '2'是安装到测试目录[${v_path_map_arr[2]}]"
  echo -e "${v_text}" >"${v_config_path}"

  ls "$v_dir_path" | grep -i ".dmg$" | sort -f | sed "s/$/&\\:2/g" >>"${v_config_path}"
  echo "✅  生成的配置文件为: ${v_config_path}"
  echo -e "🔅  需要手动修改文件配置为[#!#DO_INSTALL=TRUE]\\n\\t注意\\t1.指定安装目录\\n\\t\\t2.不用安装的app注释掉\\n\\t\\t3.确保指定的安装目录下没有同名的软件,否则会掉跳过安装"
}

## 交互式菜单,已弃用
function f_interactive_menu() {
  select option in "Exit menu(退出)" "Create configuration(生成配置文件)" "Install according to configuration(根据配置文件安装)"; do
    case $option in
    *)
      ## 第一个是 * 的话就是所有参数都会走这里
      echo "⚠️  未执行任何操作,此菜单已弃用"
      exit 1
      ;;
    "Exit menu(退出)")
      echo "🔅  退出"
      break
      ;;
    "Create configuration(生成配置文件)")
      echo "🔅  生成配置文件"
      echo -e "\t1.输入的路径不能包含空格;"
      echo -e "\t2.输入的路径结尾不能带/;"
      echo -e "\t3.如果该路径下存在[batch-install-dmg.properties]的文件会覆盖;"
      read -n 1 -p "是否继续?(y/n): " flag
      if [[ ! "y" == "$flag" ]]; then
        break
      fi
      echo ""
      read -r -p "输入dmg所在文件夹绝对路径: " path
      # f_build_config $path
      break
      ;;
    "Install according to configuration(根据配置文件安装)")
      echo "🔅  根据配置文件安装"
      read -r -p "输入配置文件路径: " path
      echo $path
      echo "⚠️  未执行任何操作,此菜单已弃用"
      break
      ;;
    *)
      echo "sorry,wrong selection"
      ;;
    esac
  done
}

## 输出帮助信息
function f_manual() {
  text="支持的操作: [cidhnVZ]
使用说明: bash ${v_name} [-cihVZ] -d [dir_path] [-n config_name]
OPTIONS:
	-c: 生成配置文件默认配置,需修改 (-c|-i 二者不能同时存在)
	-i: 根据配置文件,执行批量安装操作 (-c|-i 二者不能同时存在)
	-d: dmg镜像所在文件夹的位置 (必选 后面必须跟参数)
		需要与 (-c|-i) 配合使用 eg: (-c -d) (-i -d)
	-h: 输出帮助信息 (可选)
	-n: 指定配置文件名 (可选)
	-V: 输出版本信息 (可选)
	-Z: (已弃用)进入交互式菜单 (可选)
使用案例: 
	step1. 创建配置文件
		bash batch-install-dmg.sh -c -d ~/Downloads
	step2. 执行批量安装操作
		bash batch-install-dmg.sh -i -d ~/Downloads
	查看帮助
		bash batch-install-dmg.sh -h
	查看版本
		bash batch-install-dmg.sh -V
	"

  # echo "功能说明: 批量安装dmg镜像文件"
  echo -e "$text"
  # echo "author: ${v_author} \tversion: ${v_version}"
}

## 无人值守的菜单
function f_unattended_menu() {
  while getopts "d:n:cihVZ" opts; do
    case $opts in
    c)
      ## v_creat_config:生成配置文件模式
      v_creat_config="TRUE"
      ;;
    i)
      ## v_install:安装模式
      v_install="TRUE"
      ;;
    d)
      ## v_dir_path:dmg文件路径位置
      v_dir_path=$OPTARG
      # echo "dmg文件路径位置: ${v_dir_path}"
      ;;
    h)
      f_manual
      exit 0
      ;;
    n)
      ## v_config_name:配置文件名字
      v_config_name=$OPTARG
      ;;
    V)
      echo "$v_version"
      exit 0
      ;;
    Z)
      f_interactive_menu
      exit 0
      ;;
    ?)
      echo -e "\t❌  不支持的操作!"
      echo -e "\t❌  missing  options,pls check!"
      f_manual
      exit 1
      ;;
    esac
  done
  ## 没有传入参数
  if [[ 1 == $OPTIND ]]; then
    echo "❌  不支持无参数,查看使用说明"
    f_manual
    exit 1
  fi
  ## 可选参数赋值
  v_creat_config=${v_creat_config:-"FALSE"}
  v_install=${v_install:-"FALSE"}
  v_config_name=${v_config_name:-"batch-install-dmg.properties"}
  ## 模式校验
  if [[ "TRUE" == "${v_creat_config}" ]] && [[ "TRUE" == "${v_install}" ]]; then
    echo "❌  -c 和 -i 不能同时存在"
    exit 1
  fi
  if [[ "FALSE" == "${v_creat_config}" ]] && [[ "FALSE" == "${v_install}" ]]; then
    echo "❌  -c 和 -i 必选一种"
    exit 1
  fi
  ## 必选参数存在性及参数合法性判断
  ## 校验文件夹是否存在
  if [ -z "${v_dir_path}" ] || [ ! -d "${v_dir_path}" ]; then
    # echo "❌  [${v_dir_path}]此路径不存在,或者不是文件夹"
    echo "❌  需要添加-d参数,传入文件夹路径"
    exit 1
  fi
  ## 相对路径转成绝对路径
  v_dir_path=$(cd $v_dir_path && pwd)
  v_config_path="${v_dir_path}/${v_config_name}"
  echo "dmg所在文件夹: ${v_dir_path}"
  echo "配置文件路径位置: ${v_config_path}"
  ## 创建配置文件模式
  if [[ "TRUE" == "${v_creat_config}" ]]; then
    echo "生成配置文件模式"
    f_build_config "${v_dir_path}" "${v_config_name}"

    ## 回显配置文件
    echo -e "\\ncat $v_config_path"
    cat "${v_config_path}"
  fi
  ## 批量安装模式
  if [[ "TRUE" == "${v_install}" ]]; then
    echo "安装模式"
    f_check_config "${v_dir_path}" "${v_config_name}"
    f_batch_install "${v_config_path}"

    ## 更改开关
    sed -i '' 's/DO_INSTALL=TRUE/DO_INSTALL=FALSE/g' "${v_config_path}"
    echo -e "\\n安装完成\\n已经把${v_config_path}的配置[${v_head_flag_true}]设置为[${v_head_flag_false}]"

    ## 回显配置文件
    echo -e "\\ncat $v_config_path"
    cat "${v_config_path}"
  fi
  echo ""
  echo "🎉  successful!"

}

## 无人值守菜单
## $@ 以"$1" "$2" … "$n" 的形式输出所有参数
f_unattended_menu $@
