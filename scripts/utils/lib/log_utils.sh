#!/bin/bash

# 打印日志信息
function print_log()
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
	local log_func=""
	if [ -n "$2" ]; then
		log_func="\x1b[38;5;210m(${2})\x1b[0m"
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
	
	printf "${log_time} ${log_level} ${log_func} ${log_message}\n"
}