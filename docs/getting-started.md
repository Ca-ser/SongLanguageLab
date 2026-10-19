# 开发与运行
请先阅读根目录 README。用 VS Code 打开 client 文件夹，F5 选择 Chrome。若 PowerShell 脚本被策略阻止，无需修改系统策略，在终端直接执行：

```
C:\src\flutter\bin\flutter.bat run -d chrome
```

Flutter 已带 Dart。依赖下载遇到符号链接提示时，需要手动启用 Windows 开发者模式后重试 pub get。当前配置复用本机 C:\src\flutter；搬到其他机器需修改 .vscode/settings.json 和 scripts 中的路径。

练习歌词请保存为 UTF-8，LRC 如 [00:01.50]Hello，TXT 每个非空行作为一句。LRC 元数据会跳过；offset 元数据暂不应用，尚无真实音频同步。导入失败会保留上一份歌词。当前音频入口只记录本次会话名称。
