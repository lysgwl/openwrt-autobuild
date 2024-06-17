#!/bin/bash

#********************************************************************************#
# 设置缺省编译
setDefaultCompile()
{
	source_path=$1
	
	# luci/Makefile默认编译依赖
	{
		file="${source_path}/feeds/luci/collections/luci/Makefile"
		if [ -e ${file} ]; then
		
			# 修改默认主题
			if grep -q "+luci-theme-bootstrap" ${file}; then
				print_log "INFO" "custom config" "[修改默认主题]"
				sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ${file}
			fi
			
			# 取消uhttpd依赖
			print_log "INFO" "custom config" "[修改uhttpd编译]"
			if grep -q "+uhttpd" ${file}; then
				sed -i 's/+uhttpd //g' ${file}
			fi
			
			# 取消uhttpd-mod-ubus依赖
			if grep -q "+uhttpd" ${file}; then
				sed -i 's/+uhttpd-mod-ubus //g' ${file}
			fi
		fi
	}
}

# 设置用户信息
setUserInfo()
{
	source_path=$1
	
	# 设置主机名称
	{
		file="${source_path}/package/lean/default-settings/files/zzz-default-settings"
		if [ -e ${file} ]; then
			print_log "INFO" "custom config" "[设置主机名称]"
			
			default_name="${USERCONFIG_ARRAY["defaultname"]}"
			host_name=$(sed -n 's/.*hostname=\(.*\)/\1/p' ${file})
			
			if [ -z ${host_name} ]; then
				sed -i "/uci commit system/i\uci set system.@system[0].hostname=${default_name}" ${file}
			else
				if [ "${host_name}" != "${default_name}" ]; then
					sed -i "s/\(.*hostname=\).*$/\1${default_name}/" ${file}
				fi
			fi
		fi
	}
	
	# 设置编译信息
	{
		file="${source_path}/package/lean/default-settings/files/zzz-default-settings"
		if [ -e ${file} ]; then
			print_log "INFO" "custom config" "[设置编译信息]"
			
			build_info="C95wl build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt"
			sed -i "s/\(echo \"DISTRIB_DESCRIPTION='\)[^\']*\( '\"\s>> \/etc\/openwrt_release\)/\1${build_info}\2/g" ${file}
		fi
	}
}

#********************************************************************************#
# 设置lede插件
setLedePlugins()
{
	source_path=$1
	plugins_path=$2
}

# 设置lede主题
setLedeThemes()
{
	source_path=$1
	plugins_path=$2
	
	# luci-theme-argon
	{
		find ${source_path} -name luci-theme-argon | xargs rm -rf;
		print_log "INFO" "custom config" "获取luci-theme-argon仓库代码..."
		
		url="https://github.com/jerrykuku/luci-theme-argon.git?ref=18.06"
		clone_repo_contents $url "${plugins_path}/luci-theme-argon" ${NETWORK_PROXY_CMD}
	}
	
	# luci-theme-argon-config
	{
		find ${source_path} -name luci-theme-argon-config | xargs rm -rf;
		print_log "INFO" "custom config" "获取luci-theme-argon-config仓库代码..."
		
		url="https://github.com/jerrykuku/luci-app-argon-config.git?ref=18.06"
		clone_repo_contents $url "${plugins_path}/luci-theme-argon-config" ${NETWORK_PROXY_CMD}
	}
	
	# luci-theme-edge
	{
		find ${source_path} -name luci-theme-edge | xargs rm -rf;
		print_log "INFO" "custom config" "获取luci-theme-edge仓库代码..."
		
		url="https://github.com/kiddin9/luci-theme-edge.git?ref=18.06"
		clone_repo_contents $url "${plugins_path}/luci-theme-edge" ${NETWORK_PROXY_CMD}
	}
}

# 设置lede配置
setLedeConfig()
{
	# 设置缺省编译
	setDefaultCompile $1

	# 设置用户信息
	setUserInfo $1
}