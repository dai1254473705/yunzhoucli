#!/bin/bash
set -e

# 配置
REGISTRY="http://localhost:4873"
PACKAGES=("util" "shared")
SCOPE="@yunzhou"

# 发布所有包
for pkg in "${PACKAGES[@]}"; do
  echo "正在发布 $SCOPE/$pkg..."
  pnpm --filter "$SCOPE/$pkg" publish --registry "$REGISTRY"
  echo "✅ $SCOPE/$pkg 发布成功"
done