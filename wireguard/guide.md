# 🛡️ WireGuard 纯终端配置管理器 (wg-manager)

一个轻量级、无 Web UI 依赖的 Python 脚本，专为**纯终端环境**设计。它通过本地 JSON 缓存管理 WireGuard 服务端和客户端的生命周期，支持自动分配 IP、直接在终端打印高对比度二维码，并完美支持“生成配置 ➔ 手动微调 ➔ 重新生成二维码”的灵活工作流。

## ✨ 核心特性

- **🖥️ 纯终端体验**：无需图形界面，直接在 SSH 终端中生成带颜色的高对比度二维码，手机扫码秒识别。
- **💾 状态持久化**：使用 `wg-manager.json` 记录所有密钥和 IP 分配状态，杜绝多次添加客户端导致的 IP 冲突或配置覆盖。
- **🔄 无缝微调支持**：生成配置文件后，可随时使用文本编辑器修改（如更改 DNS 或路由），然后通过 `qr-file` 命令基于修改后的文件重新生成二维码。
- **🌐 双栈支持**：原生支持 IPv4 和 IPv6 虚拟网段的自动规划与分配。
- **🛡️ 安全优先**：自动为生成的 `.conf` 和 `.key` 文件设置 `600` 权限；支持一键开启 PresharedKey (PSK) 以抵抗量子计算/中间人攻击。

## 📦 环境要求

在运行脚本前，请确保您的系统已安装以下基础组件：

```bash
# 1. Python 3 (通常系统自带)
python3 --version

# 2. WireGuard 工具集 (用于生成密钥)
# Ubuntu/Debian:
sudo apt update && sudo apt install wireguard-tools
# CentOS/RHEL/Rocky:
sudo yum install epel-release && sudo yum install wireguard-tools

# 3. qrencode (强烈推荐！用于在终端输出带颜色、高识别率的二维码)
# Ubuntu/Debian:
sudo apt install qrencode
# CentOS/RHEL/Rocky:
sudo yum install qrencode
```
*(注：如果没有安装 `qrencode`，脚本会自动降级使用 Python 的 `qrcode` 库输出黑白字符画；如果两者都没有，脚本会给出友好的安装提示。)*

## 🚀 快速开始

1. 下载脚本并赋予执行权限：
   ```bash
   wget https://raw.githubusercontent.com/vxzman/Colloctor/refs/heads/main/wireguard/wg-gen.py 
   chmod +x wg-manager.py
   ```

2. 查看帮助信息：
   ```bash
   ./wg-manager.py
   ```

## 📖 使用指南

### 1. 初始化服务器与第一个客户端
运行交互式向导，配置服务端参数并生成第一个客户端：
```bash
./wg-manager.py init
```
*脚本会依次询问：接口名称、公网域名/IP、监听端口、IPv4/IPv6 网段、客户端名称、DNS 等。*

### 2. 添加新客户端
自动分配下一个可用 IP，生成配置，并**直接在终端打印二维码**：
```bash
./wg-manager.py add
```

### 3. 查看所有客户端列表
快速查看已分配的客户端名称、IP 地址和创建时间：
```bash
./wg-manager.py list
```

### 4. 删除客户端
从缓存中移除，删除本地配置文件，并**自动从服务端配置中剔除该 Peer**：
```bash
./wg-manager.py remove client02
```

### 5. 重新生成二维码 (基于缓存名称)
如果二维码过期或需要重新扫码：
```bash
./wg-manager.py qr client01
```

### 6. 🌟 针对任意配置文件生成二维码 (微调专用)
如果您手动修改了 `.conf` 文件，或者配置文件在其他路径，可以直接指定路径生成二维码：
```bash
./wg-manager.py qr-file /path/to/custom_client.conf
```

---

## 💡 典型微调工作流 (推荐)

在实际运维中，我们经常需要在生成配置后修改特定的 DNS 或路由规则。本脚本完美支持此流程：

1. **生成配置**：运行 `./wg-manager.py add`，输入名称 `myphone`。
2. **手动微调**：使用 `nano` 或 `vim` 编辑生成的配置文件：
   ```bash
   nano wireguard-configs/clients/myphone/myphone.conf
   ```
   *(例如：将 `DNS = 1.1.1.1` 修改为 `DNS = 192.168.5.13, 223.5.5.5`，保存退出)*
3. **重新生成二维码**：运行以下命令，脚本会读取您**刚刚修改后的最新内容**生成二维码：
   ```bash
   ./wg-manager.py qr myphone
   # 或者
   ./wg-manager.py qr-file wireguard-configs/clients/myphone/myphone.conf
   ```
4. **扫码连接**：打开手机 WireGuard App，扫描终端屏幕上的二维码即可。

---

## ⚙️ 服务端部署提示 (重要！)

脚本生成的服务端配置文件 (`wireguard-configs/server/wg0.conf`) 中包含了 NAT 转发的注释。在正式启动服务前，请务必完成以下系统级配置，否则客户端将**无法访问外网**：

**1. 开启 IPv4/IPv6 转发**
```bash
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**2. 配置防火墙/NAT (假设您的服务器出口网卡为 `eth0`)**
取消 `wg0.conf` 中 `PostUp` 和 `PostDown` 的注释，或者手动执行：
```bash
# IPv4 NAT
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# 如果使用了 IPv6，还需添加：
sudo ip6tables -A FORWARD -i wg0 -j ACCEPT
sudo ip6tables -A FORWARD -o wg0 -j ACCEPT
sudo ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```
*(注意：请将 `eth0` 替换为您服务器实际的公网网卡名称，可通过 `ip route | grep default` 查看)*

**3. 启动服务**
```bash
sudo cp wireguard-configs/server/wg0.conf /etc/wireguard/
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

---

## ⚠️ 安全与注意事项

1. **保护缓存文件**：`wg-manager.json` 包含了所有客户端和服务端的**私钥**。请确保该文件的权限为 `600`，且不要将其上传到公开的代码仓库。
2. **终端字体大小**：如果终端二维码扫码困难，请尝试在 SSH 客户端（如 PuTTY, iTerm2, Windows Terminal）中**调小字体**或**放大终端窗口**，以获得更清晰的像素点。
3. **备份**：建议定期备份 `wireguard-configs/` 目录和 `wg-manager.json` 文件。

---

## 📜 许可证

MIT License. 自由使用，修改和分发。

--- 

*如有问题或功能建议，欢迎提出 Issue 或 PR！*