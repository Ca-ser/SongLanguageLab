# 歌语 · Song Language Lab

歌曲语言练习应用。每首歌可保存本地音频、多份歌词和各版本的练习进度。

## 本机 Web 测试

打开 http://127.0.0.1:8787/。请一直使用这个地址和同一个浏览器配置文件。浏览器按站点地址保存数据，切换端口或清除站点数据会看到另一个歌曲库。

如需重新启动，从项目根目录在 PowerShell 执行：

    powershell -ExecutionPolicy Bypass -File .\scripts\run-test.ps1 -Build

第一次需要 Flutter、uv 和 Python 3.12。脚本构建 Web 并启动 FastAPI；停止时在终端按 Ctrl+C。已有 Web 构建时，可以省略 -Build。

## 试用

1. 新建歌曲，选择一个 MP3 或 WAV，再导入 UTF-8 LRC 或 TXT。
2. 导入第二份歌词。两个版本都会保留，使用按钮可以切换，删除只作用于指定版本。
3. 在 LRC 版本中切换练习句，试用循环当前句和播放速度。TXT 可以逐句阅读和跟读。
4. 点击跟读录音，授权麦克风后录一段并回放。录音限 1 分钟，离开该句后丢弃。
5. 有音频时可点击自动提取歌词。Whisper 模型在本机进行转写，生成一份可选草稿。伴奏较响或唱词不清时，请使用人工校对的歌词。
6. 刷新浏览器，确认导入的歌曲、歌词版本和练习进度仍在。本机和各浏览器的歌曲库独立。

音频上限为 25 MB，每份歌词文件上限为 1 MB。歌曲和歌词默认保存在浏览器 IndexedDB 中。自动提取只在明确确认后把音频交给本机服务处理。

## 开发

客户端在 client/，测试在 client/test/，本机转写服务在 services/audio/。Flutter 测试和静态检查可从 client/ 运行；后端测试从 services/audio/ 执行 uv run --locked python -m unittest -v。

本次交付面向 Windows 上的浏览器测试。Android、iOS、Windows 原生和 macOS 仍需各自的工具链和真机验证。
