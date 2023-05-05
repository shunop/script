#!/bin/bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2019-07-29
## Modified： 2021-01-25
## Version： v1.0.0
## Description: Denyhosts SHELL SCRIPT

FILE_WHITELIST="/etc/whitelist.txt"

cat /var/log/secure | awk '/Failed/{print $(NF-3)|"sort"}' | uniq -c | sort -nr | awk '{print $2"=" $1;}' >/root/.denyhosts_tmp.txt
#定义失败的次数
DEFINE="5"
for i in $(cat /root/.denyhosts_tmp.txt); do
  IP=$(echo $i | awk -F= '{print $1}')
  NUM=$(echo $i | awk -F= '{print $2}')
  if [ $NUM -gt $DEFINE ]; then
    ipExists=$(grep $IP /etc/hosts.deny | grep -v grep | wc -l)
    #上下等同
    #ipExists=`grep $IP /root/hosts.deny |grep -v grep |wc -l`
    if [ $ipExists -lt 1 ]; then
      # 这个ip 不在 /etc/hosts.deny 文件中，则追加
      echo "sshd:$IP"
      echo "sshd:$IP" >>/etc/hosts.deny
      #echo "sshd:$IP" >> /root/hosts.deny
    fi
  fi
done
echo "do blacklist end"

## 白名单
if [ ! -f "$FILE_WHITELIST" ]; then
  echo "$FILE_WHITELIST not exist"
  exit 0
fi
for i in $(cat "$FILE_WHITELIST"); do
  ipExists=$(grep "$i" /etc/hosts.deny | grep -v grep | wc -l)
  if [ $ipExists -gt 0 ]; then
    # 这个ip 在 /etc/hosts.deny 文件中，则去掉
    echo "whitelist:$i"
    sed -i "/$i/d" /etc/hosts.deny
  fi
done
echo "do whitelist end"