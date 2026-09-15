# Win10 20H2 离线开发环境工具包

适用系统：Windows 10 专业版 20H2、内部版本 19042.804、64 位。

这套仓库用于在一台联网电脑上准备文件，再通过 U 盘复制到不联网电脑。默认准备：

- Visual Studio Code 最新稳定版，Windows x64 User Installer
- Python 3.11.9 x64
- MinGW-w64：GCC 14.3.0、GDB 16.3、UCRT、POSIX、SEH、Win64
- VS Code 简体中文、C/C++、Python、Pylance、Python Debugger、Python Environments 插件
- MinGW 安装、VSIX 批量安装和环境检查脚本

## 使用顺序

### 1. 在联网的 Windows 电脑下载免费组件

进入仓库目录，打开 PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\01-download-free-components.ps1
```

文件会保存到 `offline-bundle`。脚本完成后还会生成 `SHA256SUMS.txt`。

### 2. 复制到 U 盘

将整个仓库目录连同生成的 `offline-bundle` 一起复制到 U 盘，建议至少预留 2 GB。

### 3. 在离线电脑安装

推荐顺序：

1. 安装 VS Code。
2. 安装 Python，勾选 `Add Python to PATH`。
3. 运行 MinGW 安装脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\02-install-mingw.ps1
```

4. 运行 VS Code 插件安装脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\03-install-vsix.ps1
```

5. 运行检查脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\04-verify-environment.ps1
```

更详细的图形界面安装步骤见 [离线安装说明](docs/OFFLINE_INSTALL.md)。

## 目录说明

```text
configs/         VS Code 的 C/C++ 配置模板
docs/            离线安装说明
scripts/         下载、安装、检查脚本
offline-bundle/  下载脚本生成的安装文件和 VSIX 插件
```

## 安全与许可

- 下载脚本只使用官方来源或项目作者的 GitHub Release。
- MinGW 压缩包使用发布者提供的 SHA-256 固定值校验。
- 其他下载会生成本地 SHA-256 清单，便于检查 U 盘复制前后文件是否一致。
- Windows 10 20H2 已停止安全维护；若电脑联网，建议升级操作系统后再长期使用。
