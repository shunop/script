#!/bin/bash
## Author: shunop
## Source: https://github.com/shunop/script
## Modified： 2021-01-16
## Version： 0.1-SNAPSHOT
## Status: 不可用
## Dmg batch installation script

version="version: 0.1-SNAPSHOT";

#### 安装dmg的
#### open -> install -> close
function doDmg-attach-install-detach() {
	VOLUME=`hdiutil attach $1 | grep Volumes | awk '{print $3}'`
	# cp -rf $VOLUME/*.app /Applications
	# cp -rf $VOLUME/*.app /Applications/0-dragInstallation
	hdiutil detach $VOLUME
}

# quietInstall

#### 后台服务类安装
function install-gradle() {
  true
}



function main() {
  true
}

param_count=$#
dest_path=$1
install_list=$2
#流程
#1.读取安装列表,说明:格式为[dmg文件路径:A|D]
#2.循环安装列表,


## 统计制定目录下以.app结尾的文件的个数
ls -al /Applications | grep ".app$" | wc -l
## 把指定目录下的dmg文件排序后的全路径输出到 install_list.config
ls ~/Downloads | grep -i ".dmg$"| sort -f | sed "s:^:`pwd`/:" | sed "s/$/&\:D/g" > install-list.properties
## 把指定目录下的dmg文件排序后拼接:D输出到 install_list.config
ls ~/Downloads | grep -i ".dmg$" | sort -f | sed "s/$/&\\:D/g" > install-list.properties
echo "#\!#DO_INSTALL=FALSE" > install-list.properties && ls ~/Downloads | grep -i ".dmg$" | sort -f | sed "s/$/&\\:D/g" >> install-list.properties
ls | grep -i ".dmg$" | sort -f | sed "s/$/&\:D/g" > install-list.properties

## 这样写是成功的
# wangs @ wsbook in ~/something [0:24:24] C:1
$ hdiutil detach "/Volumes/Google Chrome"
"disk2" ejected.


## 去掉所有引号
# VOLUME=$(echo "$VOLUME" | sed 's/\"//g')
## 行首行尾拼接引号,不用
## VOLUME=$(echo "$VOLUME" | sed 's/^/\"&/;s/$/&\"/')
## 过滤空格,不用
## VOLUME=$(echo "$VOLUME" | sed 's/ /\\ /g')


## 在文件开头添加一行
# sed '1i\ 
# #!#DO_INSTALL=TRUE' install-list.properties