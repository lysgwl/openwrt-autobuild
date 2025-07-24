#!/bin/bash

#********************************************************************************#
# 获取OpenWrt固件
get_openwrt_firmware()
{
	print_log "INFO" "get_openwrt_firmware" "获取 OpenWrt 固件,请等待..."
	
	# 参数检查
	local -n local_source_array="$1"
	local path=${local_source_array["Path"]}
	
	# 验证路径
	if [[ -z "${path}" || ! -d "${path}" ]]; then
		print_log "ERROR" "get_openwrt_firmware" "获取源码路径失败,请检查!"
		return 1
	fi
	
	# ------
	src_path="${path}/bin/targets/x86/generic"
	mkdir -p ${src_path}
	
	echo "this is a test1" > "${src_path}/test1.txt"
	echo "this is a test2" > "${src_path}/test2.txt"
	echo "this is a test3" > "${src_path}/test3.txt"
	echo "this is a test4" > "${src_path}/test4.txt"
	# ------
	
	#if [ ! -d "${path}/bin/targets" ] || ! find "${path}/bin/targets/" -mindepth 2 -maxdepth 2 -type d -name '*' | grep -q '.'; then
	#	print_log "ERROR" "get_openwrt_firmware" "固件目录不存在,请检查!"
	#	return 1
	#fi
	
	# 获取固件信息
	declare -A fields_array
	if ! get_firmware_info local_source_array fields_array; then
		return 2
	fi
	
	# 目标名称
	local target_name="${fields_array["name"]}"

	# 目标路径
	local target_path="${fields_array["path"]}"
	
	# 版本信息
	local version="${fields_array["version"]}"
	
	# 设备数组
	local device_array=()
	IFS=' ' read -r -a device_array <<< "${fields_array["devices"]}"
	
	# 创建目标路径
	if [ ! -d "${target_path}" ]; then
		mkdir -p "${target_path}"
	fi
	
	# 固件目录
	local firmware_array=()
	local target_dir=("$path"/bin/targets/*/*)
	
	(
		if ! pushd "${target_dir[0]}" >/dev/null || [ ! -n "$(find . -mindepth 1 -print -quit)" ]; then
			print_log "ERROR" "get_openwrt_firmware" "固件目录无效: ${target_dir[*]}"
			return 3
		fi
		
		# 处理设备固件
		for value in "${device_array[@]}"; do
			IFS=':' read -r device_name firmware_name <<< "$value"
			[[ -z "${device_name}" || -z "${firmware_name}" ]] && continue
			
			# ------
			dd if=/dev/zero of="test1-${device_name}.img" bs=1M count=1
			dd if=/dev/zero of="test2-${device_name}.img" bs=1M count=1
			gzip "test1-${device_name}.img" "test2-${device_name}.img"
			# ------
			
			# 准备固件路径
			local firmware_path="$target_path/$firmware_name"
			mkdir -p "${firmware_path}" || continue
			
			# 复制固件文件
			rsync -av \
				--exclude='packages/' \
				--include="*${device_name}*.img.gz" \
				--include="*${device_name}*.manifest" \
				--exclude='*.img.gz' \
				--exclude='*.manifest' \
				--include='*' \
				./ "$firmware_path/"
				
			ls -al "$target_path/$firmware_name"
				
			firmware_array+=("$firmware_name:$firmware_path")
		done
	)
	
	
	
	# 远程编译模式处理
	if [[ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[remote_compile]} ]]; then
		# 计数器
		local counter=0
		
		# 固件信息
		local firmware_json_array=()
		
		for value in "${firmware_array[@]}"; do
			IFS=':' read -r firmware_name firmware_path <<< "${value}"
			[[ -z "$firmware_name" || -z "$firmware_path" ]] && continue
			
			((counter++))
			
			echo "$firmware_name - $firmware_path"
			
			while IFS= read -r -d '' file; do
				declare -A object_array=(
					["name"]="${file##*/}"
					["file"]="${file}"
				)
				
				firmware_json_array+=("$(build_json_object object_array)")
			done < <(find "${firmware_path}" -type f -name "*.img.gz" -print0)
		done
		
		# 构建最终JSON输出
		declare -A object_json_array=(
			["count"]="${counter}"
			["name"]="${target_name}"
			["path"]="${target_path}"
			["firmware"]="$(build_json_array firmware_json_array)"
		)
		
		FIRMWARE_JSON_OBJECT=$(build_json_object object_json_array)
	fi
	
	print_log "INFO" "get_openwrt_firmware" "完成获取 OpenWrt 固件!"
	return 0
}

