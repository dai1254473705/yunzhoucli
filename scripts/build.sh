#!/bin/bash
set -e  # 任何命令失败立即退出脚本

# 定义颜色输出（增强可读性）
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"  # 无颜色

echo -e "${GREEN}开始构建所有子包...${NC}"

# 构建指定包（按依赖顺序）
# 由于 @yunzhou/shared 依赖 @yunzhou/util，按此顺序指定 --filter 可确保先构建 util，再构建 shared（pnpm 会自动识别依赖关系，但显式指定顺序更稳妥）。
pnpm run --if-present \
  --recursive \
  --filter "@yunzhou/util" \
  --filter "@yunzhou/shared" \
  build

echo -e "${GREEN}✅ 所有子包构建完成${NC}"