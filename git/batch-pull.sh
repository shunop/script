#!/bin/bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2021-12-20
## Modified： 2021-12-20
## Version： v1.0.0
## Description: 批量更新git项目
## status: 可用
## example: sh batch-pull.sh /Users/shunop/gitlab

batch_pull(){
    v_path="$1"
    if [ ! -d "$v_path" ];then
      echo "$v_path 此文件不是目录"
      return 99
    fi

    cd "$v_path"
#    for dir in $(ls);do
    for dir in ./*;do
        if [ -d "$dir" ];then
            cd $dir
            echo "进入 $(pwd)"
#            git pull origin master; ## 这种更新方式不可取
            git pull;
            echo "$dir 更新完毕！"
            cd ..
            sleep 1
        else
            echo "$dir 此文件不是目录"
        fi
    done
}

batch_pull $@
echo "project项目组已全部更新"
