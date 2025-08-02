#!/bin/bash

#********************************************************************************#
# 设置主机名称
set_host_name()
{
	print_log "INFO" "set_host_name" "[设置主机名称]"
	
	local source_type="$1"
	local source_path="$2"
	local target_name="${USER_CONFIG_ARRAY["defaultname"]}"
	
	if [[ $source_type -eq ${SOURCE_TYPE[coolsnowwolf]} ]]; then
		local config_file="$source_path/package/lean/default-settings/files/zzz-default-settings"
		
		if [[ -f "$config_file" ]]; then
			local current_name=$(sed -n 's/.*hostname=\(.*\)/\1/p' "$config_file")
			
			if [[ -z "$current_name" ]]; then
				if sed -i "/uci commit system/i\uci set system.@system[0].hostname=$target_name" "$config_file"; then
					print_log "INFO" "set_host_name" "[已添加主机名: $target_name]"
				else
					print_log "ERROR" "set_host_name" "[添加主机名失败],请检查!"
					return 1
				fi
			elif [ "$current_name" != "$target_name" ]; then
				if sed -i "s/\(.*hostname=\).*$/\1$target_name/" "$config_file"; then
					print_log "INFO" "set_host_name" "[已更新主机名: $current_name → $target_name]"
				else
					print_log "ERROR" "set_host_name" "[更新主机名失败],请检查!"
					return 2
				fi
			fi
		fi
	else
		local config_file="$source_path/package/base-files/files/bin/config_generate"
		
		if [[ -f "$config_file" ]]; then
			local current_name=$(sed -n "s/.*system\.@system\[-1\]\.hostname='\([^']*\)'/\1/p" "$config_file")
			
			if [[ -z "$current_name" ]]; then
				if sed -i '/.*add system system$/a\ \t\tset system.@system[-1].hostname='\''$target_name'\''' "$config_file"; then
					print_log "INFO" "set_host_name" "[已添加主机名: $target_name]"
				else
					print_log "ERROR" "set_host_name" "[添加主机名失败],请检查!"
					return 1
				fi
			elif [ "$current_name" != "$target_name" ]; then
				if sed -i "s/\(set system.@system\[-1\].hostname=\).*/\1'$target_name'/" "$config_file"; then
					print_log "INFO" "set_host_name" "[已更新主机名: $current_name → $target_name]"
				else
					print_log "ERROR" "set_host_name" "[更新主机名失败],请检查!"
					return 2
				fi
			fi
		fi
	fi
	
	return 0
}

# 设置用户密码
set_user_passwd()
{
	print_log "INFO" "set_user_passwd" "[设置用户默认密码]"
	
	local source_path="$1"
	local default_passwd="${USER_CONFIG_ARRAY["defaultpasswd"]}"
	
	local shadow_file="$source_path/package/base-files/files/etc/shadow"
	if [[ -f "$shadow_file" ]]; then
		if [ -z "${default_passwd}" ]; then
			default_passwd="password"
		fi
		
		#SALT=$(openssl rand -hex 8)
		#if [ $? -ne 0 ]; then
		#	return
		#fi
		
		#HASH=$(echo -n "${default_passwd}${SALT}" | openssl dgst -md5 -binary | openssl enc -base64)
		#if [ $? -ne 0 ]; then
		#	return
		#fi
		
		# 生成密码哈希
		local user_passwd
		if ! user_passwd=$(openssl passwd -1 "$default_passwd" 2>/dev/null); then
			print_log "ERROR" "security config" "[密码哈希生成失败],请检查!"
			return 1
		fi

		#echo "$user_passwd"
		
		# 更新root用户密码
		#sed -i "/^root:/s/:\([^:]*\):[^:]*/:${user_passwd}:0/" ${file}
		if sed -i "/^root:/s#:\([^:]*\):[^:]*#:$user_passwd:0#" "$shadow_file"; then
			print_log "INFO" "security config" "[更新root密码成功]"
		else
			print_log "ERROR" "security config" "[更新root密码失败],请检查!"
			return 2
		fi
	fi
	
	return 0
}

