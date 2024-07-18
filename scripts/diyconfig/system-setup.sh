#!/bin/bash

#********************************************************************************#
# 设置主机名称
set_host_name()
{
	source_type=$1
	source_path=$2
	
	if [ ${source_type} -eq ${SOURCE_TYPE[openwrt]} ] || [ ${source_type} -eq ${SOURCE_TYPE[immortalwrt]} ]; then
		{
			file="${source_path}/package/base-files/files/bin/config_generate"
			print_log "INFO" "custom config" "[设置主机名称]"
			
			if [ -e ${file} ]; then
				host_name=$(sed -n "s/.*system\.@system\[-1\]\.hostname='\([^']*\)'/\1/p" ${file})
				default_name="${USER_CONFIG_ARRAY["defaultname"]}"
				
				if [ -z "${host_name}" ]; then
					sed -i '/.*add system system$/a\ \t\tset system.@system[-1].hostname='\''${default_name}'\''' ${file}
				else
					if [ "${host_name}" != "${default_name}" ]; then
						sed -i "s/\(set system.@system\[-1\].hostname=\).*/\1'${default_name}'/" ${file}
					fi
				fi
			fi
		}
	elif [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
		# 设置主机名称
		{
			file="${source_path}/package/lean/default-settings/files/zzz-default-settings"
			print_log "INFO" "custom config" "[设置主机名称]"
			
			if [ -e ${file} ]; then
				host_name=$(sed -n 's/.*hostname=\(.*\)/\1/p' ${file})
				default_name="${USER_CONFIG_ARRAY["defaultname"]}"
				
				if [ -z ${host_name} ]; then
					sed -i "/uci commit system/i\uci set system.@system[0].hostname=${default_name}" ${file}
				else
					if [ "${host_name}" != "${default_name}" ]; then
						sed -i "s/\(.*hostname=\).*$/\1${default_name}/" ${file}
					fi
				fi
			fi
		}
	fi
}

# 设置用户密码
set_user_passwd()
{
	source_path=$1
	
	{
		file="${source_path}/package/base-files/files/etc/shadow"
		print_log "INFO" "custom config" "[设置用户缺省密码]"
		
		if [ -e ${file} ]; then
			default_passwd="${USER_CONFIG_ARRAY["defaultpasswd"]}"
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
			
			user_passwd=$(openssl passwd -1 ${default_passwd})
			if [ -z "${user_passwd}" ]; then
				print_log "ERROR" "custom config" "生成密文数据失败, 请检查!"
				return
			fi

			#echo "$user_passwd"
			#sed -i "/^root:/s/:\([^:]*\):[^:]*/:${user_passwd}:0/" ${file}
			sed -i "/^root:/s#:\([^:]*\):[^:]*#:${user_passwd}:0#"  ${file}
		fi
	}
}

# 设置默认中文
set_default_chinese()
{
	source_path=$1
	print_log "INFO" "custom config" "[设置缺省中文]"
	
	{
		file="${source_path}/feeds/luci/modules/luci-base/root/etc/config/luci"
		if [ -e ${file} ]; then
			sed -i "/option lang/s/auto/zh_cn/" ${file}
		fi
	}
	
	{
		file="${source_path}/package/base-files/files/etc/uci-defaults/99-defaults-settings"
		
		cat > ${file} <<-EOF
			uci set luci.main.lang=zh_cn
			uci commit luci
		EOF
	}	
}

# 设置时区
set_system_timezone()
{
	source_path=$1
	
	{
		file="${source_path}/package/base-files/files/bin/config_generate"
		print_log "INFO" "custom config" "[设置系统时区]"
		
		if [ -e ${file} ]; then
			time_zone=$(sed -n "s/.*system\.@system\[-1\]\.timezone='\([^']*\)'/\1/p" ${file})
			default_timezone="${USER_CONFIG_ARRAY["timezone"]}"
			
			if [ -n "${time_zone}" ]; then
				if [ "${time_zone}" != "${default_timezone}" ]; then
					sed -i "s/\(set system.@system\[-1\].timezone=\).*/\1'${default_timezone}'/" ${file}
				fi
			fi
			
			zone_name=$(sed -n "s/.*system\.@system\[-1\]\.zonename='\([^']*\)'/\1/p" ${file})
			default_zonename="${USER_CONFIG_ARRAY["zonename"]}"
			
			if [ -z "${zone_name}" ]; then
				#sed -i "/.*system.@system\[-1\].timezone.*$/a\ \t\tset system.@system[-1].zonename='\$defaultzonename'" ${file}
				sed -i "/.*system.@system\[-1\].timezone.*\$/a\ \t\tset system.@system[-1].zonename='${default_zonename}'" ${file}
			else
				if [ "${zone_name}" != "${default_zonename}" ]; then
					sed -i "s|\(set system.@system\[-1\].zonename=\).*|\1'${default_zonename}'|" ${file}
				fi
			fi
		fi
	}
}

# 设置默认编译
set_compile_option()
{
	source_type=$1
	source_path=$2
	
	{
		# 编译O2优化
		file="${source_path}/include/target.mk"
		print_log "INFO" "custom config" "[编译O2优化]"
		
		if [ -e ${file} ]; then
			sed -i 's/Os/O2/g' ${file}
		fi
	}
	
	{
		# 设置编译信息
		if [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
			file="${source_path}/package/lean/default-settings/files/zzz-default-settings"
			print_log "INFO" "custom config" "[设置编译信息]"
			
			if [ -e ${file} ]; then
				build_info="C95wl build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt"
				sed -i "s/\(echo \"DISTRIB_DESCRIPTION='\)[^\']*\( '\"\s>> \/etc\/openwrt_release\)/\1${build_info}\2/g" ${file}
			fi
		fi
	}
}

# 设置PWM FAN
set_pwm_fan()
{
	source_type=$1
	source_path=$2
	
	print_log "INFO" "custom config" "[设置PWM风扇]"
	{
		# rk3328-pwmfan
		path="${source_path}/target/linux/rockchip/armv8/base-files/etc/init.d/"
		if [ ! -f "${path}/rk3328-pwmfan" ]; then
			if [ ! -f "${OPENWRT_CONFIG_PATH}/pwm-fan/rk3328-pwmfan" ]; then
				url="https://github.com/friendlyarm/friendlywrt/raw/master-v19.07.1/target/linux/rockchip-rk3328/base-files/etc/init.d/fa-rk3328-pwmfan"
				${NETWORK_PROXY_CMD} wget -P "${path}" -O "${path}/rk3328-pwmfan" "${url}"
			else
				cp -rf "${OPENWRT_CONFIG_PATH}/pwm-fan/rk3328-pwmfan"  "${path}"
			fi
		fi
		
		# rk3328-pwm-fan.sh
		path="${source_path}/target/linux/rockchip/armv8/base-files/usr/bin/"
		if [ ! -f "${path}/rk3328-pwm-fan.sh" ]; then
			if [ ! -f "${OPENWRT_CONFIG_PATH}/pwm-fan/rk3328-pwm-fan.sh" ]; then
				url="https://github.com/friendlyarm/friendlywrt/raw/master-v19.07.1/target/linux/rockchip-rk3328/base-files/usr/bin/start-rk3328-pwm-fan.sh"
				${NETWORK_PROXY_CMD} wget -P "${path}" -O "${path}/rk3328-pwm-fan.sh" "${url}"
			else
				cp -rf "${OPENWRT_CONFIG_PATH}/pwm-fan/rk3328-pwm-fan.sh"  "${path}"
			fi
		fi
	}
	
	{
		file="${source_path}/package/base-files/files/etc/uci-defaults/99-defaults-settings"
		cat >> ${file} <<-EOF
		
		if [ -f "/etc/init.d/rk3328-pwmfan" ]; then
		    chmod 777 /etc/init.d/rk3328-pwmfan
		fi
		
		if [ -f "/usr/bin/rk3328-pwm-fan.sh" ]; then
		    chmod 777 /usr/bin/rk3328-pwm-fan.sh
		fi
		
		EOF
	}
}

#  设置系统功能
set_system_func()
{
	source_type=$1
	source_path=$2
	
	# irqbalance 
	{
		file="${source_path}/feeds/packages/utils/irqbalance/files/irqbalance.config"
		print_log "INFO" "custom config" "[设置irqbalance]"
		
		if [ -f "${file}" ]; then
			sed -i "s/enabled '0'/enabled '1'/g" ${file}
		fi
	}
}

#********************************************************************************#
# 设置系统配置
set_system_config()
{
	source_type=$1
	source_path=$2
	
	# 设置用户密码
	set_user_passwd ${source_path}
	
	# 设置默认中文
	set_default_chinese ${source_path}
	
	# 设置时区
	set_system_timezone ${source_path}
	
	# 设置主机名称
	set_host_name ${source_type} ${source_path}
	
	# 设置默认编译
	set_compile_option ${source_type} ${source_path}
}

# 设置系统脚本
set_system_script()
{
	source_type=$1
	source_path=$2
	
	# 设置PWM FAN
	set_pwm_fan ${source_type} ${source_path}
	
	#  设置系统功能
	set_system_func ${source_type} ${source_path}
}

# 设置自定义配置
set_user_config()
{
	source_type=$1
	source_path=$2

	# 设置系统配置
	set_system_config ${source_type} ${source_path}
	
	# 设置系统脚本
	set_system_script ${source_type} ${source_path}
}