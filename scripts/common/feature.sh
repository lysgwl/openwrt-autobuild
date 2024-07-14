#!/bin/bash

#********************************************************************************#
# 暂停中止命令
pause()
{
	read -n 1 -p "$*" inp
	
	if [ "$inp" != '' ]; then
		echo -ne '\b \n'
	fi
}

# 超时计数提示
timeout_with_count()
{
	local wait_seconds=$1
	local prompt_msg=$2

	while [ ${wait_seconds} -ne 0 ]; do
		# 每秒显示当前倒计时和提示信息
        echo -ne "\r${prompt_msg} ${wait_seconds} ..."
		
		# 等待1秒
		sleep 1
		
		# 倒计时减1
        ((wait_seconds--))
	done
}

# 获取命令序号
input_user_index()
{
	#stty erase ^H
	read -r value
	
	echo "$value"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]
	
	if [ "$?" = "0" ]; then
		result=$value
	else
		result=-1
	fi
	
	echo "$result"
}

# 获取用户选择是否
input_prompt_confirm()
{
	local prompt="$1"
	local input
	
	while true; do
		printf "\033[1;33m%s\033[0m" "${prompt} (y/n):"
        read -r -e input
		
		case "${input}" in
			[Yy])
				return 0
				;;
			[Nn])
				return 1
				;;
			 *)
				echo "无效输入，请输入 y 或 n."
				;;
		esac
	done
}

# 循环执行命令
execute_command_retry()
{
	# 最大尝试次数
	local max_attempts=$1
	
	# 等待时间
	local wait_seconds=$2
	
	# 运行命令
	local run_command=$3
	
	# 尝试次数
	local attempts=0
	
	until eval "${run_command}"; do
		if [ $? -eq 0 ]; then
            break
        else
			if [ "$attempts" -ge "$max_attempts" ]; then
				printf "\033[1;33m%s\033[0m\n" "命令尝试次数已达最大次数, 即将退出运行!"
				return 1
			else
				printf "\033[1;33m%s\033[0m\n" "命令执行失败, 是否需要再次尝试? (y/n):"
				read -t ${wait_seconds} input
			
				if [ -z "$input" ]; then
					input="y"
					printf "\033[1;31m%s\033[0m\n" "超时未输入，执行默认操作..."
				fi
			fi

			case "$input" in
				y|Y )
					attempts=$((attempts+1))
					continue ;;
				n|N )
					return 1 ;;
				* )
					attempts=$((attempts+1))
					continue ;;
			esac
		fi
	done
	
	return 0
}

#  打印日志信息
print_log()
{
	if [ "$#" -lt 3 ] || [ -z "$1" ]; then
		echo "Usage: print_log <log_level> <func_type> <message>"
		return
	fi

	local log_level="$1"
	local time1="$(date +"%Y-%m-%d %H:%M:%S")"
	
	# 日期格式
	local log_time="\x1b[38;5;208m[${time1}]\x1b[0m"
	
	# 消息格式
	local log_message="\x1b[38;5;87m${3}\x1b[0m"
	
	# 功能名称
	if [ -n "$2" ]; then
		local log_func="\x1b[38;5;210m(${2})\x1b[0m"
	fi
	
	case "$1" in
		"TRACE")
			local log_level="\x1b[38;5;76m[TRACE]:\x1b[0m"		# 深绿色
			;;
		"DEBUG")
			local log_level="\x1b[38;5;208m[DEBUG]:\x1b[0m"		# 浅橙色
			;;
		"WARNING")
			local log_level="\033[1;43;31m[WARNING]:\x1b[0m"	# 黄色底红字
			;;
		"INFO")
			local log_level="\x1b[38;5;76m[INFO]:\x1b[0m"		# 深绿色
			;;
		"ERROR")
			local log_level="\x1b[38;5;196m[ERROR]:\x1b[0m"		# 深红色
			;;
		*)
			echo "Unknown message type: $type"
			return
			;;
	esac
	
	printf "${log_time} ${log_level} ${func_type} ${log_message}\n"
}

