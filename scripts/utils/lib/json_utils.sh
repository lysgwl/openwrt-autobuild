#!/bin/bash

# 判断是否为有效 JSON 对象
function is_json_object()
{
	local input=$1
	
	# 去掉字符串两端的空白字符
	input=$(echo "${input}" | xargs)
	
	 # 检查输入是否以 "{" 开头并以 "}" 结尾
	if [[ ! "${input}" =~ ^\{.*\}$ ]]; then
		return 1
	fi
	
	return 0
}

# 判断是否为有效 JSON 格式
function is_valid_json()
{
	local input="$1"
	
	 # 使用 jq 来验证输入是否是有效的 JSON
	echo "$input" | jq empty >/dev/null 2>&1
	return $?
}

# 将数组转换为 JSON 数组
function generate_json_array()
{
	local -n json_items=$1
	local json_output="["
	
	local last_index=$(( ${#json_items[@]} - 1 ))
	
	for index in "${!json_items[@]}"; do
		json_output+="${json_items[${index}]}"
		
		if [ ${index} -ne ${last_index} ]; then
			json_output+=", "
		fi
	done
	
	json_output+="]"
	echo "${json_output}"
}

# 构建 JSON 对象
function build_json_object()
{
	local -n params_ref=$1
	local json_object="{"
	
	local first_pair=true
	
	for key in "${!params_ref[@]}"; do
		local value="${params_ref[$key]}"
		
		# 如果不是第一个键值对，添加逗号
		if [ "${first_pair}" = false ]; then
			json_object+=", "
		fi
		
		# 判断值的类型并进行相应处理
		if is_valid_json "$value"; then
			# 如果值是合法的 JSON 对象/数组，直接使用
			json_object+="\"${key}\": ${value}"
		elif [[ "$value" =~ ^-?[0-9]+$ ]]; then
			# 如果值是整数，不加引号
			json_object+="\"${key}\": ${value}"
		elif [[ "$value" =~ ^(true|false|null)$ ]]; then
			# 如果值是布尔值或 null，不加引号
			json_object+="\"${key}\": ${value}"
		else
			# 默认情况：字符串，加引号
			json_object+="\"${key}\": \"${value}\""
		fi

		# 更新标志，后续键值对之前需要添加逗号
		first_pair=false
	done
	
	json_object+="}"
	echo "$json_object"
}

# 构建 JSON 数组
function build_json_array()
{
	local -n array_ref=$1
	local -a json_array=()
	
	for value in "${array_ref[@]}"; do
		local json_object

		# 判断元素类型
		if is_json_object "$value"; then
			json_object="$value"
		else
			json_object="\"${value}\""
		fi
		
		# 添加到 JSON 数组
		if [ -n "${json_object}" ]; then
			json_array+=("$json_object")
		fi
	done
	
	generate_json_array json_array
}

# 将 JSON 对象转换为数组
function json_to_array()
{
	local json_str="$1"
	local array=()
	
	# 使用 jq 解析 JSON 对象
	while IFS="=" read -r name path; do
		array+=("$name:$path")
	done < <(echo "$json_str" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
	
	 # 输出数组
	echo "${array[@]}"
}