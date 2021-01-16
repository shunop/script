# mac上使用的一些脚本



## batch-install-dmg.sh

> 功能: 根据配置文件分级批量安装dmg文件

#### 使用说明

帮助命令  `bash batch-install-dmg.sh -h` 

```shell
支持的操作: [cidhnVZ]
使用说明: bash batch-install-dmg.sh [-cihVZ] -d [dir_path] [-n config_name]
OPTIONS:
	-c: 生成配置文件默认配置,需修改 (-c|-i 二者不能同时使用)
	-i: 根据配置文件,执行批量安装操作 (-c|-i 二者不能同时使用)
	-d: dmg镜像所在文件夹的位置 (必选 后面必须跟参数)
		需要与 (-c|-i) 配合使用 eg: (-c -d) (-i -d)
	-h: 输出帮助信息 (可选)
	-n: 指定配置文件名 (可选)
	-V: 输出版本信息 (可选)
	-Z: (已弃用)进入交互式菜单 (可选)
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
#!#VERSION=1.0.1
###20210114_133830
# 确保指定的安装目录下没有同名的软件,否则会掉跳过安装
# 支持行首带'#'的注释,安装时自动跳过注释行
# ':'后可指定的参数'0|1|2'
# '0'是安装到默认目录[/Applications]
# '1'是安装到脚本自定义目录[/Applications/dragInstallation]
# '2'是安装到测试目录[$HOME/Desktop/ins-tmp]
# BaiduNetdisk_mac_3.3.2.dmg:2
# ctfile.dmg:2
Firefox 84.0.2.dmg:2
# folx-downloader_mac.dmg:2
googlechrome.dmg:2
```



#### v1.0.1

1. 支持辅助生成配置文件
2. 增加交互式菜单
3. 增加动态参数式菜单并弃用交互式菜单
4. 增加安全开关, 防呆设计
5. 校验配置文件的版本号
6. 校验目标位置有重名的就跳过
7. 增加安装日志输出到文件 `安装目录/batch-install-dmg.log` 
   1. 格式为 `时间戳:脚本名:版本:安装类型:app名:dmg文件位置` 

#### V1.0.0

1. 完成单个dmg安装
2. 文件夹内所有dmg批量安装
3. 根据配置文件批量安装
4. 旧版本(4版本以前)的bash不支持 `declare -A` 声明关联数组(即map结构) 改为简单数组
   1. `declare: usage: declare [-afFirtx] [-p] [name[=value] ...]` 
5. 解决路径空格问题,解决挂载磁盘空格问题

---

