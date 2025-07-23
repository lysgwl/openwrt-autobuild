#!/bin/bash

# 克隆仓库内容
function clone_repo_contents() 
{
	# 远程仓库URL
	local remote_repo=$1
	
	# 本地指定路径
	local local_path=$2
	
	# 代理命令
	local proxy_cmd=$3
	
	# 获取.git前缀和后缀字符
	local git_prefix="${remote_repo%%.git*}"
	local git_suffix="${remote_repo#*.git}"
	
	if [ -z "${git_prefix}" ] || [ -z "${git_suffix}" ]; then
		return 1
	fi
	
	# 获取?前缀和后缀字符
	local suffix_before_mark="${git_suffix%%\?*}"
	local suffix_after_mark="${git_suffix#*\?}"
	
	# url地址
	local repo_url="${git_prefix}.git"

	# 远程分支名称
	local repo_branch=$(echo ${suffix_after_mark} | awk -F '=' '{print $2; exit}')
	
	# 临时目录，用于克隆远程仓库
	local temp_dir=$(mktemp -d)
	
	# 函数返回值
	local ret=0
	
	while true; do
		echo "Cloning branch code... ${repo_branch}"
		
		# 克隆远程仓库到临时目录 ${proxy_cmd}
		local command="${proxy_cmd} git clone --depth 1 --branch ${repo_branch} ${repo_url} ${temp_dir}"
		if ! execute_command_retry ${USER_STATUS_ARRAY["retrycount"]} ${USER_STATUS_ARRAY["waittimeout"]} "${command}"; then
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
function get_remote_spec_contents()
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
	local git_prefix="${remote_repo%%.git*}"
	local git_suffix="${remote_repo#*.git}"

	if [ -z "${git_prefix}" ] || [ -z "${git_suffix}" ]; then
		return 1
	fi
	
	# 获取?前缀和后缀字符
	local suffix_before_mark="${git_suffix%%\?*}"	#
	local suffix_after_mark="${git_suffix#*\?}"	#

	if [ -z "${suffix_before_mark}" ] || [ -z "${suffix_after_mark}" ]; then
		return 1
	fi
	
	# url地址
	local repo_url="${git_prefix}.git"
	
	# 指定路径
	local repo_path="${suffix_before_mark}"
	
	# 远程分支名称
	local repo_branch=$(echo ${suffix_after_mark} | awk -F '=' '{print $2; exit}')
	
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
	local sparse_file=".git/info/sparse-checkout"
	
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
		if ! execute_command_retry ${USER_STATUS_ARRAY["retrycount"]} ${USER_STATUS_ARRAY["waittimeout"]} "${command}"; then
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