# 编译openwrt源码
compile_openwrt_firmware()
{
	print_log "INFO" "compile_openwrt_firmware" "正在编译 OpenWrt 固件,请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"
	
	# 获取路径
	local path=${local_source_array["Path"]}
	if [ -z "${path}" ] || [ ! -d "${path}" ]; then
		print_log "ERROR" "compile_openwrt_firmware" "获取源码路径失败,请检查!"
		return 1
	fi
	
	# 进入源码目录
	pushd ${path} > /dev/null
	
	# 设置信号捕捉来在退出时执行popd
	trap 'popd > /dev/null' EXIT
	
	run_make_command() {
		# 编译openwrt源码
		if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[local_compile]} ]; then
			${NETWORK_PROXY_CMD} make -j1 V=s
		else
			make -j$(nproc) V=s || make -j1 V=s
		fi || return 1
		
		return 0
	}
	
	if ! execute_command_retry ${USER_STATUS_ARRAY["retrycount"]} ${USER_STATUS_ARRAY["waittimeout"]} run_make_command; then
		df -hT && print_log "ERROR" "compile_openwrt_firmware" "编译 OpenWrt 固件失败,请检查!"
		return 1
	fi
	
	print_log "INFO" "compile_openwrt_firmware" "完成编译 OpenWrt 固件!"
	return 0
}

# 下载openwrt包
download_openwrt_package()
{
	print_log "INFO" "download_openwrt_package" "下载 OpenWrt 软件包,请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"

	# 获取路径
	local path=${local_source_array["Path"]}
	if [ -z "${path}" ] || [ ! -d "${path}" ]; then
		print_log "ERROR" "download_openwrt_package" "获取源码路径失败,请检查!"
		return 1
	fi
	
	# 进入源码目录
	pushd ${path} > /dev/null
	
	# 设置信号捕捉来在退出时执行popd
	trap 'popd > /dev/null' EXIT
	
	run_make_command() {
		# 下载软件包
		${NETWORK_PROXY_CMD} make download -j$(nproc) V=s || return 1

		# 查找文件并列出（ls）
		find dl -size -1024c -exec ls -l {} \; || return 1
		
		# 查找文件并删除（rm）
		find dl -size -1024c -exec rm -f {} \; || return 1

		return 0
	}
	
	if ! execute_command_retry ${USER_STATUS_ARRAY["retrycount"]} ${USER_STATUS_ARRAY["waittimeout"]} run_make_command; then
		print_log "ERROR" "download_openwrt_package" "下载 OpenWrt 软件包失败,请检查!"
		return 1
	fi

	print_log "INFO" "download_openwrt_package" "完成下载 OpenWrt 软件包!"
	return 0
}