# 设置默认中文
set_default_chinese()
{
	print_log "INFO" "set_default_chinese" "[设置缺省中文]"
	
	local source_path="$1"
	
	# 修改luci配置文件语言设置
	local config_file="$source_path/feeds/luci/modules/luci-base/root/etc/config/luci"
	
	if [[ -f "$config_file" ]]; then
		if sed -i "/option lang/s/auto/zh_cn/" "$config_file"; then
			print_log "INFO" "set_default_chinese" "[修改luci语言设置成功]"
		else
			print_log "ERROR" "set_default_chinese" "[修改luci语言设置失败],请检查!"
			return 1
		fi
	fi
	
	# 创建默认设置脚本
	local script_file="$source_path/package/base-files/files/etc/uci-defaults/99-defaults-settings"
	mkdir -p "$(dirname "$script_file")"
	
	cat > "$script_file" <<-EOF
		uci set luci.main.lang=zh_cn
		uci commit luci
	EOF
	
	return 0
}

# 设置时区
set_system_timezone()
{
	print_log "INFO" "set_system_timezone" "[设置系统时区]"
	
	local source_path="$1"
	local target_timezone="${USER_CONFIG_ARRAY["timezone"]}"
	local target_zonename="${USER_CONFIG_ARRAY["zonename"]}"
	
	local config_file="$source_path/package/base-files/files/bin/config_generate"
	if [[ -f "$config_file" ]]; then
		
		# 设置时区
		local current_timezone=$(sed -n "s/.*system\.@system\[-1\]\.timezone='\([^']*\)'/\1/p" "$config_file")
		if [[ -n "$current_timezone" && "$current_timezone" != "$target_timezone" ]]; then
			if sed -i "s/\(set system.@system\[-1\].timezone=\).*/\1'$target_timezone'/" "$config_file"; then
				print_log "INFO" "set_system_timezone" "[时区已更新: $target_timezone]"
			else
				print_log "ERROR" "set_system_timezone" "[时区更新失败],请检查!"
				return 1
			fi
		fi

		# 设置时区名称
		local current_zonename=$(sed -n "s/.*system\.@system\[-1\]\.zonename='\([^']*\)'/\1/p" "$config_file")
		if [[ -z "$current_zonename" ]]; then
			#sed -i "/.*system.@system\[-1\].timezone.*$/a\ \t\tset system.@system[-1].zonename='\$defaultzonename'" ${file}
			
			if sed -i "/.*system.@system\[-1\].timezone.*\$/a\ \t\tset system.@system[-1].zonename='$target_zonename'" "$config_file"; then
				print_log "INFO" "set_system_timezone" "[已添加时区名称: $target_zonename]"
			else
				print_log "ERROR" "set_system_timezone" "[添加时区名称失败],请检查!"
				return 2
			fi
		elif [[ "$current_zonename" != "$target_zonename" ]]; then
			if sed -i "s|\(set system.@system\[-1\].zonename=\).*|\1'$target_zonename'|" "$config_file"; then
				print_log "INFO" "set_system_timezone" "[时区名称已更新: $target_zonename]"
			else
				print_log "ERROR" "set_system_timezone" "[时区名称更新失败],请检查!"
				return 3
			fi
		fi
	fi
	
	return 0
}

# 设置默认编译
set_compile_option()
{
	print_log "INFO" "set_compile_option" "[设置编译选项]"
	
	local source_type="$1"
	local source_path="$2"
	
	# 编译优化级别设置
	local target_file="$source_path/include/target.mk"
	if [[ -f "$target_file" ]]; then
		if sed -i 's/Os/O2/g' "$target_file"; then
			print_log "INFO" "set_compile_option" "[设置编译O2成功]"
		else
			print_log "ERROR" "set_compile_option" "[设置编译O2失败],请检查!"
			return 1
		fi
	fi
	
	# 编译信息设置
	if [[ $source_type -eq ${SOURCE_TYPE[coolsnowwolf]} ]]; then
		print_log "INFO" "set_compile_option" "[设置编译信息]"
		
		local config_file="$source_path/package/lean/default-settings/files/zzz-default-settings"
		if [[ -f "$config_file" ]]; then
			local build_info="C95wl build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt"
			
			if sed -i "s/\(echo \"DISTRIB_DESCRIPTION='\)[^\']*\( '\"\s>> \/etc\/openwrt_release\)/\1$build_info\2/g" "$config_file"; then
				print_log "INFO" "set_compile_option" "[设置编译信息成功]"
			else
				print_log "INFO" "set_compile_option" "[设置编译信息失败],请检查!"
				return 2
			fi
		fi
	fi
	
	return 0
}

