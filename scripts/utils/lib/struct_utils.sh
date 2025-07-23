#!/bin/bash

# 设置结构体字段
function set_struct_field()
{
	# 传入的关联数组
	local -n struct="$1"
	
	# 结构体名称
	local key="$2"

	# 传入的关联数组
	local -n fields="$3"
	
	# 可选的排序函数
	local sort_func="$4"
	
	# 获取关联数组的所有键（字段名称）
	local -a field_names=("${!fields[@]}")
	
	# 如果提供了排序函数，则使用该函数排序字段名称
	if [ -n "$sort_func" ]; then
		mapfile -t sorted_field_names < <( printf "%s\n" "${field_names[@]}" | "$sort_func" )
	else
		sorted_field_names=("${field_names[@]}")
	fi
	
	# 循环遍历字段名称数组, 将关联数组的内容合并到传入的结构体关联数组中
	for field_name in "${sorted_field_names[@]}"; do
		struct["$key:$field_name"]="${fields[$field_name]}"
		#echo $key:$field_name:${fields[$field_name]}
	done
}

# 获取结构体的字段值
function get_struct_field()
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
function enum_struct_field()
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