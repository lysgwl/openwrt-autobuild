#!/bin/bash

# 获取文件section
function get_config_section()
{
	# section名称
	local section=$1	
	
	# 配置文件
	local confile=$2
	
	if [ ! -e "${confile}" ]; then
		return
	fi
	
	# 判断第三个参数是否是数组
	if declare -p "$3" &>/dev/null && [[ "$(declare -p "$3")" =~ "declare -a" ]]; then
		# 用于存放字段值的数组
		local -n field_array="$3"
		
		# 查找所有section的信息
		local sections=$(awk -F '[][]' '/\[.*'"$section"'\]/{print $2}' ${confile})
		#echo "\"$sections\""
		
		# 枚举获取每个section段
		for section in $sections; do
			local value=$section
			field_array+=("$value")
		done
	fi
}

# 获取section的配置
function get_config_list()
{
	# section名称
	local section=$1

	# 配置文件
	local confile=$2
	
	# 传出结果数组
	local -n result=$3
	
	# 判断配置文件
	if [ ! -e "${confile}" ]; then
		return 1
	fi
	
	# 清空结果数组
	result=()
	
	#获取section的内容
	local content=$(awk -v section="$section" '
			/^\['"$section"'\]/ { flag = 1; next }
			 /^\[.*\]/ { flag = 0 }
			flag && NF { sub(/[[:space:]]+$/, "", $0); print }
			' "${confile}")
	
	#echo "\"$content\""
	#clean_content=$(echo "$content" | awk '{ sub(/[[:space:]]+$/, ""); print }')

	if [ -z "${content}" ]; then
		return 1
	fi
	
	local tmp_declare=$(declare -p "${3}" 2>/dev/null)
	
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