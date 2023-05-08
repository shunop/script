#!/bin/bash
## Author: shunop
## Source:
## Created: 2021-01-25
## Modified： 2021-01-25
## Version： v1.0.0
## Description: Init centos environment


V_SSHD_PORT=19222


random_string() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}



echo 'export HISTTIMEFORMAT="%F %T "' >> /etc/bashrc
echo "PS1='[\e[32;40m\u@\h\e[0m \e[33;40m\w\e[0m]\$ '" >> /etc/bashrc
source /etc/bashrc
# yum -y install wget net-tools telnet netcat vim tcpdump isomd5sum nmap bind-utils bash-completion strace man-pages man-pages-overrides lsof psmisc traceroute iputils tree sysstat dos2unix conntrack-tools
yum -y install wget net-tools telnet netcat vim tcpdump isomd5sum nmap bind-utils bash-completion strace lsof traceroute tree

## 配置时区
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

mkdir -p /opt/src/
cd /opt/src/
#wget https://storage.googleapis.com/tiziblog/xray.sh

## 配置 auto-denyhosts.sh
curl -O https://raw.githubusercontent.com/shunop/script/main/centos/auto-denyhosts.sh
echo '120.244.60.*' >> /etc/whitelist.txt
echo '*/1 * * * * /bin/bash /opt/src/auto-denyhosts.sh > /dev/null' >> /var/spool/cron/root

