#!/bin/bash

#********************************************************************************#
# 下载 argon主题
download_themes_argon()
{
	local plugin_path="$1"
	print_log "INFO" "download_themes_argon" "获取主题argon仓库代码..."
	
	local url="https://github.com/jerrykuku/luci-theme-argon.git?ref=master"
	if ! clone_repo_contents "$url" "$plugin_path/luci-theme-argon" $NETWORK_PROXY_CMD; then
		print_log "ERROR" "download_themes_argon" "获取luci-theme-argons仓库代码失败, 请检查!"
		return 1
	fi

	local url="https://github.com/jerrykuku/luci-app-argon-config.git?ref=master"
	if ! clone_repo_contents "$url" "$plugin_path/luci-theme-argon-config" $NETWORK_PROXY_CMD; then
		print_log "ERROR" "download_themes_argon" "获取luci-theme-argon-config仓库代码失败, 请检查!"
		return 2
	fi

	return 0
}

# 下载 edge主题
download_themes_edge()
{
	local plugin_path="$1"
	print_log "INFO" "download_themes_edge" "获取主题edge仓库代码..."
	
	local url="https://github.com/kiddin9/luci-theme-edge.git?ref=master"
	if ! clone_repo_contents "$url" "$plugin_path/luci-theme-edge" $NETWORK_PROXY_CMD; then
		print_log "ERROR" "download_themes_edge" "获取luci-theme-edge仓库代码失败, 请检查!"
		return 1
	fi

	return 0
}

#********************************************************************************#
# 设置默认主题
set_default_themes()
{
	print_log "INFO" "set_default_themes" "[修改默认主题]"
	local source_path="$1"
	
	local file="$source_path/feeds/luci/collections/luci/Makefile"
	if [[ -f "$file" ]]; then
		if sed -i 's/luci-light/luci-theme-argon/g' "$file"; then
			print_log "INFO" "set_default_themes" "[修改luci缺省主题成功]"
		else
			print_log "INFO" "set_default_themes" "[修改luci缺省主题失败],请检查!"
			return 1
		fi
	fi
	
	return 0
}

# 设置主题移除
set_themes_remove()
{
	local source_path="$1"
	
	local user_array=()
	local source_array=("$source_path")
	
	for value in "${source_array[@]}"; do
		# 排除数组
		local exclude_array=()
		
		# 排除json数组
		local exclude_json_array=$(build_json_array exclude_array)
		
		# 对象关联数组
		declare -A object_array=(
			["source_path"]="$value"
			["exclude_path"]=${exclude_json_array}
		)
		
		# 对象json数组
		local object_json=$(build_json_object object_array)
		user_array+=("$object_json")
	done
	
	local user_json_array=$(build_json_array user_array)
	
	# themes-config
	local user_config="themes-config"
	if ! remove_plugin_package "$user_config" "$OPENWRT_PLUGIN_FILE" "$user_json_array"; then
		print_log "ERROR" "set_plugin_remove" "移除主题配置$user_config失败,请检查!"
		return 1
	fi
	
	return 0
}

#********************************************************************************#
# 下载用户主题
download_user_themes()
{
	[[ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]] && ! input_prompt_confirm "是否需要下载用户主题?" && return 0
	
	local -n source_array_ref=$1
	local source_path="${source_array_ref["Path"]}"
	
	if [[ -z "$source_path" ]]; then
		print_log "ERROR" "download_user_themes" "[无效参数: 源码路径为空],请检查!"
		return 1
	fi
	
	local plugin_path="$source_path/package/${USER_CONFIG_ARRAY["plugins"]}/themes"
	mkdir -p "$plugin_path"
	
	# 移除主题插件
	if ! set_themes_remove "$source_path"; then
		print_log "ERROR" "download_user_themes" "[主题插件清理失败],请检查!"
		return 2
	fi
	
	# 下载 argon 主题
	if ! download_themes_argon "$plugin_path"; then
		print_log "ERROR" "download_user_themes" "[下载argon主题插件失败],请检查!"
		return 3
	fi
	
	return 0
}

# 设置主题配置
set_themes_config()
{
	local -n source_array_ref=$1
	local source_path="${source_array_ref["Path"]}"
	
	if [[ -z "$source_path" ]]; then
		print_log "ERROR" "set_themes_config" "[无效参数: 源码路径为空],请检查!"
		return 1
	fi
	
	# 设置默认主题
	if ! set_default_themes "$source_path"; then
		print_log "ERROR" "set_system_config" "[设置缺省主题失败],请检查!"
		return 2
	fi
}

#********************************************************************************#
# 设置自定义主题
set_user_themes()
{
	print_log "INFO" "set_user_plugin" "设置用户主题"
	
	# 下载用户主题
	if ! download_user_themes $1; then
		return 1
	fi
	
	# 设置主题配置
	if ! set_themes_config $1; then
		return 2
	fi
	
	return 0
}