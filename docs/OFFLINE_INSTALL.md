# 离线电脑安装说明

## 安装前检查

1. 按 `Win + R`，输入 `winver`。
2. 确认系统为 Windows 10 20H2、内部版本 19042.804。
3. 打开“设置 → 系统 → 关于”，确认“系统类型”为 64 位操作系统。
4. 系统盘建议至少保留 5 GB 空闲空间。

## 1. 安装 VS Code

运行：

```text
offline-bundle\installers\VSCodeUserSetup-x64.exe
```

安装时勾选：

- 添加到 PATH
- 将“通过 Code 打开”添加到文件右键菜单
- 将“通过 Code 打开”添加到目录右键菜单
- 将 Code 注册为受支持文件类型的编辑器

## 2. 安装 Python

运行：

```text
offline-bundle\installers\python-3.11.9-amd64.exe
```

第一页先勾选 `Add python.exe to PATH`，然后选择 `Install Now`。

安装后重新打开 CMD，执行：

```bat
python --version
pip --version
```

应能看到 Python 3.11.9。

## 3. 安装 MinGW-w64

运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\02-install-mingw.ps1
```

脚本会：

- 校验 MinGW 压缩包 SHA-256
- 解压到 `%USERPROFILE%\Tools\mingw64`
- 将 `%USERPROFILE%\Tools\mingw64\bin` 加入当前用户 PATH
- 检查 `gcc`、`g++` 和 `gdb`

完成后关闭并重新打开 VS Code。

## 4. 安装 VS Code 离线插件

运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\03-install-vsix.ps1
```

也可以在 VS Code 中按 `Ctrl+Shift+P`，执行 `Extensions: Install from VSIX`，逐个选择 `offline-bundle\vsix` 内的文件。

## 5. 配置 C/C++ 工程

在自己的 C/C++ 工程根目录建立 `.vscode` 文件夹，将下列三个模板复制进去：

```text
configs\c_cpp_properties.json
configs\tasks.json
configs\launch.json
```

打开一个 `.cpp` 文件：

- `Ctrl+Shift+B`：编译
- `F5`：调试
- `Ctrl+F5`：运行但不调试

## 6. 配置 Python

1. 在 VS Code 中按 `Ctrl+Shift+P`。
2. 输入 `Python: Select Interpreter`。
3. 选择刚安装的 Python 3.11.9。
4. 打开 `.py` 文件，点击右上角运行按钮。

## 7. 最终检查

运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\04-verify-environment.ps1
```

脚本会检查版本、编译并运行一个最小 C++ 程序，并在仓库根目录生成 `verification-report.txt`。

## 常见问题

### VS Code 找不到 g++

关闭全部 VS Code 和 CMD 窗口后重新打开。如果仍然找不到，确认用户 PATH 中存在：

```text
%USERPROFILE%\Tools\mingw64\bin
```

### 插件提示版本不兼容

联网电脑下载了比离线 VS Code 更新的插件。重新下载最新版 VS Code，或者在插件市场的 `Version History` 中选择兼容版本的 VSIX。

### Python 插件缺少依赖

确认以下四个 VSIX 都已安装：

```text
ms-python.python
ms-python.vscode-pylance
ms-python.debugpy
ms-python.vscode-python-envs
```