# 设置功能选项
set_menu_options()
{
	print_log "INFO" "set_menu_options" "设置软件包目录,请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"
	
	# 获取路径
	local path=${local_source_array["Path"]}
	if [ -z "${path}" ] || [ ! -d "${path}" ]; then
		print_log "ERROR" "set_menu_options" "获取源码路径失败,请检查!"
		return 1
	fi
	
	# 缺省feeds配置文件
	local default_feeds_file="${path}/${USER_CONFIG_ARRAY["defaultconf"]}"
	
	# 自定义feeds配置文件
	local custom_feeds_file=""
	if [ -n "${USER_CONFIG_ARRAY["userdevice"]}" ] && [ -n "${local_source_array["Alias"]}" ]; then
		local feeds_file_path="${OPENWRT_CONFIG_PATH}/conf-file/${USER_CONFIG_ARRAY["userdevice"]}"
		custom_feeds_file="${feeds_file_path}/${local_source_array["Alias"]}"
		
		if [ "${USER_CONFIG_ARRAY["nginxcfg"]}" = "1" ]; then
			custom_feeds_file="${custom_feeds_file}-nginx"
		fi
		
		if [ "${USER_CONFIG_ARRAY["litecfg"]}" = "1" ]; then
			custom_feeds_file="${custom_feeds_file}-${USER_CONFIG_ARRAY["userdevice"]}-lite"
		else
		if [ "${USER_CONFIG_ARRAY["dockercfg"]}" = "1" ]; then
			custom_feeds_file="${custom_feeds_file}-docker"
			fi
			custom_feeds_file="${custom_feeds_file}-${USER_CONFIG_ARRAY["userdevice"]}"
		fi
		
		custom_feeds_file="${custom_feeds_file}.config"
	fi
	
	# 进入源码目录
	pushd ${path} > /dev/null
	
	# 设置信号捕捉来在退出时执行popd
	trap 'popd > /dev/null' EXIT

	# 远端编译
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[remote_compile]} ]; then
		if [ ! -f "${custom_feeds_file}" ]; then
			print_log "ERROR" "set_menu_options" "自定义 feeds 配置文件不存在,请检查!"
			return 1
		fi

		cp -rf "${custom_feeds_file}" "${default_feeds_file}"
		make defconfig
	else  # 本地编译
		if [ -f "${default_feeds_file}" ]; then
			if [ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]; then
				if [ -f "${custom_feeds_file}" ]; then
					if input_prompt_confirm "是否使用自定义 feeds 配置?"; then
						cp -rf "${custom_feeds_file}" "${default_feeds_file}"
					fi
				fi

				make menuconfig
			fi
		else
			if [ ! -f "${custom_feeds_file}" ]; then
				make menuconfig
			else
				cp -rf "${custom_feeds_file}" "${default_feeds_file}"
				if [ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]; then
					make menuconfig
				fi
			fi
		fi
		
		make defconfig
		./scripts/diffconfig.sh > seed.config
	fi

	print_log "INFO" "set_menu_options" "完成设置软件包目录!"
	return 0
}

# 设置自定义配置
set_custom_config()
{
	print_log "INFO" "set_custom_config" "设置自定义配置,请等待..."
	
	# 传入源码信息
	local -n local_source_array=$1
	
	# 获取路径
	if [ -z "${local_source_array["Path"]}" ] || [ ! -d "${local_source_array["Path"]}" ]; then
		print_log "ERROR" "set_custom_config" "获取源码失败,请检查!"
		return 1
	fi
	
	# 添加插件
	if ! set_openwrt_plugins local_source_array; then
		return 1
	fi
	
	# 添加主题
	if ! set_openwrt_themes local_source_array; then
		return 1
	fi

	# 设置openwrt缺省配置
	set_openwrt_config local_source_array
	
	print_log "INFO" "set_custom_config" "完成设置自定义配置!"
	return 0
}

# 更新 openwrt feeds源
update_openwrt_feeds()
{
	print_log "INFO" "update_openwrt_feeds" "更新 OpenWrt Feeds 源,请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"
	
	# 执行命令
	local command=""
	
	# 获取路径
	local path=${local_source_array["Path"]}
	if [ -z "${path}" ] || [ ! -d "${path}" ]; then
		print_log "ERROR" "update_openwrt_feeds" "获取源码路径失败,请检查!"
		return 1
	fi
	
	# Update feeds configuration
	print_log "INFO" "update feeds" "更新Feeds源码!"
	
	command="${NETWORK_PROXY_CMD} ${path}/scripts/feeds update -a"
	if ! execute_command_retry ${USER_STATUS_ARRAY["retrycount"]} ${USER_STATUS_ARRAY["waittimeout"]} "${command}"; then
		print_log "ERROR" "update_openwrt_feeds" "更新本地源失败,请检查!"
		return 1
	fi

	# Install feeds configuration
	print_log "INFO" "update_openwrt_feeds" "安装 Feeds 源码!"
	
	command="${NETWORK_PROXY_CMD} ${path}/scripts/feeds install -a"
	if ! execute_command_retry ${USER_STATUS_ARRAY["retrycount"]} ${USER_STATUS_ARRAY["waittimeout"]} "${command}"; then
		print_log "ERROR" "update_openwrt_feeds" "安装本地源失败,请检查!"
		return 1
	fi

	print_log "INFO" "update_openwrt_feeds" "完成更新 OpenWrt Feeds 源!"
	return 0
}

