#!/bin/bash

# 添加防重复加载检查
[[ -n "${_COMMON_SH_LOADED}" ]] && return 0
_COMMON_SH_LOADED=1

# 初始标识
readonly RUN_INIT_LOCK="/var/run/run_init_flag.pid"

# 加载环境变量
source $SCRIPTS_DIR/settings/options.sh

# 加载日志脚本
source $SCRIPTS_DIR/utils/lib/log_utils.sh

# 加载功能函数
source $SCRIPTS_DIR/utils/feature.sh

# 加载功能模块
load_feature "utils" "$SCRIPTS_DIR/utils/lib" || {
	print_log "ERROR" "COMMON" "加载通用模块失败, 请检查!"
	exit 1
}

# 加载配置模块
load_feature "config" "$SCRIPTS_DIR/settings" || {
	print_log "ERROR" "COMMON" "加载配置模块失败, 请检查!"
	exit 1
}

# 加载核心功能
load_feature "core" "$SCRIPTS_DIR/core" || {
	print_log "ERROR" "COMMON" "加载核心功能失败, 请检查!"
	exit 1
}

# 加载设置模块
load_module "plugin-setup" "$SCRIPTS_DIR/diyscripts" && 
load_module "themes-setup" "$SCRIPTS_DIR/diyscripts" &&
load_module "system-setup" "$SCRIPTS_DIR/diyscripts" &&
load_module "network-setup" "$SCRIPTS_DIR/diyscripts" || {
	print_log "ERROR" "COMMON" "加载设置功能失败, 请检查!"
	exit 1
}

# 加载导入功能
load_module "loader" "$SCRIPTS_DIR/dispatcher" || {
	print_log "ERROR" "COMMON" "加载导入功能失败, 请检查!"
	exit 1
}