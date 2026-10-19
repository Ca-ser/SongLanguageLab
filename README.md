# 歌语 · Song Language Lab

用于边学边开发的 Flutter + Dart 歌曲语言学习项目。

## 开始
在桌面 SongLanguageLab 文件夹打开 PowerShell：

```powershell
.\scripts\doctor.ps1
.\scripts\run-web.ps1
```

或用 VS Code 打开 client，选择 Chrome/Edge 后按 F5。项目已配置现有 SDK 路径 C:\src\flutter。无需另装 Dart。

## 首版
- 原创示例歌词、上一句/下一句、跟读指引和进度。
- UTF-8 LRC/TXT 本地导入，多时间戳展开与排序。
- 音频文件选择入口，仅记录当前会话文件名。
- 文件不上传；关闭或刷新页面后导入和进度不保留。
- 尚未实现真实播放、逐句循环、录音、自动提取或数据库。

## 学习顺序
1. client/lib/main.dart：应用从哪里开始。
2. client/lib/domain：理解数据模型和纯函数解析。
3. client/lib/features/library：文件选择与错误提示。
4. client/lib/features/practice：有状态组件和按钮。
5. client/test：修改解析器，再运行测试。

```powershell
cd client
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat build web
```

## 平台限制
Web 为本机首个验证目标。Android 尚缺 SDK：安装 Android Studio，通过 SDK Manager 配置 SDK、命令行工具及模拟器，执行 flutter doctor --android-licenses，再连接设备。Windows 原生构建尚缺 Visual Studio（不是 VS Code），需要 Desktop development with C++ 工作负载。iOS/macOS 需在 Mac 安装 Xcode 后构建；Windows 无法在本机完成这两者构建。实际结果见 docs/verification.md。

## 后续路线
真实音频播放和逐句循环 → 本地歌曲存储 → 录音跟读 → 独立 Python + FastAPI 转写及时间对齐服务。Web 文件访问与原生文件系统有差异，后续持久化需分别设计。