# 设置PWM FAN
set_pwm_fan()
{
	if [[ ! "${USER_CONFIG_ARRAY["userdevice"]}" =~ ^(r2s|r5s)$ ]]; then
		return 0
	fi
	
	local source_type="$1"
	local source_path="$2"
	
	print_log "INFO" "set_pwm_fan" "[设置PWM风扇]"
	
	# rk3328-pwmfan脚本
	local initd_path="$source_path/target/linux/rockchip/armv8/base-files/etc/init.d/"
	local pwmfan_script="rk3328-pwmfan"
	
	if [[ ! -f "$initd_path/$pwmfan_script" ]]; then
		mkdir -p "$initd_path"
		
		if [[ -f "$OPENWRT_CONFIG_PATH/pwm-fan/$pwmfan_script" ]]; then
			cp -f "$OPENWRT_CONFIG_PATH/pwm-fan/$pwmfan_script" "$initd_path/"
			print_log "INFO" "set_pwm_fan" "[已复制本地PWM风扇控制脚本]"
		else
			local pwmfan_url="https://github.com/friendlyarm/friendlywrt/raw/master-v19.07.1/target/linux/rockchip-rk3328/base-files/etc/init.d/fa-rk3328-pwmfan"
			
			if $NETWORK_PROXY_CMD wget -q -P "$initd_path" -O "$initd_path/$pwmfan_script" "$pwmfan_url"; then
				print_log "INFO" "set_pwm_fan" "[已下载PWM风扇控制脚本]"
			else
				print_log "ERROR" "set_pwm_fan" "[下载PWM风扇控制脚本失败],请检查!"
				return 1
			fi
		fi
	fi
	
	# rk3328-pwm-fan.sh脚本
	local bin_path="$source_path/target/linux/rockchip/armv8/base-files/usr/bin/"
	local pwmfan_sh="rk3328-pwm-fan.sh"
	
	if [[ ! -f "$bin_path/$pwmfan_sh" ]]; then
		mkdir -p "$bin_path"
		
		if [[ -f "$OPENWRT_CONFIG_PATH/pwm-fan/$pwmfan_sh" ]]; then
			cp -f "$OPENWRT_CONFIG_PATH/pwm-fan/$pwmfan_sh" "$bin_path/"
			print_log "INFO" "set_pwm_fan" "[已复制本地PWM风扇脚本]"
		else
			local pwmfan_sh_url="https://github.com/friendlyarm/friendlywrt/raw/master-v19.07.1/target/linux/rockchip-rk3328/base-files/usr/bin/start-rk3328-pwm-fan.sh"
			
			if $NETWORK_PROXY_CMD wget -q -P "$bin_path" -O "$bin_path/$pwmfan_sh" "$pwmfan_sh_url"; then
				print_log "INFO" "set_pwm_fan" "[已下载PWM风扇脚本]"
			else
				print_log "ERROR" "set_pwm_fan" "[下载PWM风扇脚本失败],请检查!"
				return 2
			fi
		fi
	fi
	
	# 添加启动权限设置
	local config_file="$source_path/package/base-files/files/etc/uci-defaults/99-defaults-settings"
	mkdir -p "$(dirname "$config_file")"
	
	cat >> "$config_file" <<-'EOF'
		# PWM风扇权限设置
		[ -f "/etc/init.d/rk3328-pwmfan" ] && chmod 777 /etc/init.d/rk3328-pwmfan
		[ -f "/usr/bin/rk3328-pwm-fan.sh" ] && chmod 777 /usr/bin/rk3328-pwm-fan.sh
	EOF
	
	return 0
}

