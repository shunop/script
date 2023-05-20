#!/bin/bash
## Author: shunop
## Source:
## Created: 2021-01-25
## Modified： 2023-05-10
## Version： v1.0.1
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
#curl -O https://raw.githubusercontent.com/shunop/script/main/centos/init-centos7-out.sh
curl -O https://raw.githubusercontent.com/shunop/script/main/centos/auto-denyhosts.sh
echo '120.244.60.*' >> /etc/whitelist.txt
echo '*/1 * * * * /bin/bash /opt/src/auto-denyhosts.sh > /dev/null' >> /var/spool/cron/root

## 配置sshd
function f_config_sshd() {
  echo "===== 配置sshd ====="
  _back_file="/etc/ssh/sshd_config_bak_$(date +%Y%m%d_%H%M%S)"
  _is_changed="F"
  cp /etc/ssh/sshd_config "${_back_file}"

  res=$(grep '^GatewayPorts' /etc/ssh/sshd_config)
  if [[ -z "${res}" ]]; then
    _is_changed="S"
    echo "/etc/ssh/sshd_config 添加 [GatewayPorts yes] !"
    sed -i '/^#GatewayPorts/a\GatewayPorts yes' /etc/ssh/sshd_config
  fi
  res=$(grep '^ClientAliveInterval' /etc/ssh/sshd_config)
  if [[ -z "${res}" ]]; then
    _is_changed="S"
    echo "/etc/ssh/sshd_config 添加 [ClientAliveInterval 60] !"
    sed -i '/^#ClientAliveInterval/a\ClientAliveInterval 60' /etc/ssh/sshd_config
  fi
  res=$(grep '^ClientAliveCountMax' /etc/ssh/sshd_config)
  if [[ -z "${res}" ]]; then
    _is_changed="S"
    echo "/etc/ssh/sshd_config 添加 [ClientAliveCountMax 3] !"
    sed -i '/^#ClientAliveCountMax/a\ClientAliveCountMax 3' /etc/ssh/sshd_config
  fi
  if [[ "F" == "${_is_changed}" ]]; then
    rm -f "${_back_file}"
  fi
  systemctl restart sshd
}
f_config_sshd
