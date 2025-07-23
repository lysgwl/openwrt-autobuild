#!/bin/bash

# 工作目录
OPENWRT_WORKDIR_NAME="workdir"

# 工作路径
OPENWRT_WORK_PATH=""

# 脚本当前路径
SCRIPT_CUR_PATH=""

# 输出路径
OPENWRT_OUTPUT_PATH=""

# 配置路径
OPENWRT_CONFIG_PATH=""

# 脚本配置文件
OPENWRT_CONF_FILE=""

# 脚本种子配置文件
OPENWRT_FEEDS_CONF_FILE=""

# 种子文件
OPENWRT_SEED_FILE=""

# 插件列表文件
OPENWRT_PLUGIN_FILE=""

# 网络代理命令
NETWORK_PROXY_CMD=""

# 固件JSON数组
FIRMWARE_JSON_ARRAY=""

# 固件JSON对象
FIRMWARE_JSON_OBJECT=""

# 编译模式
declare -A COMPILE_MODE
COMPILE_MODE[local_compile]=0
COMPILE_MODE[remote_compile]=1

# 源码类型
declare -A SOURCE_TYPE
SOURCE_TYPE[openwrt]=0
SOURCE_TYPE[istoreos]=1
SOURCE_TYPE[immortalwrt]=2
SOURCE_TYPE[coolsnowwolf]=3

# 项目配置
declare -gA SOURCE_CONFIG_ARRAY

# 用户配置
declare -gA USER_CONFIG_ARRAY

# 网络配置
declare -gA NETWORK_CONFIG_ARRAY

# 用户状态
declare -gA USER_STATUS_ARRAY

# 命令类型
declare -A CMD_TYPE
CMD_TYPE[autoCompileOpenwrt]=1
CMD_TYPE[cloneOpenWrtSrc]=2
CMD_TYPE[setOpenWrtFeeds]=3
CMD_TYPE[updateOpenWrtFeeds]=4
CMD_TYPE[setCustomConfig]=5
CMD_TYPE[setMenuOptions]=6
CMD_TYPE[downloadOpenWrtPackage]=7
CMD_TYPE[compileOpenWrtFirmware]=8
CMD_TYPE[getOpenWrtFirmware]=9

# 命令数组
CMD_ARRAY[${CMD_TYPE[autoCompileOpenwrt]}]="自动编译OpenWrt"
CMD_ARRAY[${CMD_TYPE[cloneOpenWrtSrc]}]="获取OpenWrt源码"
CMD_ARRAY[${CMD_TYPE[setOpenWrtFeeds]}]="设置OpenWrt feeds源"
CMD_ARRAY[${CMD_TYPE[updateOpenWrtFeeds]}]="更新OpenWrt feeds源"
CMD_ARRAY[${CMD_TYPE[setCustomConfig]}]="设置自定义配置"
CMD_ARRAY[${CMD_TYPE[setMenuOptions]}]="设置软件包目录"
CMD_ARRAY[${CMD_TYPE[downloadOpenWrtPackage]}]="下载OpenWrt包"
CMD_ARRAY[${CMD_TYPE[compileOpenWrtFirmware]}]="编译OpenWrt固件"
CMD_ARRAY[${CMD_TYPE[getOpenWrtFirmware]}]="获取OpenWrt固件"

# 种子数组
declare -A FEEDS_ARRAY
#FEEDS_ARRAY["helloworld"]="https://github.com/fw876/helloworld"
#FEEDS_ARRAY["passwall"]="https://github.com/xiaorouji/openwrt-passwall"
#FEEDS_ARRAY["kenzo"]="https://github.com/kenzok8/openwrt-packages"
#FEEDS_ARRAY["small"]="https://github.com/kenzok8/small"
#FEEDS_ARRAY["scw"]="https://github.com/songchenwen/openwrt-package"
#FEEDS_ARRAY["xwrt"]="https://github.com/x-wrt/com.x-wrt"
FEEDS_ARRAY["istore"]="https://github.com/linkease/istore;main"