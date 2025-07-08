### 使用 pnpm 开发并发布 Monorepo 到私有仓库完整教程

#### 一、环境准备（确保正确安装工具）
1. **安装 pnpm**  
```bash
npm install -g pnpm
pnpm -v  # 确保版本 >= 8.0
```

2. **安装 Verdaccio 私有仓库**  
```bash
npm install -g verdaccio
```


#### 二、创建项目并初始化
1. **创建项目目录并初始化 pnpm**  
```bash
mkdir testmonorepo && cd testmonorepo
pnpm init
```

2. **配置 pnpm 工作区**  
创建 `pnpm-workspace.yaml` 文件（定义多包路径）：  
```yaml
# pnpm-workspace.yaml
packages:
 - "packages/*"
```

3. **更新根目录 package.json**  
添加 `workspaces` 字段（若自动生成的文件中没有）：  
```json
{
  "name": "testmonorepo",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "workspaces": [
    "packages/*"
  ],
  "keywords": [],
  "author": "",
  "license": "ISC",
  "packageManager": "pnpm@10.12.4",
  "private": true  // 根目录不发布，设为私有
}
```


#### 三、创建子包（util 和 shared）
1. **手动创建子包目录**  
```bash
mkdir -p packages/util/src packages/shared/src
```

2. **配置 util 包**  
```bash
# 初始化 util 包
cd packages/util
pnpm init
```
```json
// packages/util/package.json
{
  "name": "@yunzhou/util",
  "version": "0.0.1",
  "description": "",
  "main": "dist/util/index.js", 
  "keywords": [],
  "author": "",
  "license": "ISC",
  "packageManager": "pnpm@10.12.4",
  "devDependencies": {
    "typescript": "^5.2.2"
  }
}
```
```typescript
// packages/util/src/index.ts
export function add(a: number, b: number): number {
  return a + b;
}
```

3. **配置 shared 包（依赖 util）**  
```bash
cd ../shared
pnpm init
```
```json
// packages/shared/package.json
{
  "name": "@yunzhou/shared",
  "version": "1.0.0",
  "description": "",
  "main": "dist/shared/index.js", 
  "keywords": [],
  "author": "",
  "license": "ISC",
  "packageManager": "pnpm@10.12.4",
  "dependencies": {
    "@yunzhou/util": "workspace:*"
  },
  "devDependencies": {
    "typescript": "^5.2.2"
  }
}
```
```typescript
// packages/shared/src/index.ts
import { add } from '@yunzhou/util';

export function calculateTotal(prices: number[]): number {
  return prices.reduce((total, price) => add(total, price), 0);
}
```


#### 四、配置 TypeScript
1. **创建根目录 tsconfig.base.json**  
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "target": "esnext",
    "module": "ESNext",
    "moduleResolution": "Node",
    "jsx": "react-jsx",
    "esModuleInterop": true,
    "experimentalDecorators": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "skipLibCheck": true, // 跳过检查第三方库类型，加快编译速度
    "resolveJsonModule": true,
    "composite": true,
    "lib": ["ES2018", "DOM"],
    "outDir": "./dist",         // 统一输出目录
    "tsBuildInfoFile": "./.tsbuildinfo",  // 默认路径（会被子包覆盖）
    "paths": {
      "@yunzhou/util": ["packages/util/src"],
      "@yunzhou/shared": ["packages/shared/src"],
    }
  },
  "exclude": [
    "node_modules",
    "packages/**/node_modules",
    "dist",
    "packages/**/dist",
    "**/__tests__/**/*",
    "**/*.md",
    ".husky"
  ]
}
```

2. **为每个子包创建 tsconfig.json**  
```json
// packages/util/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "../../dist/util",  // 输出到根目录 dist 下的对应包目录
    "rootDir": "./src",
    "tsBuildInfoFile": "../../dist/util/.tsbuildinfo" // 独立的构建信息文件
  },
  "include": ["src/**/*.ts"],
  "references": []  // util 不依赖其他包
}
```

```json
// packages/shared/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "../../dist/shared",
    "rootDir": "./src",
    "tsBuildInfoFile": "../../dist/shared/.tsbuildinfo" // 独立的构建信息文件
  },
  "references": [
    { "path": "../util" } // 声明依赖 util 包
  ]
}
```


#### 五、安装依赖与构建
1. **安装所有依赖（pnpm 自动处理工作区链接）**  
```bash
cd ../../  # 返回根目录
pnpm install
```

2. **验证依赖链接**  
```bash
pnpm list --recursive
```
输出应显示：  
```
daiyunzhou@daiyunzhouMacBook-Pro testmonorepo % pnpm list --recursive
Legend: production dependency, optional only, dev only

yunzhou@1.0.0 /Users/daiyunzhou/code/study/testmonorepo

devDependencies:
lerna 8.1.2

@yunzhou/shared@1.0.0 /Users/daiyunzhou/code/study/testmonorepo/packages/shared

dependencies:
@yunzhou/util link:../util

devDependencies:
typescript 5.8.3

@yunzhou/util@0.0.1 /Users/daiyunzhou/code/study/testmonorepo/packages/util

devDependencies:
typescript 5.8.3
```

3. **构建所有包**  

根目录创建 `scripts` 目录，添加 `build.sh` 脚本：

```bash
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
```

#### 六、配置与启动 Verdaccio 私有仓库
1. **启动 Verdaccio 服务**  
```bash
verdaccio
```
服务默认运行在 `http://localhost:4873`，浏览器访问可查看仓库状态。

2. **配置 npmrc 指向私有仓库**  
在项目根目录创建 `.npmrc` 文件：  
```
@yunzhou:registry=http://localhost:4873
```

3. **注册发布用户**  

```bash
npm adduser --registry=http://localhost:4873
```
如果忘记了用户名或密码，可通过 `/Users/daiyunzhou/.config/verdaccio/htpasswd` 删除后重启verdaccio服务重置。

4. **登录私有仓库**  

```sh
npm login --registry=http://localhost:4873
```

#### 七、发布到私有仓库
1. **手动更新版本号**  
```bash
# 更新 util 包版本
cd packages/util
npm version patch  # 或手动修改 package.json 中的 version 字段
cd ../..

# 同理更新 shared 包版本
cd packages/shared
npm version patch
cd ../..
```

2. **执行发布流程（按依赖顺序）**  
```bash
# 发布 util 包
pnpm --filter @yunzhou/util publish --registry=http://localhost:4873

# 发布 shared 包
pnpm --filter @yunzhou/shared publish --registry=http://localhost:4873
```

3. **验证发布结果**  
访问 `http://localhost:4873`，应看到 `@yunzhou/util` 和 `@yunzhou/shared` 已发布。

#### 九、关键问题总结
1. **工作区配置**：必须通过 `pnpm-workspace.yaml` 声明工作区。  
2. **依赖声明**：子包间依赖使用 `workspace:*` 协议，确保本地链接。  
3. **构建输出**：配置 TypeScript 输出到根目录 `dist` 下的对应包目录。  
4. **发布流程**：手动更新版本号后，按依赖顺序发布子包。  
5. **私有仓库**：通过 `.npmrc` 配置作用域指向私有仓库，避免全局修改。