#********************************************************************************#
# 获取文件section
get_config_section()
{
	# section名称
	section=$1	
	
	# 配置文件
	confile=$2
	
	if [ ! -e "${confile}" ]; then
		return
	fi
	
	# 判断第三个参数是否是数组
	if declare -p "$3" &>/dev/null && [[ "$(declare -p "$3")" =~ "declare -a" ]]; then
		# 用于存放字段值的数组
		local -n field_array="$3"
		
		# 查找所有section的信息
		sections=$(awk -F '[][]' '/\[.*'"$section"'\]/{print $2}' ${confile})
		#echo "\"$sections\""
		
		# 枚举获取每个section段
		for section in $sections; do
			local value=$section
			field_array+=("$value")
		done
	fi
}

# 获取section的配置
get_config_list()
{
	# section名称
	section=$1
	
	# 配置文件
	confile=$2
	
	# 传出结果数组
	local -n result=$3
	
	# 判断配置文件
	if [ ! -e "${confile}" ]; then
		return 1
	fi
	
	# 清空结果数组
	result=()
	
	#获取section的内容
	content=$(awk -v section="$section" '
			/^\['"$section"'\]/ { flag = 1; next }
			 /^\[.*\]/ { flag = 0 }
			flag && NF { sub(/[[:space:]]+$/, "", $0); print }
			' "${confile}")
	
	#echo "\"$content\""
	#clean_content=$(echo "$content" | awk '{ sub(/[[:space:]]+$/, ""); print }')

	if [ -z "${content}" ]; then
		return 1
	fi
	
	tmp_declare=$(declare -p "${3}" 2>/dev/null)
	
	# 判断关联数组
	#if [ "$(declare -p "${3}" 2>/dev/null | grep -o 'declare \-A')" == "declare -A" ]; then
	if [[ "${tmp_declare}" =~ "declare -A" ]]; then
		if [[ ! "${content}" =~ = ]]; then
			return 1
		fi
		
		while IFS='=' read -r key value; do
			if [ -n "${key}" ]; then
				result["$key"]="$value"
			fi
		done <<< "$content"
	else
		while IFS=' ' read -r value; do
			if [ -n "${value}" ]; then
				result+=("${value}")
			fi
		done <<< "$content"
	fi	
	
	return 0
}

#********************************************************************************#
# 设置结构体字段
set_struct_field()
{
	# 传入的关联数组
	local -n struct="$1"
	
	# 结构体名称
	local key="$2"

	# 传入的关联数组	
	local -n fields_array="$3"
	
	# 可选的排序函数
	local sort_func="$4"
	
	# 获取关联数组的所有键（字段名称）
	local -a field_names=("${!fields_array[@]}")
	
	# 如果提供了排序函数，则使用该函数排序字段名称
	if [ -n "$sort_func" ]; then
		mapfile -t sorted_field_names < <( printf "%s\n" "${field_names[@]}" | "$sort_func" )
	else
		sorted_field_names=("${field_names[@]}")
	fi
	
	# 循环遍历字段名称数组, 将关联数组的内容合并到传入的结构体关联数组中
	for field_name in "${sorted_field_names[@]}"; do
		struct["$key:$field_name"]="${fields_array[$field_name]}"
		#echo $key:$field_name:${fields_array[$field_name]}
	done
}

# 获取结构体的字段值
get_struct_field()
{
	# 传入的关联数组
	local -n struct="$1"

	# 结构体名称
	local key="$2"	
	
	# 判断参数个数
	if [ "$#" -lt 3 ]; then
		return
	fi
	
	# 判断参数3是否是关联数组
	if [ ! "$(declare -p "$3" 2>/dev/null | grep -o 'declare \-A')" == "declare -A" ]; then
		# 字段名称
		local field_name="$3"
		
		# 获取并返回字段值
		echo "${struct["$key:$field_name"]}"
	else
		# 用于传出结果的关联数组
		local -n result="$3"

		# 清空结果数组
		result=()
		
		for struct_name in "${!struct[@]}"; do
			# 获取结构体名称，即去除最后一个冒号后面的内容
			local field_key="${struct_name%:*}"
			
			# 获取字段名称，即去除第一个冒号前面的内容
			local field_name="${struct_name#*:}"
			
			if [ "$field_key" != "$key" ]; then
				continue
			fi
			
			local field_value="${struct["$struct_name"]}"
			result["$field_name"]=$field_value
		done
	fi
}

# 枚举获取指定字段的字段值，并将字段值放入数组返回
enum_struct_field()
{
	if [ "$#" -lt 3 ]; then
		return
	fi
	
	# 传入的关联数组
	local -n struct="$1"
	
	# 字段名称
	local target_field="$2"
	
	# 判断第三个参数是否是数组
	if declare -p "$3" &>/dev/null && [[ "$(declare -p "$3")" =~ "declare -a" ]]; then
		# 用于存放字段值的数组
		local -n field_array="$3"
		
		for struct_name in "${!struct[@]}"; do
			# 获取结构体名称，即去除最后一个冒号后面的内容
			local field_key="${struct_name%:*}"
			
			# 获取字段名称，即去除第一个冒号前面的内容
			local field_name="${struct_name#*:}"
			
			# 获取字段值
			local field_value="${struct["$struct_name"]}"
			
			if [ -n "$target_field" ] && [ "$field_name" == "$target_field" ]; then
				# 将匹配成功的字段值放入数组
				field_array+=("$field_value")
			fi
		done
	fi
}

#********************************************************************************#
# 克隆仓库内容
clone_repo_contents() 
{
	# 远程仓库URL
	local remote_repo=$1
	
	# 本地指定路径
	local local_path=$2
	
	# 代理命令
	local proxy_cmd=$3
	
	# 获取.git前缀和后缀字符
	git_prefix="${remote_repo%%.git*}"
	git_suffix="${remote_repo#*.git}"
	
	if [ -z "${git_prefix}" ] || [ -z "${git_suffix}" ]; then
		return 1
	fi
	
	# 获取?前缀和后缀字符
	suffix_before_mark="${git_suffix%%\?*}"
	suffix_after_mark="${git_suffix#*\?}"
	
	# url地址
	repo_url="${git_prefix}.git"

	# 远程分支名称
	repo_branch=$(echo ${suffix_after_mark} | awk -F '=' '{print $2; exit}')
	
	# 临时目录，用于克隆远程仓库
	local temp_dir=$(mktemp -d)
	
	# 函数返回值
	local ret=0
	
	while true; do
		echo "Cloning branch code... ${repo_branch}"
		
		# 克隆远程仓库到临时目录 ${proxy_cmd}
		command="${proxy_cmd} git clone --depth 1 --branch ${repo_branch} ${repo_url} ${temp_dir}"
		if ! execute_command_retry ${USER_CONFIG_ARRAY["retrycount"]} ${USER_CONFIG_ARRAY["waittimeout"]} "${command}"; then
			ret=1
			break
		fi
		
		local target_path="${local_path}"
		
		if [ ! -d "${target_path}" ]; then
			mkdir -p "${target_path}"
		fi
		
		# 判断目标目录是否为空
		if [ ! -z "$(ls -A ${target_path})" ]; then
			# 使用:?防止变量为空时删除根目录
			rm -rf "${target_path:?}"/*  
		fi
		
		echo "Copying repo directory to local...."
		
		# 复制克隆的内容到目标路径
		cp -r ${temp_dir}/* "${local_path}"
		break
	done

	# 清理临时目录
	rm -rf ${temp_dir}
	
	return ${ret}
}

# 添加获取远程仓库指定内容
get_remote_spec_contents()
{
	# 远程仓库URL
	local remote_repo=$1
	
	# 远程仓库别名
	local remote_alias=$2
	
	# 本地指定路径
	local local_path=$3
	
	# 代理命令
	local proxy_cmd=$4
	
	# 获取.git前缀和后缀字符
	git_prefix="${remote_repo%%.git*}"
	git_suffix="${remote_repo#*.git}"

	if [ -z "${git_prefix}" ] || [ -z "${git_suffix}" ]; then
		return 1
	fi
	
	# 获取?前缀和后缀字符
	suffix_before_mark="${git_suffix%%\?*}"	#
	suffix_after_mark="${git_suffix#*\?}"	#

	if [ -z "${suffix_before_mark}" ] || [ -z "${suffix_after_mark}" ]; then
		return 1
	fi
	
	# url地址
	repo_url="${git_prefix}.git"
	
	# 指定路径
	repo_path="${suffix_before_mark}"
	
	# 远程分支名称
	repo_branch=$(echo ${suffix_after_mark} | awk -F '=' '{print $2; exit}')
	
	# 临时目录，用于克隆远程仓库
	local temp_dir=$(mktemp -d)
	
	# 初始化本地目录
	git init -b main ${temp_dir}
	
	# 使用pushd进入临时目录
	pushd ${temp_dir} > /dev/null	# cd ${temp_dir}
	
	# 添加远程仓库
	echo "Add remote repository: ${remote_alias}"
	git remote add ${remote_alias} ${repo_url} || true
	
	# 开启Sparse checkout模式
	git config core.sparsecheckout true
	
	# 配置要检出的目录或文件
	sparse_file=".git/info/sparse-checkout"
	
	if [ ! -e "${sparse_file}" ]; then
		touch "${sparse_file}"
	fi
	
	echo "${repo_path}" >> ${sparse_file}
	echo "Pulling from $remote_alias branch $repo_branch..."
	
	# 函数返回值
	local ret=0
	
	while true; do
		# 从远程将目标目录或文件拉取下来
		command="${proxy_cmd} git pull ${remote_alias} ${repo_branch}"
		if ! execute_command_retry ${USER_CONFIG_ARRAY["retrycount"]} ${USER_CONFIG_ARRAY["waittimeout"]} "${command}"; then
			ret=1
			break
		fi
		
		local target_path="${local_path}"
		
		if [ ! -d "${target_path}" ]; then
			mkdir -p "${target_path}"
		fi
		
		# 判断目标目录是否为空
		if [ ! -z "$(ls -A ${target_path})" ]; then
			rm -rf "${target_path:?}"/*  
		fi
		
		echo "Copying remote repo directory to local...."
		
		if [ -e "${temp_dir}/${repo_path}" ]; then
			cp -rf ${temp_dir}/${repo_path}/* ${target_path}
		fi
		
		break
	done
	
	# 返回原始目录
    popd > /dev/null
	
	# 清理临时目录
	rm -rf ${temp_dir}
	
	return ${ret}
}

# 显示源码目录
show_source_menu()
{
	local source_array=("${@}")
	
	printf "\033[1;33m%s\033[0m\n" "请选择源码类型:"
	printf "\033[1;31m%2d. %s\033[0m\n" "0" "关闭"
	
	for ((i=0; i<${#source_array[@]}; i++)) do
		printf "\033[1;36m%2d. %s项目\033[0m\n" $((i+1)) "${source_array[i]}"
	done
	
	printf "\033[1;33m%s\033[0m" "请输入源码序号:"
}

# 显示命令目录
show_cmd_menu()
{
	local cmd_array=("${!1}")	# ${@}
	local -n local_source_array="$2"
	
	printf "\033[1;33m%s\033[0m\n" "请选择命令序号(${local_source_array["Name"]}):"
	printf "\033[1;31m%2d. %s\033[0m\n" "0" "返回"
	
	for ((i=0; i<${#cmd_array[@]}; i++)) do
		printf "\033[1;36m%2d. %s\033[0m\n" $((i+1)) "${cmd_array[i]}"
	done
	
	printf "\033[1;33m%s\033[0m" "请输入命令序号:"
}