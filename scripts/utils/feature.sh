#!/bin/bash

# 已加载模块缓存
declare -A LOADED_MODULES=()

# 模块依赖关系
declare -A MODULE_DEPEND=(
	["core"]="init run"
	["config"]="options config"
	["utils"]="cmd_utils config_utils git_utils json_utils prompt_utils struct_utils"
)

#********************************************************************************#
# 加载单个功能模块
function load_module() 
{
	local module_name=$1
	local module_path=$2
	
	# 检查模块是否已加载
	if [[ -n "${LOADED_MODULES[$module_name]}" ]]; then
		return 0
	fi
	
	local module_file="$module_path/$module_name.sh"
	
	# 检查文件是否存在
	if [[ ! -f "$module_file" ]]; then
		echo "[ERROR] 模块文件不存在: $module_file" >&2
		return 1
	fi
	
	# 加载模块
	source "$module_file" || {
		echo "[ERROR] 加载模块失败: $module_name (文件: $module_file)" >&2
		return 2
	}
	
	# 标记为已加载
	LOADED_MODULES["$module_name"]=1
	return 0
}

# 加载功能组
function load_feature()
{
	local group=$1
	local module_path=$2
	
	local module_array=()
	case "$group" in
		"core")
			module_array=(${MODULE_DEPEND[core]})
			;;
		"config")
			module_array=(${MODULE_DEPEND[config]})
			;;
		"utils")
			module_array=(${MODULE_DEPEND[utils]})
			;;
		*)
			load_module "$group" "$module_path"
			return $?
			;;
	esac
	
	# 加载所有依赖模块
	for module in "${module_array[@]}"; do
		load_module "$module" "$module_path" || return $?
	done
	
	return 0
}