# 设置 openwrt feeds源
set_openwrt_feeds()
{
	print_log "INFO" "set_openwrt_feeds" "设置 OpenWrt Feeds 源,请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"
	
	# 获取路径
	local path=${local_source_array["Path"]}
	if [ -z "${path}" ] || [ ! -d "${path}" ]; then
		print_log "ERROR" "set_openwrt_feeds" "获取源码路径失败,请检查!"
		return 1
	fi
	
	# 设置脚本种子配置文件
	print_log "INFO" "set_openwrt_feeds" "拷贝 Feeds 源配置文件!"
	[ -e ${OPENWRT_FEEDS_CONF_FILE} ] && cp -rf ${OPENWRT_FEEDS_CONF_FILE} ${path}
	
	# 设置种子配置文件
	print_log "INFO" "set_openwrt_feeds" "设置 Feeds 源配置文件!"
	for key in "${!FEEDS_ARRAY[@]}"; do

		if [ "$key" = "istore" ] && [ ${local_source_array["Type"]} -eq ${SOURCE_TYPE[istoreos]} ]; then
			continue
		fi
		
		if grep -q "src-git.*${key}.*https" "${path}/feeds.conf.default"; then
			if grep -q "^#.*src-git.*${key}.*https" "${path}/feeds.conf.default"; then
				sed -i "/^#.*${key}/s/#//" "${path}/feeds.conf.default"
			fi
		else
			echo "src-git ${key} ${FEEDS_ARRAY[$key]}" >>${path}/feeds.conf.default
		fi
	done
	
	print_log "INFO" "set_openwrt_feeds" "完成设置 OpenWrt Feeds 源!"
	return 0
}

# 克隆openwrt源码
clone_openwrt_source()
{
	print_log "INFO" "clone_openwrt_source" "获取OpenWrt源码,请等待..."
	
	# 传入源码信息
	local -n local_source_array="$1"

	# 获取url
	local url=${local_source_array["URL"]}
	
	# 获取branch
	local branch=${local_source_array["Branch"]}
	
	# 获取路径
	local path=${local_source_array["Path"]}
	
	# 执行命令
	local command=""
	
	if [ -z "${url}" ] || [ -z "${path}" ]; then
		print_log "ERROR" "clone_openwrt_source" "获取源码路径失败,请检查!"
		return 1
	fi
	
	if [ ! -d "${path}" ]; then
		print_log "INFO" "clone_openwrt_source" "克隆源码文件!"
		
		if [ -n "${branch}" ]; then
			command="${NETWORK_PROXY_CMD} git clone ${url} -b ${branch} --depth=1 ${path}"
		else
			command="${NETWORK_PROXY_CMD} git clone ${url} --depth=1 ${path}"
		fi
		
		if ! execute_command_retry ${USER_STATUS_ARRAY["retrycount"]} ${USER_STATUS_ARRAY["waittimeout"]} "${command}"; then
			print_log "ERROR" "clone_openwrt_source" "Git获取源码失败,请检查!"
			return 1
		fi
	else
		print_log "INFO" "clone_openwrt_source" "更新源码文件!"
		
		command="${NETWORK_PROXY_CMD} git -C ${path} pull"
		if ! execute_command_retry ${USER_STATUS_ARRAY["retrycount"]} ${USER_STATUS_ARRAY["waittimeout"]} "${command}"; then
			print_log "ERROR" "clone_openwrt_source" "更新源码失败,请检查!"
		fi
	fi
	
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[local_compile]} ]; then
		ln -sf ${path}  ${SCRIPT_CUR_PATH}
	else
		ln -sf ${path} ${GITHUB_WORKSPACE}/${OPENWRT_SOURCEDIR_NAME}
	fi

	print_log "INFO" "clone_openwrt_source" "完成获取 OpenWrt 源码!"
	return 0
}

#********************************************************************************#
# 自动编译openwrt
auto_compile_openwrt()
{
	# 设置自动编译状态
	USER_STATUS_ARRAY["autocompile"]=1

	# 克隆openwrt源码
	if ! clone_openwrt_source $1; then
		return 1
	fi
	
	# 设置 openwrt feeds源
	#if ! set_openwrt_feeds $1; then
	#	return 1
	#fi

	# 更新 openwrt feeds源
	#if ! update_openwrt_feeds $1; then
	#	return 1
	#fi
	
	# 设置自定义配置
	#set_custom_config $1
	
	# 设置功能选项
	if ! set_menu_options $1; then
		return 1
	fi

	# 下载openwrt包
	#if ! download_openwrt_package $1; then
	#	return 1
	#fi
	
	# 编译openwrt源码
	#if ! compile_openwrt_firmware $1; then
	#	return 1
	#fi

	# 获取OpenWrt固件
	get_openwrt_firmware $1
	return 0
}
