# Centos上的一些脚本



## centos/steam/install-steam-dst.sh



创建 `steamgame` 用户, 并在此用户下执行 `dst` 安装脚本

```shell
useradd -m steamgame && su - steamgame -c bash -c "$(curl -fsSL https://raw.githubusercontent.com/shunop/script/main/centos/steam/install-steam-dst.sh)"
```

