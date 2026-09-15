# 创建 GitHub 仓库

GitHub 连接可以向已有仓库写入文件，但不能代替用户新建仓库。请完成一次下面的操作：

1. 登录 GitHub，打开：<https://github.com/new?owner=Tian-Ya-1>
2. `Repository name` 填写：`win10-offline-dev-kit`
3. `Description` 可填写：`Win10 20H2 offline development environment preparation kit`
4. 选择 `Private`。
5. 不要勾选 `Add a README file`。
6. `.gitignore template` 选择 `None`。
7. `License` 选择 `None`。
8. 点击 `Create repository`。

创建后，确保 ChatGPT 的 GitHub 连接有权访问这个私有仓库。随后即可上传本工具包中的全部文本、配置和脚本。

安装程序和 VSIX 下载文件被 `.gitignore` 排除，不会进入 Git 历史；请在联网电脑运行下载脚本后，把本地完整目录复制到 U 盘。