# 设置系统功能
set_system_func()
{
	print_log "INFO" "set_system_func" "[设置系统功能]"
	
	local source_type="$1"
	local source_path="$2"
	
	# 设置irqbalance
	local irqbalance_config="$source_path/feeds/packages/utils/irqbalance/files/irqbalance.config"
	if [[ -f "$irqbalance_config" ]]; then
		if sed -i "s/enabled '0'/enabled '1'/g" "$irqbalance_config"; then
			print_log "INFO" "set_system_func" "[启用irqbalance成功]"
		else
			print_log "ERROR" "set_system_func" "[修改irqbalance配置失败],请检查!"
			return 1
		fi
	fi
	
	# 设置ttyd登录路径
	local ttyd_config="${source_path}/feeds/packages/utils/ttyd/files/ttyd.config"
	if [[ -f "$ttyd_config" ]]; then
		if sed -i "s|/bin/login|/usr/libexec/login.sh|g" "$ttyd_config"; then
			print_log "INFO" "set_system_func" "[成功修改ttyd登录路径]"
		else
			print_log "ERROR" "set_system_func" "[ttyd配置修改失败],请检查!"
			return 2
		fi
	fi
	
	return 0
}

#********************************************************************************#
# 设置系统配置
set_system_config()
{
	local -n source_array_ref=$1
	local source_type=${source_array_ref["Type"]}
	local source_path=${source_array_ref["Path"]}
	
	if [[ -z "${source_type}" || -z "${source_path}" ]]; then
		print_log "ERROR" "set_system_config" "[无效参数: 参数验证为空],请检查!"
		return 1
	fi
	
	# 设置主机名称
	if ! set_host_name "$source_type" "$source_path"; then
		print_log "ERROR" "set_system_config" "[设置主机名失败],请检查!"
		return 1
	fi
	
	# 设置用户密码
	if ! set_user_passwd "$source_path"; then
		print_log "ERROR" "set_system_config" "[设置密码失败],请检查!"
		return 2
	fi
	
	# 设置默认中文
	if ! set_default_chinese "$source_path"; then
		print_log "ERROR" "set_system_config" "[设置语言失败],请检查!"
		return 3
	fi
	
	# 设置时区
	if ! set_system_timezone "$source_path"; then
		print_log "ERROR" "set_system_config" "[设置时区失败],请检查!"
		return 4
	fi
	
	# 设置默认编译
	if ! set_compile_option "$source_type" "$source_path"; then
		print_log "ERROR" "set_system_config" "[设置编译选项失败],请检查!"
		return 5
	fi
	
	return 0
}

# 设置系统脚本
set_system_script()
{
	local -n source_array_ref=$1
	local source_type=${source_array_ref["Type"]}
	local source_path=${source_array_ref["Path"]}
	
	if [[ -z "${source_type}" || -z "${source_path}" ]]; then
		print_log "ERROR" "set_system_script" "[无效参数: 参数验证为空],请检查!"
		return 1
	fi
	
	# 设置PWM FAN
	if ! set_pwm_fan "$source_type" "$source_path"; then
		print_log "ERROR" "set_system_script" "[设置PWM风扇失败],请检查!"
		return 1
	fi
	
	# 设置系统功能
	if ! set_system_func "$source_type" "$source_path"; then
		print_log "ERROR" "set_system_script" "[设置系统功能失败],请检查!"
		return 2
	fi
	
	return 0
}

#********************************************************************************#

# 设置自定义配置
set_user_config()
{
	print_log "INFO" "set_user_config" "设置用户配置"
	
	# 设置系统配置
	if ! set_system_config $1; then
		return 1
	fi
	
	# 设置系统脚本
	if ! set_system_script $1; then
		return 2
	fi
	
	return 0
}