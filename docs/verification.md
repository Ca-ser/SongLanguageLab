# 验证记录 · 2026-10-19

## 环境
- Windows 11 25H2，Flutter 3.47.7 stable，Dart 3.13.5，SDK C:\src\flutter。
- 复用现有 Git、VS Code 与 Flutter/Dart 插件，没有重新安装 SDK。
- SDK 未加入全局 PATH；项目脚本临时设置，VS Code 项目设置指定路径。

## 已执行
- flutter doctor -v：SDK 可用、Chrome/Edge 可用；Android SDK 缺失；Visual Studio C++ 缺失；Maven 网络探测超时。doctor 返回 0，但存在上述诊断项。
- flutter create：生成五个平台目录，最终退出 1，原因是 SDK .pub-preload-cache 目录占用。后续依赖解析和 Web 构建能够完成。
- flutter pub add file_selector：依赖下载及 lockfile 更新成功，最终退出 1，原因是 Windows 插件符号链接需要开发者模式。
- flutter analyze：首轮 5 条风格提示，经 dart fix 修正后，无问题。
- flutter test：初始缺少实现，预期失败；实现后 5 项通过，补充导入取消/错误/重置测试后共 7 项通过。
- 代码复核：发现 LRC 空白时间戳行应跳过；增加回归测试复现后修复。最终全套结果记录于 final-checks.md。
- flutter build web：首次构建通过（包含 Wasm dry run）；最终构建结果见 final-checks.md。
- flutter run -d chrome --web-port 8765：调试服务连接成功，进入 Flutter 运行命令界面。
- 内置浏览器打开 localhost:8765，已目视确认中文页面、导入入口及示例练习面板正常显示。浏览器自动点击未确认句子变化，逐句操作由 widget 测试验证，不宣称浏览器交互验收完成。

## 手动配置与限制
- 最终重试 flutter pub get 已返回 0（Got dependencies!）。首次插件安装曾提示开发者模式；后续若 Windows 插件再次出现符号链接错误，请在 Windows 设置中搜索“开发者模式”并启用后重试。未自动更改系统设置。
- Android：安装 Android Studio/Android SDK/JDK，接受 SDK licenses，配置设备或模拟器；网络需能访问 Maven/Google 依赖源。
- Windows：安装 Visual Studio 的 Desktop development with C++ 工作负载。未构建 Windows 可执行文件。
- iOS/macOS：需要 Mac 与 Xcode。这里只生成平台源文件，未构建或签名。
- 后端未部署、未安装转写模型；首版无需 Python。
- 当前音频仅选择文件名，没有音频播放、录音、自动转写或重启后数据保存。

