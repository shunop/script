#!/bin/bash

## ModifyDate: 20220608
echo "version: 1.1"
function f_config_yum_aliyun() {
  ## 仅使用新设置的国内源，先备份原先的源文件
  mkdir /etc/yum.repos.d/backup
  mv /etc/yum.repos.d/*.* /etc/yum.repos.d/backup
  ## 使用阿里云Yum源CentOS7
  curl -o /etc/yum.repos.d/CentOS7-Aliyun.repo http://mirrors.aliyun.com/repo/Centos-7.repo
  curl -o /etc/yum.repos.d/epel-7-Aliyun.repo http://mirrors.aliyun.com/repo/epel-7.repo
  ## 使用网易Yum源CentOS7
  #curl -o /etc/yum.repos.d/CentOS7-163-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
  ## 更新缓存
  yum clean all
  yum makecache
  ## 查看源列表
  yum repolist all
  ## 阿里云的各种源可以点击http://mirrors.aliyun.com/repo/
  yum -y update && yum -y upgrade
  echo "$(date)  =====配置阿里的yum源--end-success====="
}
function f_init_yum_install() {
  ## 原来的
#  yum -y install wget net-tools telnet netcat vim tcpdump isomd5sum screen nmap bind-utils bash-completion strace man-pages man-pages-overrides lsof psmisc traceroute iputils
  yum -y install wget net-tools telnet netcat vim tcpdump isomd5sum screen nmap bind-utils bash-completion strace man-pages man-pages-overrides lsof psmisc traceroute iputils tree sysstat dos2unix conntrack-tools
  ## 向鑫docker的
  ## yum install -y wget net-tools telnet tree nmap sysstat lrzsz dos2unix bind-utils conntrack-tools
#  yum -y install tree sysstat dos2unix conntrack-tools
  echo "$(date)  =====安装一些工具包--end-success====="
}
function f_config_PS1() {
    cat >> .bash_profile <<EOF

## 终端高亮主机名和当前路径
##PS1='[\u@\h \W]\$ '
PS1='[\e[32;40m\u@\h\e[0m \e[33;40m\w\e[0m]\$ '

EOF
  echo "$(date)  =====高亮主机名--end-success====="
}
function f_config_history() {
    cat >> .bash_profile << EOF

# 历史命令显示操作时间
if ! grep HISTTIMEFORMAT /etc/bashrc; then
    echo 'export HISTTIMEFORMAT="%F %T "' >> /etc/bashrc
fi

EOF
  echo "$(date)  =====历史命令显示操作时间--end-success====="
}
function f_config_close_firewall() {
  ## 关闭防火墙
  systemctl stop firewalld.service
  systemctl status firewalld.service
  echo "$(date)  =====关闭防火墙--end-success====="
}
function f_config_close_selinux() {
  ## 关闭selinux
  sed -i '/^SELINUX=enforcing/a\SELINUX=disabled' /etc/sysconfig/selinux
  sed -i 's/^SELINUX=enforcing/##&/g' /etc/sysconfig/selinux
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  echo "$(date)  =====关闭selinux【需要重启 reboot】--end-success====="
}
function f_config_close_swap() {
  ## 关闭swap
  swapoff -a
  echo "$(date)  =====关闭swap--end-success====="
}

f_config_yum_aliyun &&\
  f_init_yum_install &&\
  f_config_PS1 &&\
  f_config_history &&\
  f_config_close_firewall &&\
  f_config_close_selinux &&\
  f_config_close_swap
