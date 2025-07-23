#!/bin/bash

# 暂停中止命令
function pause()
{
	read -n 1 -p "$*" inp
	
	if [ "$inp" != '' ]; then
		echo -ne '\b \n'
	fi
}

# 删除系统软件包
function remove_packages()
{
	local pattern=$1
	
	# 查找符合条件的正则表达式软件包
	remove_packages=$(dpkg -l | awk "/^ii/ && \$2 ~ /${pattern}/" | awk '{print $2}')
	if [ -n "$remove_packages" ]; then
		# 逐个删除包，忽略无法找到的包
		while read -r package; do
			if sudo apt-get remove -y "$package" 2>/dev/null; then
				echo "已成功删除包: $package"
			fi
		done <<< "$remove_packages"
	fi
}

# 删除文件中的关键字
function remove_keyword_file()
{
	local keyword=$1
	local file=$2
	
	if [ ! -e ${file} ]; then
		return
	fi
	
	if ! grep -q "${keyword}" ${file}; then
		return
	fi
	
	sed -i '/'"${keyword}"'/{
		# # 如果行中只有关键字和行尾的反斜杠，直接删除整行
		/^[[:space:]]*'"${keyword}"'[[:space:]]*\\[[:space:]]*$/{
            d
        }
		
		# 替换关键字及其前后的空格为单个空格
        s/[[:space:]]*'"${keyword}"'[[:space:]]*/ /g
		
		# 合并多个空格为单个空格
		s/[[:space:]]\{2,\}/ /g
		
		# 如果关键字在行首，删除前面的空格
		#s/^[[:space:]]*//
		
		# 如果关键字在行尾，删除后面的空格
		#s/[[:space:]]*$//

	}' ${file}
	
	# s/[[:space:]]*'"${keyword}"'[[:space:]]*/ /g
	#	s/ \+/ /g
}

# 循环执行命令
function execute_command_retry()
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
				printf "\033[1;33m%s\033[0m\n" "命令尝试次数已达最大次数,即将退出运行!"
				return 1
			else
				printf "\033[1;33m%s\033[0m\n" "命令执行失败,是否需要再次尝试? (y/n):"
				read -t ${wait_seconds} input
			
				if [ -z "$input" ]; then
					input="y"
					printf "\033[1;31m%s\033[0m\n" "超时未输入,执行默认操作..."
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