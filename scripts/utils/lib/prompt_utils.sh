#!/bin/bash

# 超时计数提示
function timeout_with_count()
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
function input_user_index()
{
	local value
	local result
	
	# 提示用户输入
	read -r -e -p "$(printf "\033[1;33m请输出正确的序列号:\033[0m")" value
	
	# 过滤输入，只接受数字
	if [[ "$value" =~ ^[0-9]+$ ]]; then
		result="$value"
	else
		result=-1
	fi
	
	echo "$result"
}

# 获取用户选择是否
function input_prompt_confirm()
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

# 显示源码目录
function show_source_menu()
{
	local source_array=("${@}")
	
	printf "\033[1;33m%s\033[0m\n" "请选择源码类型:"
	printf "\033[1;31m%2d. %s\033[0m\n" "0" "关闭"
	
	for ((i=0; i<${#source_array[@]}; i++)) do
		printf "\033[1;36m%2d. %s项目\033[0m\n" $((i+1)) "${source_array[i]}"
	done
}

# 显示命令目录
function show_cmd_menu()
{
	local cmd_array=("${!1}")	# ${@}
	local -n local_source_array="$2"
	
	printf "\033[1;33m%s\033[0m\n" "请选择命令序号(${local_source_array["Name"]}):"
	printf "\033[1;31m%2d. %s\033[0m\n" "0" "返回"
	
	for ((i=0; i<${#cmd_array[@]}; i++)) do
		printf "\033[1;36m%2d. %s\033[0m\n" $((i+1)) "${cmd_array[i]}"
	done
}