# 架构

Flutter 负责歌曲库、歌词导入、练习和录音。Song 持有多个 LyricVersion，每个版本包含 LyricLine，并有独立的练习位置。选择和删除通过版本 ID 定位。同名版本可以共存。

LibraryStore 管理歌曲元数据和音频，变更在一个事务中写入。Web 使用 IndexedDB，原生平台使用应用支持目录。只有用户确认自动提取时，音频才进入回环地址的 FastAPI 服务。服务返回带时间的草稿，不替换当前练习版本。

Web 播放使用 audioplayers，LRC 时间戳定义循环范围。录音用 record 在本机捕获，录制结束可回放。转写服务与 Flutter 源码独立，缺少服务时仍能导入和练习。
