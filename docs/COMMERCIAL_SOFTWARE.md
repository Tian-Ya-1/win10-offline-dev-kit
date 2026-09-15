# Office、MATLAB、Adobe 准备说明

商业软件安装包不提交到 GitHub。请在联网电脑上通过自己的正版账号和授权渠道下载，再复制到 `offline-bundle\commercial`。

## Microsoft Office 2021 64 位

推荐：Office 2021 64 位。个人许可证从 Microsoft 账户的“服务和订阅”页面下载安装；单位批量许可证从单位软件中心、管理员或 Microsoft 批量许可渠道取得。

官方入口：

- <https://account.microsoft.com/services>
- <https://support.microsoft.com/office/download-install-or-reinstall-microsoft-365-or-office-2021>

注意：

- Office LTSC Professional Plus 2021 属于批量许可产品，只有单位确实提供相应许可证时才使用。
- 不要使用来源不明的 KMS、破解器或二次封装镜像。
- Office 2021 将在 2026 年 10 月结束支持；离线电脑仍可运行，但不会继续获得安全更新。

## MATLAB R2022b Windows 64 位

你的 Windows 10 20H2 满足 MATLAB R2022b 的官方最低系统版本要求。联网电脑上：

1. 登录 MathWorks 账户：<https://www.mathworks.com/downloads/>。
2. 在以前的版本中选择 `R2022b`。
3. 选择 Windows 64 位安装程序。
4. 使用下载但不安装功能，把需要的产品下载完整。
5. 将整个下载目录复制到离线电脑，不要只复制最外层安装程序。

离线激活通常还需要与许可证对应的文件安装密钥和许可证文件。请提前从学校、单位许可证管理员或自己的 MathWorks 许可证页面取得。

官方离线说明：

- <https://www.mathworks.com/help/install/ug/download-products-without-installing.html>
- <https://www.mathworks.com/help/install/ug/install-mathworks-software-on-offline-machine.html>

## Adobe PDF

只需要查看、打印和批注 PDF：下载 Acrobat Reader 64 位完整离线安装包。

需要编辑、合并、OCR 和格式转换：使用有许可证的 Acrobat Pro DC 64 位。

官方入口：

- Reader 企业/完整安装包：<https://get.adobe.com/reader/enterprise/>
- Acrobat Pro 下载：<https://helpx.adobe.com/acrobat/install.html>

不要选择 Acrobat 2020 作为长期方案，因为它已经停止安全支持。

## 建议目录

准备完成后可按下面的形式存放：

```text
offline-bundle\commercial\
├─ Office2021\
├─ MATLAB_R2022b\
└─ Adobe\
```
