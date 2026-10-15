# 小智 AI 固件 — 立创·实战派 S3（DeepSeek 定制版）

基于 [78/xiaozhi-esp32](https://github.com/78/xiaozhi-esp32) v2.5.2 构建的 ESP32-S3 语音助手固件，
针对 **立创·实战派 S3 开发板（LCKFB SZPI ESP32-S3）** 定制：

| 定制项 | 内容 |
|---|---|
| 唤醒词 | **大肥鱼**（拼音 `da fei yu`，离线 MultiNet7 识别） |
| 开机/主页图标 | **鲸鱼娘透明背景状态 GIF**（待机 / 开心 / 聆听 / 思考 / 说话） |
| 开发板 | `lckfb/szpi-esp32s3`（构建名 `lckfb-lichuang-dev`） |
| 目标芯片 | ESP32-S3 / 16MB Flash / 8MB assets 分区 |
| IDF 版本 | ESP-IDF v6.1 |

---

## 一、直接烧录（推荐，不需要编译环境）

### 1. 连接开发板

用 **数据线**（不是只能充电的线）连接电脑，板子上电。

### 2. 烧录整包固件

最简单的办法是烧 `merged-binary`（一个文件包含所有分区）：

```bash
cd firmware
esptool --chip esp32s3 -p COM3 -b 460800 --before default-reset --after hard-reset \
  write-flash 0x0 xiaozhi-lckfb-szpi-esp32s3-merged.bin
```

或者按分区分别烧（在 `firmware/` 目录下执行）：

```bash
esptool --chip esp32s3 -b 460800 --before default-reset --after hard-reset \
  write-flash --flash-mode dio --flash-freq 80m --flash-size 16MB "@flash_args"
```

### 3. 查看串口日志

```bash
python -m serial.tools.miniterm COM7 115200
```

> 烧录后设备会进入配网模式（热点或 BluFi），按屏幕提示配网即可。

### Windows 用户

如果本机装好了 ESP-IDF，可以直接用仓库里的脚本（会自动找串口）：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\flash.ps1
```

---

## 二、从源码编译

### 1. 准备 ESP-IDF v6.1

本项目要求 **ESP-IDF v6.1**（最低 v6.0.1，不支持 5.x）。

```powershell
# Windows
.\scripts\idf-env.ps1     # 按自己的安装路径改这个文件里的 IDF_PATH
```

### 2. 编译

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\build.ps1
```

等价于：

```bash
python scripts/build.py lckfb/szpi-esp32s3 --name lichuang-dev
```

### 3. 应用源码改动

`source-changes/` 里是相对上游的全部改动：

- `xiaozhi-deepseek.patch` — 合并补丁，可直接 `git apply`
- `files/` — 改动后的完整文件（按工程目录结构放置）
- `patches/` — 按文件拆分的独立补丁

```bash
git clone https://github.com/78/xiaozhi-esp32.git
cd xiaozhi-esp32
git apply /path/to/xiaozhi-deepseek.patch
```

---

## 三、定制实现说明

### 唤醒词：大肥鱼

WakeNet 只能识别固定词，**无法自定义**，所以改用 ESP-SR 的 **MultiNet7 命令词识别**。

配置写在板级 `config.json` 里（`main/boards/lckfb/szpi-esp32s3/config.json`）：

```json
"CONFIG_USE_CUSTOM_WAKE_WORD=y",
"CONFIG_USE_AFE_WAKE_WORD=n",
"CONFIG_SR_MN_CN_NONE=n",
"CONFIG_SR_MN_CN_MULTINET7_QUANT=y",
"CONFIG_CUSTOM_WAKE_WORD=\"da fei yu\"",
"CONFIG_CUSTOM_WAKE_WORD_DISPLAY=\"大肥鱼\"",
"CONFIG_CUSTOM_WAKE_WORD_THRESHOLD=20"
```

要点：

- `CONFIG_CUSTOM_WAKE_WORD` 必须是**拼音、空格分隔** —— 引擎按拼音建模。
- `CONFIG_CUSTOM_WAKE_WORD_DISPLAY` 是识别后发给服务器的问候语，用中文。
- `THRESHOLD` 越小越灵敏（1–99，默认 20）。误唤醒多就调大，喊不动就调小。
- 必须**关闭** AFE/ESP WakeNet，否则两者会冲突。

### 图标：鲸鱼娘状态动画

主页使用基于 `Desktop/1.png` 统一角色制作的透明背景 GIF，资源位于 `assets/state_gifs/`：

- `idle.gif`：待机
- `happy.gif`：开心
- `listening.gif`：聆听
- `thinking.gif`：思考 / 连接中
- `speaking.gif`：说话 / 播报

`LcdDisplay::SetEmotion()` 将服务器情绪映射到对应 GIF；设备状态切换时，应用层会主动选择聆听、思考和说话动画，不再显示默认笑脸。

GIF 已预生成并随仓库发布；编译时由 `main/display/whale_girl_state_gifs.c` 内嵌 GIF 数据，背景透明且不依赖运行时文件。

---

## 四、已知问题与排查

### 烧录

| 现象 | 原因 / 解决 |
|---|---|
| 找不到串口 | 换数据线；换 USB 口；CH343 需装驱动 |
| 端口被占用 | 关掉串口监视器 / 其它串口工具 |
| 烧录失败 | 按住 BOOT 再按 RST 进下载模式 |

### 唤醒

| 现象 | 原因 / 解决 |
|---|---|
| 喊了没反应 | 读作 *dà féi yú*；把 `THRESHOLD` 调小（如 10） |
| 老是误唤醒 | 把 `THRESHOLD` 调大（如 40） |
| 串口无 MultiNet 日志 | 确认 `CONFIG_USE_CUSTOM_WAKE_WORD=y` 且 `SR_MN_CN_MULTINET7_QUANT=y` |

### 编译（Windows）

- **`ninja: fatal: CreateProcess: The parameter is incorrect`**
  Windows 命令行长度上限。把工程放到短路径再编译（如 `D:\xz\xiaozhi`）。
- **`git`/`curl`/PowerShell 无法访问 github.com**
  Windows schannel TLS 损坏（`SEC_E_NO_CREDENTIALS`）。改用 Python 的 OpenSSL 通道，
  并设 `IDF_GITHUB_ASSETS=dl.espressif.com/github_assets` 走乐鑫镜像。
- **`idf.py` 报编码错误**
  设 `PYTHONUTF8=1`，或控制台执行 `chcp 65001`。
- **pip 装依赖极慢**
  换国内源：`--index-url https://pypi.tuna.tsinghua.edu.cn/simple`，
  并记得带 `--constraint espidf.constraints.v6.1.txt`。

---

## 五、许可

固件基于 [78/xiaozhi-esp32](https://github.com/78/xiaozhi-esp32)（MIT）。
DeepSeek 鲸鱼图标版权归 DeepSeek 所有，仅供个人学习使用。
