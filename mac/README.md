# mac上使用的一些脚本



[更新日志](https://github.com/shunop/script/wiki/%E6%9B%B4%E6%96%B0%E6%97%A5%E5%BF%97)



## batch-install-dmg.sh

> 功能: 根据配置文件分级批量安装dmg文件

#### 使用说明

帮助命令  `bash batch-install-dmg.sh -h` 

```shell
支持的操作: [cidhnV]
使用说明: bash batch-install-dmg.sh [-cihV] -d [dir_path] [-n config_name]
OPTIONS:
	-c: 生成配置文件默认配置,需修改 (-c|-i 二者不能同时使用)
	-i: 根据配置文件,执行批量安装操作 (-c|-i 二者不能同时使用)
	-d: dmg镜像所在文件夹的位置 (必选 后面必须跟参数)
		需要与 (-c|-i) 配合使用 eg: (-c -d) (-i -d)
	-h: 输出帮助信息 (可选)
	-n: 指定配置文件名 (可选)
	-V: 输出版本信息 (可选)
使用案例:
	step1. 创建配置文件
		bash batch-install-dmg.sh -c -d ~/Downloads
	step2. 执行批量安装操作
		bash batch-install-dmg.sh -i -d ~/Downloads
	查看帮助
		bash batch-install-dmg.sh -h
	查看版本
		bash batch-install-dmg.sh -V
```

#### 配置文件格式样例

```properties
#!#DO_INSTALL=FALSE
#!#VERSION=v1.0.2
## 20210116_185808
## 确保指定的安装目录下没有同名的软件,否则会掉跳过安装
## 支持行首带'#'的注释,安装时自动跳过注释行
## 行格式[安装包名:(0|1|2):密码]
## ':'后可指定的参数'0|1|2'
## '0'是安装到默认目录[/Applications]
## '1'是安装到脚本自定义目录[/Applications/dragInstallation]
## '2'是安装到测试目录[$HOME/Desktop/ins-tmp]
# BaiduNetdisk_mac_3.3.2.dmg:2
# ctfile.dmg:2
Firefox 84.0.2.dmg:2
# folx-downloader_mac.dmg:2
googlechrome.dmg:2
XZ 2020 for Mac 10.0.1.dmg:2:password
```





