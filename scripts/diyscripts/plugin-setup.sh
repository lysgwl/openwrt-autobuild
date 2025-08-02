#!/bin/bash

#********************************************************************************#
# 下载other package
download_other_package()
{
	local plugin_path="$1"
	
	local url="https://github.com/lysgwl/openwrt-package.git/otherpackage?ref=master"
	print_log "INFO" "download_other_package" "获取otherpackage仓库代码..."
	
	if ! get_remote_spec_contents "$url" "other" "$plugin_path" $NETWORK_PROXY_CMD; then
		print_log "ERROR" "download_other_package" "获取otherpackage仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载golang
download_golang()
{
	local source_path="$1"
	
	local url="https://github.com/sbwml/packages_lang_golang.git?ref=23.x"
	print_log "INFO" "download_golang" "获取golang仓库代码..."
	
	if ! clone_repo_contents "$url" "$source_path/feeds/packages/lang/golang" $NETWORK_PROXY_CMD; then
		print_log "ERROR" "download_golang" "获取golang仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载shidahuilang package
download_shidahuilang_package()
{
	local plugin_path="$1"
	
	local url="https://github.com/lysgwl/openwrt-package.git/shidahuilang?ref=master"
	print_log "INFO" "download_shidahuilang_package" "获取shidahuilang仓库代码..."
	
	if ! get_remote_spec_contents "$url" "$plugin_path" $NETWORK_PROXY_CMD; then
		print_log "ERROR" "download_shidahuilang_package" "获取shidahuilang仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载kiddin9 package
download_kiddin9_package()
{
	local plugin_path="$1"
	
	local url="https://github.com/lysgwl/openwrt-package.git/kiddin9/master?ref=master"
	print_log "INFO" "download_kiddin9_package" "获取kiddin9仓库代码..."
	
	if ! get_remote_spec_contents "$url" "$plugin_path" $NETWORK_PROXY_CMD; then
		print_log "ERROR" "download_kiddin9_package" "获取kiddin9仓库代码失败, 请检查!"
		return 1
	fi
		
	return 0
}

# 下载siropboy package
download_siropboy_package()
{
	local plugin_path="$1"
	
	local url="https://github.com/sirpdboy/sirpdboy-package.git?ref=main"
	print_log "INFO" "download_siropboy_package" "获取sirpdboy-package仓库代码..."
	
	if ! clone_repo_contents "$url" "$plugin_path" $NETWORK_PROXY_CMD; then
		print_log "ERROR" "download_siropboy_package" "获取sirpdboy-package仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

#********************************************************************************#
# 设置light插件
set_light_depends()
{
	local source_path="$1"
	print_log "INFO" "set_light_depends" "[设置插件luci-light相关依赖]"
	
	local paths=(
		"$source_path/feeds/luci/collections/luci-light"
		"$source_path/feeds/luci/collections/luci-ssl/Makefile"
		"$source_path/feeds/luci/collections/luci-ssl-openssl/Makefile"
	)
	
	for path in "${paths[@]}"; do
		local plugin_name=$(basename "$([ -d "$path" ] && echo "$path" || dirname "$path")")
		
		if [ -d "$path" ]; then	
			print_log "INFO" "set_light_depends" "[删除插件目录: $plugin_name]"
			rm -rf "$path"
		elif [ -f "$path" ]; then
			print_log "INFO" "set_light_depends" "[移除插件$plugin_name的依赖: luci-light]"
			remove_keyword_file "+luci-light" "$path"
		fi
	done
}

# 设置uhttpd插件依赖
set_uhttpd_depends()
{
	[[ ${USER_CONFIG_ARRAY["nginxcfg"]} -ne 1 ]] && return 0
	
	local source_path="$1"
	print_log "INFO" "set_uhttpd_depends" "[设置uhttpd编译依赖]"
	
	local file="$source_path/feeds/luci/collections/luci/Makefile"
	local keywords=(
		"+uhttpd"
		"+uhttpd-mod-ubus"
	)
	
	local plugin_name=$(basename $(dirname "$file"))
	
	if [[ -f "$file" ]]; then
		for keyword in "${keywords[@]}"; do
			print_log "INFO" "set_uhttpd_depends" "[移除插件 $plugin_name 的依赖: $keyword]"
			remove_keyword_file "$keyword" "$file"
		done
	fi
}

# 设置bootstrap插件
set_bootstrap_depends()
{
	local source_path="$1"
	
	# 取消luci-nginx对luci-theme-bootstrap依赖
	print_log "INFO" "set_bootstrap_depends" "[设置插件luci-nginx依赖]"
	
	local paths=(
		"$source_path/feeds/luci/collections/luci-nginx/Makefile"
		"$source_path/feeds/luci/collections/luci-ssl-nginx/Makefile"
	)
	
	local keyword="+luci-theme-bootstrap"
	
	for file in "${paths[@]}"; do
		local plugin_name=$(basename $(dirname "$file"))
		
		if [[ -f "$file" ]]; then
			print_log "INFO" "set_bootstrap_depends" "[移除插件 $plugin_name 的依赖: $keyword]"
			remove_keyword_file "$keyword" "$file"
		fi
	done
}

# 设置docker插件
set_docker_depends()
{
	local source_path="$1"
	
	# 取消luci-app-dockerman对docker-compose依赖
	print_log "INFO" "set_docker_depends" "[设置插件luci-app-dockerman依赖]"
	
	local file="${source_path}/feeds/luci/applications/luci-app-dockerman/Makefile"
	remove_keyword_file "+docker-compose" ${file}
}

# 设置nginx插件
set_nginx_plugin()
{
	[[ ${USER_CONFIG_ARRAY["nginxcfg"]} -ne 1 ]] && return 0
	
	local source_path="$1"
	print_log "INFO" "set_nginx_plugin" "[设置nginx配置文件]"
	
	# 修改nginx配置文件
	local nginx_cfg="$source_path/feeds/packages/net/nginx-util/files/nginx.config"
	if [[ -f "$nginx_cfg" ]]; then
		if grep -q "302 https://\$host\$request_uri" "$nginx_cfg"; then
			if ! grep -q "^#.*302 https://\$host\$request_uri" "$nginx_cfg"; then
				if sed -i "/.*302 https:\/\/\$host\$request_uri/s/^/#/g" "$nginx_cfg"; then
					print_log "INFO" "set_default_themes" "[注释nginx配置成功]"
				else
					print_log "INFO" "set_default_themes" "[注释nginx配置失败],请检查!"
					return 1
				fi
			fi
		fi
		
		if ! grep -A 1 '302 https://$host$request_uri' "$nginx_cfg" | grep -q 'restrict_locally'; then
			if sed -i "/302 https:\/\/\$host\$request_uri/ a\ \tlist include 'restrict_locally'\n\tlist include 'conf.d/*.locations'" "$nginx_cfg"; then
				print_log "INFO" "set_default_themes" "[添加nginx配置成功]"
			else
				print_log "INFO" "set_default_themes" "[添加nginx配置失败],请检查!"
				return 2
			fi
		fi
	fi
	
	return 0
}

# 设置插件依赖
set_plugin_depends()
{
	# 设置uhttpd依赖
	set_uhttpd_depends "$1"
	
	# 设置light依赖
	set_light_depends "$1"
	
	# 设置bootstrap依赖
	set_bootstrap_depends "$1"
	
	# 设置docker依赖
	#set_docker_depends "$1"
}

# 设置插件UI 
set_plugin_webui()
{
	:
}

# 移除插件
set_plugin_remove()
{
	local source_path=$1
	local source_alias=$2
	local plugin_path=$3

	local user_array=()
	local source_array=("$source_path/package" "$source_path/feeds")
	
	for value in "${source_array[@]}"; do
		# tr 命令来去除空格
		local last_field=$(echo "${value##*/}" | tr -d '[:space:]')
		
		# 排除数组
		local exclude_array=()
		if [ "$last_field" == "package" ]; then
			exclude_array=("$plugin_path")
		elif [ "$last_field" == "feeds" ]; then
			exclude_array=()
		fi
		
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
	
	# common_config
	local user_config="common_config"
	if ! remove_plugin_package "$user_config" "$OPENWRT_PLUGIN_FILE" "$user_json_array"; then
		print_log "ERROR" "set_plugin_remove" "移除插件配置 $user_config失败,请检查!"
		return 1
	fi
	
	#
	user_config="${source_alias}_config"
	if ! remove_plugin_package "$user_config" "$OPENWRT_PLUGIN_FILE" "$user_json_array"; then
		print_log "ERROR" "set_plugin_remove" "移除插件配置 $user_config失败,请检查!"
		return 1
	fi
	
	# 删除golang源码目录
	rm -rf "$source_path/feeds/packages/lang/golang"
	return 0
}

#********************************************************************************#
# 下载插件
download_user_plugin()
{
	[[ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]] && ! input_prompt_confirm "是否需要下载用户插件?" && return 0
	
	local -n source_array_ref=$1
	local source_path="${source_array_ref["Path"]}"
	local source_alias="${source_array_ref["Alias"]}"
	
	if [[ -z "$source_path" || -z "$source_alias" ]]; then
		print_log "ERROR" "download_user_plugin" "[无效参数: 参数验证为空],请检查!"
		return 1
	fi
	
	local plugin_path="$source_path/package/${USER_CONFIG_ARRAY["plugins"]}/plugins"
	mkdir -p "$plugin_path"
	
	# 移除插件
	if ! set_plugin_remove "$source_path" "$source_alias" "$plugin_path"; then
		print_log "ERROR" "download_user_plugin" "[插件清理失败],请检查!"
		return 2
	fi
	
	# other package
	if ! download_other_package "$plugin_path"; then
		print_log "ERROR" "download_user_plugin" "[下载other数据包失败],请检查!"
		return 3
	fi

	# golang
	if ! download_golang "$source_path"; then
		print_log "ERROR" "download_user_plugin" "[下载golang数据包失败],请检查!"
		return 4
	fi
	
	return 0
}

# 设置插件配置
set_plugin_config()
{
	local -n source_array_ref=$1
	local source_path="${source_array_ref["Path"]}"
	
	if [[ -z "$source_path" ]]; then
		print_log "ERROR" "set_plugin_config" "[无效参数: 参数验证为空],请检查!"
		return 1
	fi
	
	# 设置nginx插件
	if ! set_nginx_plugin "$source_path"; then
		print_log "ERROR" "set_system_config" "[设置nginx配置失败],请检查!"
		return 2
	fi
	
	# 设置插件依赖
	set_plugin_depends "$source_path"
	
	# 设置插件UI
	set_plugin_webui "$source_path"
	
	return 0
}

#********************************************************************************#
# 设置用户插件
set_user_plugin()
{
	print_log "INFO" "set_user_plugin" "设置用户插件"
	
	# 下载插件
	if ! download_user_plugin $1; then
		return 1
	fi
	
	# 设置插件配置
	if ! set_plugin_config $1; then
		return 2
	fi
	
	return 0
}