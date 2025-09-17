#!/bin/sh
set -e

# ==============================
# Sing-box 一键安装/更新脚本 (Alpine)
# 支持架构: amd64 / arm64
# 安装目录: /etc/sing-box/
# ==============================

# 检查依赖
apk update && apk add --no-cache curl wget tar bash

# 获取 CPU 架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)   ARCH=amd64 ;;
    aarch64)  ARCH=arm64 ;;
    *) echo "❌ 不支持的架构: $ARCH"; exit 1 ;;
esac

# 获取最新版本号
VER=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d '"' -f4)

echo "📦 正在下载 Sing-box ${VER} (${ARCH}) ..."
wget -q https://github.com/SagerNet/sing-box/releases/download/${VER}/sing-box-${VER}-linux-${ARCH}.tar.gz -O /tmp/sing-box.tar.gz

# 解压并安装
tar -xvf /tmp/sing-box.tar.gz -C /tmp
mkdir -p /etc/sing-box/conf
mv -f /tmp/sing-box-${VER}-linux-${ARCH}/sing-box /etc/sing-box/sing-box

# 建立配置文件（如果不存在）
[ ! -f /etc/sing-box/config.json ] && echo '{}' > /etc/sing-box/config.json

# 创建 systemd service
cat >/etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=Sing-box Service
After=network.target

[Service]
ExecStart=/etc/sing-box/sing-box run -c /etc/sing-box/config.json
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
systemctl daemon-reexec
systemctl enable sing-box
systemctl restart sing-box

echo "✅ Sing-box ${VER} 安装/更新完成！"
echo "👉 查看运行状态: systemctl status sing-box"
echo "👉 配置文件路径: /etc/sing-box/config.json"
