#!/bin/bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2021-01-25
## Modified： 2021-01-25
## Version： v1.0.0
## Description: Init centos environment
## 未验证

V_SSHD_PORT=19222

random_string() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

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

## 初始化swap交换区
function f_init_swap() {
#  参考 https://blog.csdn.net/duokongshi/article/details/80999077
#  if [ 0 -eq $(free | grep 'Swap' | awk '$2>1024*1024*1' | wc -l) ]; then
  v_size=1024*1024*1
  if [ $v_size -lt $(free | grep 'Swap' | awk '{print $2}') ]; then
    echo '开启 Swap'
    ## 大约 5G
    dd if=/dev/zero of=/swapfile bs=1024 count=5120k
    mkswap /swapfile
    swapon /swapfile
    ## 持久化swap memory
    echo '/swapfile          swap            swap    defaults        0 0      # for centos 6' >>/etc/fstab
    chmod 600 /swapfile
    free -h
  else
    echo '已经开启，无需重新操作'
  fi
}

function f_config_openjdk() {
#  配置 Open-JDK 的环境变量
#  yum search java-11-openjdk									# 可以不用执行，查找安装包
#  yum install -y java-11-openjdk java-11-openjdk-devel		# 安装
  echo '配置 Open-JDK'
  cat >> /etc/profile <<EOF

# Open-Java Environment
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el7_9.x86_64
export JRE_HOME=\$JAVA_HOME/jre
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/jre/lib/tools.jar:\$JRE_HOME/lib:\$CLASSPATH
export PATH=\$JAVA_HOME/bin:\$PATH

EOF
  source /etc/profile
}
function f_config_oraclejdk() {
#  配置 Oracle-JDK 的环境变量
  echo '配置 Oracle-JDK'
  cat >> /etc/profile <<EOF

# Oracle-Java Environment
export JAVA_HOME=/usr/local/java/jdk1.8.0_201
export JRE_HOME=\${JAVA_HOME}/jre
export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib
export PATH=\${JAVA_HOME}/bin:\$PATH

EOF
  source /etc/profile
}


function f_init_java() {
  # 检查
  rpm -qa | grep java
  yum list installed | grep java

  v_arch=$(uname -m)
  v_x86_64='x86_64'
  echo "cpu架构是: $(uname -m)"
#  mkdir ~/wget && cd ~/wget
#  wget -c https://download.oracle.com/otn/java/jdk/8u221-b11/230deb18db3e4014bb8e3e8324f81b43/jdk-8u221-linux-x64.tar.gz
  mkdir /usr/local/java
  mkdir ~/myupload
  md5sum ~/myupload/jdk-8u201-linux-x64.tar.gz
#  f4198016c840e227bb185bb1c1042a9f
  tar -zxvf ~/myupload/jdk-8u201-linux-x64.tar.gz -C /usr/local/java/
  # 创建软链接
  ln -s /usr/local/java/jdk1.8.0_201/bin/java /usr/bin/java
}

function f_init_redis() {
#  不要执行此方法
  REDIS_PASSWORD=$(random_string 32)
  echo "redis password is : ${REDIS_PASSWORD}"
  wget https://raw.githubusercontent.com/antirez/redis/4.0/redis.conf -O conf/redis.conf
  sed -i 's/logfile ""/logfile "access.log"/g' conf/redis.conf
  sed -i "s/# requirepass foobared/requirepass $REDIS_PASSWORD/g" conf/redis.conf
  sed -i 's/appendonly no/appendonly yes/g' conf/redis.conf
  docker run -di --name sofa_redis -p 16379:6379 -v /opt/myDocker/redis/data:/data -v /opt/myDocker/redis/conf/redis.conf:/etc/redis/redis.conf  redis  redis-server /etc/redis/redis.conf
  docker  exec -it sofa_redis  redis-cli
  # 防火墙
  firewall-cmd --permanent --add-port=16379/tcp
  firewall-cmd --reload
}

function f_init_yum() {
  yum -y install tree
  yum -y install lrzsz
  yum -y install netcat
  yum -y install telnet telnet-server
}

function f_init_deny_hosts() {
  service crond status




  # 参考 https://blog.csdn.net/mzc11/article/details/81842534
  # echo "* * * * * hostname >> /tmp/tmp.txt" >> /var/spool/cron/root
  # crontab -l > conf && echo "* * * * * hostname >> /tmp/tmp.txt" >> conf && crontab conf && rm -f conf
}


function f_init_change_ssh_port() {
  ## status:ok
  #port的最大值其实可以达到65535（2^16 - 1)
  #假定变量 a 为 10，变量 b 为 20：
  #-eq	检测两个数是否相等，相等返回 true。	[ $a -eq $b ] 返回 false。
  #-ne	检测两个数是否不相等，不相等返回 true。	[ $a -ne $b ] 返回 true。
  #-gt	检测左边的数是否大于右边的，如果是，则返回 true。	[ $a -gt $b ] 返回 false。
  #-lt	检测左边的数是否小于右边的，如果是，则返回 true。	[ $a -lt $b ] 返回 true。
  #-ge	检测左边的数是否大于等于右边的，如果是，则返回 true。	[ $a -ge $b ] 返回 false。
  #-le	检测左边的数是否小于等于右边的，如果是，则返回 true。	[ $a -le $b ] 返回 true。
  v_min=2000
  v_max=65535
  if [ $v_min -lt $V_SSHD_PORT ] && [ $V_SSHD_PORT -lt $v_max ]
  then
    true
  fi

# 不在区间内
  if (($V_SSHD_PORT < $v_min || $V_SSHD_PORT > $v_max)); then
#    return 99
    exit 
  fi

#  防火墙
  firewall-cmd --add-port=${V_SSHD_PORT}/tcp --permanent
  firewall-cmd --reload
# sshd 配置
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
  sed -i "s/^Port 22/#Port 22\nPort ${V_SSHD_PORT}/g" /etc/ssh/sshd_config
  ##不用变量的写法
  ##sed -i 's/^Port 22/#Port 22\nPort 19222/g' /etc/ssh/sshd_config
  systemctl restart sshd
}

# 初始化防火墙
f_init_firewall
# 初始化swap
f_init_swap
# 初始化java
f_init_java
# 配置环境变量
f_config_oraclejdk
