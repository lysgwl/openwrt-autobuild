#!/bin/bash
set -eo pipefail

# 工作目录
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# 脚本运行参数
export SCRIPT_CMD_ARGS="${1:-}"

# 导出工作目录
export WORK_DIR="${WORK_DIR:-$(pwd)}"

# 导出脚本目录
export SCRIPTS_DIR="$WORK_DIR/scripts"

# 加载 common 脚本
source $SCRIPTS_DIR/core/common.sh

# 运行linux脚本
run_app_linux