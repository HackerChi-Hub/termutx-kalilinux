#!/data/data/com.termux/files/usr/bin/bash
# Kali Nethunter 安装收尾脚本
# 作者：黑客驰（hackerchi）
# 依赖环境变量：
#   DESTINATION - Kali 根目录（例如 /data/data/.../home/kali-arm64-full）
#   SETARCH     - 架构：arm64 / armhf

fix_profile() {
    if [ -f "${DESTINATION}/root/.bash_profile" ]; then
        # 清除可能导致自动退出之类的 if...fi 段
        sed -i '/if/,/fi/d' "${DESTINATION}/root/.bash_profile"
    fi
}

fix_sudo() {
    chmod +s "${DESTINATION}/usr/bin/sudo" 2>/dev/null || :
    chmod +s "${DESTINATION}/usr/bin/su" 2>/dev/null || :
    mkdir -p "${DESTINATION}/etc/sudoers.d"
    echo "kali    ALL=(ALL:ALL) ALL" > "${DESTINATION}/etc/sudoers.d/kali"
    echo "Set disable_coredump false" > "${DESTINATION}/etc/sudo.conf"
}

fix_uid() {
    GID="$(id -g)"
    # 将 Kali 中的 kali 用户 / 组 UID/GID 设置成与 Termux 当前用户一致，避免文件权限问题
    startkali -r usermod -u "$UID" kali 2>/dev/null || :
    startkali -r groupmod -g "$GID" kali 2>/dev/null || :
}

create_xsession_handler() {
    if [ "$SETARCH" = "arm64" ]; then
        LIBGCCPATH=/usr/lib/aarch64-linux-gnu
    else
        LIBGCCPATH=/usr/lib/arm-linux-gnueabihf
    fi

    VNC_WRAPPER="${DESTINATION}/usr/bin/vnc"
    cat > "$VNC_WRAPPER" <<- EOF
#!/bin/bash
# 简易 VNC 管理脚本（在 Kali 内执行：vnc start/stop/status/kill/passwd）

vnc_start() {
    if [ ! -f ~/.vnc/passwd ]; then
        vnc_passwd
    fi
    USR=\$(whoami)
    if [ "\$USR" = "root" ]; then
        SCR=:1
    else
        SCR=:2
    fi
    export USER=\$USR
    LD_PRELOAD=$LIBGCCPATH/libgcc_s.so.1 nohup vncserver \$SCR >/dev/null 2>&1 </dev/null
}

vnc_stop() {
    vncserver -kill :1 2>/dev/null
    vncserver -kill :2 2>/dev/null
    return \$?
}

vnc_passwd() {
    vncpasswd
    return \$?
}

vnc_status() {
    session_list=\$(vncserver -list 2>/dev/null)
    if [[ "\$session_list" == *"590"* ]]; then
        echo "\$session_list"
    else
        echo "当前没有正在运行的 VNC 会话。"
        echo "可以通过命令：vnc start  启动新会话。"
    fi
}

vnc_kill() {
    pkill Xtigervnc 2>/dev/null
    return \$?
}

case "\$1" in
    start)
        vnc_start
        ;;
    stop)
        vnc_stop
        ;;
    status)
        vnc_status
        ;;
    kill)
        vnc_kill
        ;;
    passwd)
        vnc_passwd
        ;;
    *)
        echo "[!] 用法：vnc {start|stop|status|kill|passwd}"
        ;;
esac
EOF
    chmod +x "$VNC_WRAPPER"
}

### 主流程

fix_profile
fix_sudo
fix_uid
create_xsession_handler