# Kali Nethunter 2025.4 Termux 安装脚本说明

## 简介
本仓库提供由 **黑客驰（hackerchi）** 编写的 Termux 无需 root 安装 Kali Nethunter 脚本，自动完成以下流程：

- 检测 CPU 架构（arm64 / armhf）
- 选择并下载指定变体（full / minimal / nano）
- 校验 SHA256
- 解压 rootfs
- 创建启动脚本与网络配置
- 调用 `finaltouchup.sh` 完成收尾

适配最新的官方 rootfs 索引：  
`http://kali.download/nethunter-images/current/rootfs/`

## 可选 rootfs 版本（2025-09-23 更新）

| 文件名 | 架构 | 体积 | 说明 |
| --- | --- | --- | --- |
| kali-nethunter-rootfs-full-amd64.tar.xz | amd64 | 2.5 GiB | 完整功能 |
| kali-nethunter-rootfs-full-arm64.tar.xz | arm64 | 2.1 GiB | 完整功能 |
| kali-nethunter-rootfs-full-armhf.tar.xz | armhf | 2.0 GiB | 完整功能 |
| kali-nethunter-rootfs-full-i386.tar.xz | i386 | 2.2 GiB | 完整功能 |
| kali-nethunter-rootfs-minimal-\*.tar.xz | amd64/arm64/armhf/i386 | 123–139 MiB | 精简版 |
| kali-nethunter-rootfs-nano-\*.tar.xz | amd64/arm64/armhf/i386 | 175–194 MiB | 极简版 |
| `SHA256SUMS` | 所有架构 | 1.3 KiB | 校验文件 |

> 脚本使用的下载地址格式：  
> `https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-${chroot}-${SETARCH}.tar.xz`

## 依赖条件

- Termux（Android）
- 网络可访问 `kali.download`
- 必需软件：`proot`、`tar`、`axel`
- `dos2unix`（可选，用于处理 `SHA256SUMS`）

脚本内会自动执行 `apt update && apt upgrade`，并安装缺失依赖。

## 环境变量

| 变量 | 说明 |
| --- | --- |
| `DESTINATION` | Kali 根目录（默认 `$HOME/kali-${SETARCH}`） |
| `SETARCH` | `arm64` 或 `armhf`，由脚本自动检测 |

## 核心函数概览

- `fix_profile`：清理 `root/.bash_profile` 中可能导致自动退出的逻辑
- `fix_sudo`：修复 `sudo`/`su` 权限，写入 `sudoers.d/kali`
- `fix_uid`：同步 `kali` 用户/组的 UID/GID 到 Termux 当前用户，避免权限问题
- `create_xsession_handler`：在 Kali 内生成 `vnc` 管理脚本（start/stop/status/kill/passwd）
- `setvariant`：交互选择 rootfs 变体
- `checksysinfo`：读取 `getprop ro.product.cpu.abi` 判断架构
- `checkdeps`：安装依赖并升级包
- `seturl`：配置下载链接与校验文件名（处理带版本号的 SHA 条目）
- `gettarfile` / `getsha` / `checkintegrity`：下载并校验 rootfs
- `extract`：使用 `proot --link2symlink tar -xf` 解压
- `detect_destination`：定位解压出的 Kali 根目录
- `createloginfile`：生成 `startkali` / `startkali-minimal` / `startkali-nano` 启动脚本
- `resolvconf`：写入 DNS 配置
- `finalwork`：执行 `finaltouchup.sh` 完成最终配置

## 使用步骤

1. **克隆或下载脚本**  
   ```bash
   git clone https://github.com/<yourrepo>/Nethunter-In-Termux.git
   cd Nethunter-In-Termux
   ```

2. **给脚本执行权限**  
   ```bash
   chmod +x kalinethunter finaltouchup.sh
   ```

3. **运行安装脚本**  
   ```bash
   ./kalinethunter
   ```
   - 按提示选择变体（full/minimal/nano）
   - 如需跳过 HTTPS 校验可传参 `--insecure`

4. **启动 Kali**  
   - full：`startkali`
   - minimal：`startkali-minimal`
   - nano：`startkali-nano`
   - root 模式：`startkali -r`


## 常见问题

1. **未知架构**  
   - 若 `getprop ro.product.cpu.abi` 非 `arm64-v8a` 或 `armeabi/armeabi-v7a`，安装会终止。

2. **下载失败**  
   - 检查网络或使用 `./kalinethunter --insecure` 绕过证书问题（不推荐）。

3. **SHA 校验失败**  
   - 删除 `kalifs-*.tar.xz` 后重跑脚本；确保 `SHA256SUMS` 来自同一目录。

4. **未找到 Kali 目录**  
   - 脚本会自动搜索；若仍失败，按提示提交 `ls`/`find` 输出。

5. **DNS/网络异常**  
   - `resolv.conf` 会写入 Google DNS，可自行修改。

## 致谢

- 作者：黑客驰（hackerchi）  
- 联系方式：`hackerchi99@gmail.com`  
- 博客：`https://hackerchi.top`

> “现在你已经可以在 Termux 中愉快地使用 Kali Nethunter 了！:)”
