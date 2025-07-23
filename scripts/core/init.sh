#!/bin/sh

#********************************************************************************#
# 执行功能
exe_cmd_shell()
{
	local cmd=$1
	local ret=0
	local cmd_name=""
	
	print_log "DEBUG" "exe_cmd_shell" "执行命令:$cmd"
	
	case ${cmd} in
	${CMD_TYPE[autoCompileOpenwrt]})
		# 自动编译openwrt
		cmd_name="auto_compile_openwrt"
		auto_compile_openwrt "$2"; ret=$?
		;;
	${CMD_TYPE[cloneOpenWrtSrc]})
		# 获取OpenWrt源码
		cmd_name="clone_openwrt_source"
		clone_openwrt_source "$2"; ret=$?
		;;
	${CMD_TYPE[setOpenWrtFeeds]})
		# 设置OpenWrt feeds源
		cmd_name="set_openwrt_feeds"
		set_openwrt_feeds "$2"; ret=$?
		;;
	${CMD_TYPE[updateOpenWrtFeeds]})
		# 更新OpenWrt feeds源
		cmd_name="update_openwrt_feeds"
		update_openwrt_feeds "$2"; ret=$?
		;;
	${CMD_TYPE[setCustomConfig]})
		# 设置自定义配置
		cmd_name="set_custom_config"
		set_custom_config "$2"; ret=$?
		;;
	${CMD_TYPE[setMenuOptions]})
		# 设置软件包目录
		cmd_name="set_menu_options"
		set_menu_options "$2"; ret=$?
		;;
	${CMD_TYPE[downloadOpenWrtPackage]})
		# 下载openwrt包
		cmd_name="download_openwrt_package"
		download_openwrt_package "$2"; ret=$?
		;;
	${CMD_TYPE[compileOpenWrtFirmware]})
		# 编译OpenWrt固件
		cmd_name="compile_openwrt_firmware"
		compile_openwrt_firmware "$2"; ret=$?
		;;
	${CMD_TYPE[getOpenWrtFirmware]})
		# 获取OpenWrt固件
		cmd_name="get_openwrt_firmware"
		get_openwrt_firmware "$2"; ret=$?
		;;
	*)
		USER_STATUS_ARRAY["autocompile"]=0
		print_log "ERROR" "exe_cmd_shell" "无效命令:$cmd"
		return 1
		;;
	esac
	
	# 命令执行结果
	if [ $ret -eq 0 ]; then
		print_log "INFO" "exe_cmd_shell" "命令执行成功: ${cmd_name:-unknown}"
	else
		print_log "ERROR" "exe_cmd_shell" "命令执行失败: ${cmd_name:-unknown} (ret=${ret})"
	fi
	
	# 重置自动编译状态
	USER_STATUS_ARRAY["autocompile"]=0
	return $ret
}

