#!/bin/bash

#********************************************************************************#
# 设置缺省IP地址
set_default_addr()
{
	print_log "INFO" "set_default_addr" "[设置Lan接口缺省IP地址]"
	
	local source_path="$1"
	local default_addr="${NETWORK_CONFIG_ARRAY["lanaddr"]}"
	
	local config_file="${source_path}/package/base-files/files/bin/config_generate"
	
	if [[ -f "$config_file" ]]; then
		local ip_addr=$(sed -n 's/.*lan) ipad=\${ipaddr:-"\([0-9.]\+\)"}.*/\1/p' "$config_file")
		
		if [ "$ip_addr" != "$default_addr" ]; then
			if sed -i "s/lan) ipad=\${ipaddr:-\"$ip_addr\"}/lan) ipad=\${ipaddr:-\"$default_addr\"}/" "$config_file"; then
				print_log "INFO" "set_default_addr" "[设置Lan口缺省地址成功]"
			else
				print_log "INFO" "set_default_addr" "[设置Lan口缺省地址失败],请检查!"
				return 1
			fi
		fi
	fi
	
	return 0
}

# 生成网络配置
generate_network_config()
{
	print_log "INFO" "generate_network_config" "[设置网络接口地址]"
	local source_path="$1"
	
	local config_file="$source_path/package/base-files/files/etc/uci-defaults/99-defaults-settings"
	mkdir -p "$(dirname "$config_file")"
	
	# LAN配置
	cat >> "$config_file" <<-EOF
	
	uci -q batch << EOI
	set network.lan.proto='static'
	set network.lan.ipaddr='${NETWORK_CONFIG_ARRAY["lanaddr"]:-192.168.2.1}'
	set network.lan.netmask='${NETWORK_CONFIG_ARRAY["lannetmask"]:-255.255.255.0}'
	set network.lan.broadcast='${NETWORK_CONFIG_ARRAY["lanbroadcast"]:-192.168.2.255}'
	commit network
	
	set dhcp.lan.ignore='0'
	set dhcp.lan.start='${NETWORK_CONFIG_ARRAY["landhcpstart"]:-40}'
	set dhcp.lan.limit='${NETWORK_CONFIG_ARRAY["landhcpnumber"]:-60}'
	set dhcp.lan.leasetime='12h'
	commit dhcp
	EOI
	EOF
	
	# WAN配置
	cat >> "$config_file" <<-EOF
	
	uci -q batch << EOI
	set network.wan.proto='static'
	set network.wan.ipaddr='${NETWORK_CONFIG_ARRAY["wanaddr"]:-192.168.1.1}'
	set network.wan.netmask='${NETWORK_CONFIG_ARRAY["wannetmask"]:-255.255.255.0}'
	set network.wan.broadcast='${NETWORK_CONFIG_ARRAY["wanbroadcast"]:-192.168.1.255}'
	set network.wan.gateway='${NETWORK_CONFIG_ARRAY["wangateway"]:-192.168.1.1}'
	set network.wan.dns='${NETWORK_CONFIG_ARRAY["wandnsaddr"]:-192.168.1.1}'
	commit network
	EOI
	EOF
}

# 设置网络地址
set_network_addr()
{
	local source_path="$1"
	
	if ! set_default_addr "$source_path"; then
		return 1
	fi
	
	generate_network_config "$source_path"
	return 0
}

#********************************************************************************#
# 设置自定义网络
set_user_network()
{
	print_log "INFO" "set_user_config" "设置网络配置"
	
	local -n source_array_ref=$1
	local source_path=${source_array_ref["Path"]}
	
	if [[ -z "${source_path}" ]]; then
		print_log "ERROR" "set_user_network" "[无效参数: 参数验证为空],请检查!"
		return 1
	fi
	
	# 设置网络地址
	if ! set_network_addr "$source_path"; then
		print_log "ERROR" "set_user_network" "[设置网络地址失败],请检查!"
		return 2
	fi
	
	return 0
}