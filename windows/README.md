# Clipboard10

Windows桌面文字暂存器：最近十条文本剪贴板、十个收藏位、主题分类、托盘和 Ctrl+Shift+V 浮窗。

## 运行与构建

Node.js20+，在Windows下载源码后：
```sh
npm ci
npm start
npm run dist:win
```
生成的Windows x64便携ZIP在 release/；解压后运行Clipboard10.exe。首次依赖安装会下载Electron。未签名，发布包应配合SHA256校验。

最近历史仅存内存，退出后清空；收藏保存在Electron userData目录。没有云同步或网络上传。`CLIPBOARD10_DATA_DIR` 可指定独立数据目录，便于测试/便携使用。开机启动是用户在界面中选择的功能，默认不会代替用户修改。

1.2.1是本次发布工程整理版本：补依赖、打包命令和可指定数据目录；保留1.2.0的主要界面与功能。