# 设置命令目录
set_cmd_menu()
{
	local cmd_array=("${CMD_ARRAY[@]}")
	local ret=0
	
	# 初始校验
	if [ ${#cmd_array[@]} -eq 0 ]; then
		print_log "ERROR" "set_cmd_menu" "命令配置有误,请检查!"
		return 1
	fi
	
	while [ 1 ]; do
		clear
		local -n cmd_source_array=$1
		
		# 显示菜单
		show_cmd_menu cmd_array[@] cmd_source_array
		
		# 获取用户输入
		local index=$(input_user_index)
		
		# 输入验证
		if ! [[ "$index" =~ ^[0-9]+$ ]]; then
			print_log "WARNING" "set_cmd_menu" "输入无效：请输入数字!"
			pause "Press any key to continue..."
			continue
		fi
		
		if (( index < 0 || index > ${#cmd_array[@]} )); then
			print_log "WARNING" "set_cmd_menu" "请输入正确的命令序号!"
			pause "Press any key to continue..."
			continue
		fi
		
		# 退出选择列表
		[ $index -eq 0 ] && { ret=0; break; }
		
		# 执行命令功能
		exe_cmd_shell ${index} cmd_source_array
		local cmd_ret=$?
		
		if [ $? -ne 0 ]; then
			pause "press any key to continue..."
		fi
	done
}

# 设置源码目录 
set_source_menu()
{
	# 初始清屏
	clear
	
	while [ 1 ]; do
		local source_name_array=("${@}")
		
		# 检查空输入
		if [ ${#source_name_array[@]} -eq 0 ]; then
			print_log "ERROR" "set_source_menu" "提供的数据列表错误,请检查!"
			return 1
		fi
		
		# 名称排序（降序）
		local sorted_source_name_array=()
		while IFS= read -r line; do
			sorted_source_name_array+=("$line")
		done < <(printf "%s\n" "${source_name_array[@]}" | sort -r)
		
		# 显示菜单
		show_source_menu "${sorted_source_name_array[@]}"
		
		# 获取用户输入
		local index=$(input_user_index)
		
		# 输入验证
		if ! [[ "$index" =~ ^[0-9]+$ ]]; then
			print_log "WARNING" "set_source_menu" "输入无效：请输入数字!"
			pause "Press any key to continue..."
			clear; continue
		fi
		
		# 判断输入值是否有效
		if (( index < 0 || index > ${#sorted_source_name_array[@]} )); then
			print_log "WARNING" "set_source_menu" "请输入正确的命令序号!"
			pause "Press any key to continue..."
			clear; continue
		fi
		
		# 退出选择列表
		[ $index -eq 0 ] && { break; }
		
		# 获取选择的源码
		local source_name=${sorted_source_name_array[$index-1]}
		
		# 获取源码类型
		local source_type=${SOURCE_TYPE[${source_name}]}
		
		# 获取源码配置
		declare -A menu_source_array
		get_struct_field SOURCE_CONFIG_ARRAY "${source_type}" menu_source_array
		
		if [ ${#menu_source_array[@]} -eq 0 ]; then
			print_log "WARNING" "set_source_menu" "获取源码配置有误, 请检查!"
			clear; continue
		fi
		
		# 设置命令目录
		set_cmd_menu menu_source_array
		clear
	done
}

# 运行linux环境
run_linux_env()
{
	print_log "TRACE" "run_linux_env" "运行脚本环境，请等待..."
	
	local source_name_array=()
	enum_struct_field SOURCE_CONFIG_ARRAY "Name" source_name_array

	if [ ${#source_name_array[@]} -eq 0 ]; then
		print_log "ERROR" "run_linux_env" "获取配置信息失败, 请检查!"
		return
	fi
	
	case "${USER_CONFIG_ARRAY["mode"]}" in
		"${COMPILE_MODE[local_compile]}")
			# 交互式菜单模式
			set_source_menu ${source_name_array[@]}
			;;
		*)
			# 排序源码列表（降序）
			local sorted_source_name_array=()
			#mapfile -t sorted_source_name_array < <(printf "%s\n" "${source_name_array[@]}" | sort -r)
			while IFS= read -r line; do
				sorted_source_name_array+=("$line")
			done < <(printf "%s\n" "${source_name_array[@]}" | sort -r)
			
			# 用户输入选项
			local source_opt="$(echo "${USER_CONFIG_ARRAY["actionopt"]}" | sed 's/^ *//;s/ *$//')"
			# local source_opt=$(trim "${USER_CONFIG_ARRAY["actionopt"]}")
			
			# 使用索引遍历
			for index in "${!sorted_source_name_array[@]}"; do
				# 获取源码名称
				local source_name="${sorted_source_name_array[index]}"
				
				# 获取源码类型
				local source_type="${SOURCE_TYPE[$source_name]}"
				[ -z "$source_type" ] && continue
				
				# 获取源码信息
				declare -A source_array
				get_struct_field SOURCE_CONFIG_ARRAY "$source_type" source_array || continue
				
				# 检查名称匹配
				if [[ "$source_opt" == "$source_name" || "$source_opt" == "${source_array["Alias"]}" ]]; then
					# 自动编译openwrt
					auto_compile_openwrt source_array
				fi
			done
			;;
	esac
	
	print_log "INFO" "run_linux_env" "结束脚本环境运行!"
}

# 设置linux环境
set_linux_env()
{
	print_log "INFO" "set_linux_env" "设置 linux 环境，请等待..."

	# 创建工作目录
	if [ ! -d $OPENWRT_WORK_PATH ]; then
		sudo mkdir -p $OPENWRT_WORK_PATH
	fi
	
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[local_compile]} ]; then
		if [ ! -d $OPENWRT_CONFIG_PATH ]; then
			sudo mkdir -p $OPENWRT_CONFIG_PATH
		fi
		
		if [ ! -d $OPENWRT_OUTPUT_PATH ]; then
			sudo mkdir -p $OPENWRT_OUTPUT_PATH
		fi

		if dpkg -s proxychains4 >/dev/null 2>&1; then
			NETWORK_PROXY_CMD="proxychains4 -q -f /etc/proxychains4.conf"
		fi
		
		set +e
	else
		# exit on error
		set -e
	fi
	
	# 赋予工作目录权限
	sudo chown $USER:$GROUPS $OPENWRT_WORK_PATH
	
	# 设置系统时区
	sudo timedatectl set-timezone "${USER_CONFIG_ARRAY["zonename"]}"
	
	# 显示文件系统的磁盘使用情况
	df -hT
	
	print_log "INFO" "set_linux_env" "完成 linux 环境的设置!"
}

# 更新linux环境
update_linux_env()
{
	print_log "INFO" "update_linux_env" "更新 linux 环境，请等待..."
	
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[remote_compile]} ]; then
		# 列出前100个比较大的包
		#dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -n 100
		
		print_log "INFO" "update_linux_env" "正在删除大的软件包，请等待..."
		
		# ^ghc-8.*
		remove_packages '^ghc-8.*'

		# ^dotnet-.*
		remove_packages '^dotnet-.*'

		# ^llvm-.*
		remove_packages '^llvm-.*'
		
		# php.*
		remove_packages 'php.*'
		
		# temurin-.*
		remove_packages 'temurin-.*'
		
		# mono-.*
		remove_packages 'mono-.*'
		
		remove_packages_list=("azure-cli" "google-cloud-sdk" "hhvm" "google-chrome-stable" "firefox" "powershell" "microsoft-edge-stable")
		
		for package in "${packages_to_remove[@]}"; do
			echo "正在尝试删除包：$package"
			remove_packages "$package"
		done
		
		sudo rm -rf \
			/etc/apt/sources.list.d/* \
			/usr/share/dotnet \
			/usr/local/lib/android \
			/opt/ghc \
			/opt/hostedtoolcache/CodeQL
	fi

	sudo -E apt-get -qq update
	sudo -E apt-get -qq upgrade
	
	sudo -E apt-get -qq install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache clang cmake cpio curl device-tree-compiler fastjar file flex g++-multilib gawk gcc-multilib gettext git gperf haveged help2man intltool jq libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev libssl-dev libtool lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-distutils python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs unzip upx-ucl vim wget xmlto xxd zlib1g-dev
	
	sudo -E apt-get -qq autoremove --purge
	sudo -E apt-get -qq clean
	
	print_log "INFO" "update_linux_env" "完成 linux 环境的更新!"
}

# 初始化linux环境
init_linux_env()
{
	print_log "INFO" "init_linux_env" "初始化 linux 环境，请等待..."

	if ! init_user_config "${OPENWRT_CONF_FILE}"; then
		exit 1
	fi
	
	# 判断插件列表文件
	if [ ! -f "${OPENWRT_PLUGIN_FILE}" ]; then
		touch "${OPENWRT_PLUGIN_FILE}"
	fi
	
	print_log "INFO" "init_linux_env" "完成 linux 环境的初始化!"
}

#********************************************************************************#
# 运行linux脚本
run_app_linux()
{
	# 初始化linux环境
	init_linux_env
	
	# 更新linux环境
	#update_linux_env
	
	# 设置linux环境
	set_linux_env
	
	# 运行linux环境
	run_linux_env
}