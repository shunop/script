#!/bin/bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2021-01-25
## Modified： 2021-01-25
## Version： v1.0.0
## Description: Init centos environment

function f_init_firewall() {
#  systemctl start firewalld
#  systemctl status firewalld
  ## 设置firewall开机启动
  systemctl enable firewalld
  ## 禁止firewall开机启动
#  systemctl disable firewalld
}

function f_init_docker() {
  curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
}

function f_init_pip() {
  yum -y install epel-release python-pip
}


