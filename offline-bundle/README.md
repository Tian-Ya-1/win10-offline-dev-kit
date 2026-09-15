# offline-bundle

在联网 Windows 电脑上运行 `scripts/01-download-free-components.ps1` 后，此目录会自动生成：

```text
installers/      VS Code、Python、MinGW-w64
vsix/            VS Code 离线插件
SHA256SUMS.txt   所有已下载文件的 SHA-256
download-info.txt
```

二进制安装文件被 `.gitignore` 排除，不会误提交到 GitHub。下载完成后，请直接把整个仓库文件夹复制到 U 盘。
