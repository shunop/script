# Centos上的一些脚本



## steam/automatic-dst.sh

> 一键更新重启脚本, 可配合crontab使用

```shell
bash <(curl -fsSL https://raw.githubusercontent.com/shunop/script/main/centos/steam/automatic-dst.sh) load
或者
curl -fsSL https://raw.githubusercontent.com/shunop/script/main/centos/steam/automatic-dst.sh | bash -s load
```



## steam/install-steam-dst.sh

>一键安装dst脚本

创建 `steamgame` 用户, 并在此用户下执行 `dst` 安装脚本

```shell
useradd -m steamgame && su - steamgame -c bash -c "$(curl -fsSL https://raw.githubusercontent.com/shunop/script/main/centos/steam/install-steam-dst.sh)"
```

若已经创建好该用户则执行

```shell
su - steamgame -c bash -c "$(curl -fsSL https://raw.githubusercontent.com/shunop/script/main/centos/steam/install-steam-dst.sh)"
```

> 需要到 raw.githubusercontent.com 上拉取代码
>
> 报错解决curl: (7) Failed connect to raw.githubusercontent.com:443; Connection refused
>
> https://github.com/hawtim/blog/issues/10
>
> **解决方案**
>
> 打开 https://www.ipaddress.com/ 输入访问不了的域名, 查询之后可以获得正确的 IP 地址, 在本机的 host 文件中添加
>
> 比如
>
> ```shell
> echo "199.232.68.133 raw.githubusercontent.com" >> /etc/hosts
> ```
>
> 199.232.68.133 raw.githubusercontent.com
> 199.232.68.133 user-images.githubusercontent.com
> 199.232.68.133 avatars2.githubusercontent.com
> 199.232.68.133 avatars1.githubusercontent.com

