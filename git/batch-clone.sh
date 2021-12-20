#!/bin/bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2021-12-20
## Modified： 2021-12-20
## Version： v1.0.0
## Description: 批量下载git仓库的项目
## status: 不可用

code_addr=(
'git@gitlab.com:project/project1.git'
'git@gitlab.com:project/project2.git'
'git@gitlab.com:project/project3.git'
)
website_dir=website
clone_code(){
	#判断文件夹是否存在
	if [ -d $website_dir ];then
		echo "文件夹存在"
		cd $website_dir
	else
		echo "文件不存在，创建$website_dir文件夹"
		mkdir $website_dir && cd $website_dir
    fi
	#批量克隆项目代码
	for i in ${code_addr[@]}
		do
			git clone $i
	done
}
clone_code
echo "website项目组已拉取完毕！"
