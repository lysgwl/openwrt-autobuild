#!/bin/bash

# 设置插件
set_openwrt_plugins()
{
	print_log "INFO" "set_openwrt_plugins" "正在获取第三方插件..."
	local -n set_source_array=$1
	
	# 设置插件路径
	local plugin_path="${set_source_array["Path"]}/package/${USER_CONFIG_ARRAY["plugins"]}/plugins" 
	if [ ! -d "${plugin_path}" ]; then
		mkdir -p "${plugin_path}"
	fi
	
	# 设置用户插件
	if ! set_user_plugin ${plugin_path} set_source_array; then
		return 1
	fi

	return 0
}

# 设置主题
set_openwrt_themes()
{
	print_log "INFO" "set_openwrt_themes" "正在设置自定义主题..."
	local -n set_source_array=$1

	# 设置主题路径
	local plugins_path="${set_source_array["Path"]}/package/${USER_CONFIG_ARRAY["plugins"]}/themes" 
	if [ ! -d "${plugins_path}" ]; then
		mkdir -p "${plugins_path}"
	fi
	
	# 设置自定义主题
	if ! set_user_themes ${plugins_path} set_source_array; then
		return 1
	fi
	
	return 0
}

# 设置配置
set_openwrt_config()
{
	print_log "INFO" "set_openwrt_config" "正在设置缺省配置..."
	local -n set_source_array=$1
	
	# 设置自定义配置
	set_user_config set_source_array
	
	# 设置自定义网络
	set_user_network set_source_array
}