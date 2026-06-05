---

# PXM Transparent Proxy Scripts (pxm-tproxy)

一套通用、解耦的 Linux 透明代理规则管理脚本。支持 **TCP REDIRECT + UDP TPROXY (混合模式)** 与 **纯 UDP/TCP TPROXY 模式**。

本套脚本彻底移除了对特定代理软件（如 mihomo）的硬编码依赖，可无缝迁移并适配 **mihomo (Clash.Meta)**、**sing-box**、**Xray** 等任何支持 TPROXY/REDIRECT 的现代代理核心。

## ✨ 核心特性

1. **完全解耦**：通过 systemd 实例化机制 (`%i`)，脚本自动适配对应的代理服务（如 `redir-tproxy@sing-box` 自动依赖 `sing-box.service`）。
2. **灵活的自身流量绕过**：支持通过用户组 (`EXCLUDE_GID`) 或路由标记 (`ROUTING_MARK`) 绕过代理软件自身的流量，防止路由环路。**两者共存时，优先使用 `EXCLUDE_GID`**。
3. **智能生命周期管理**：使用 systemd `BindsTo=` 强绑定。当底层代理核心重启或崩溃时，透明代理规则会自动清理，**杜绝断网或流量泄露**。
4. **动态局域网旁路**：纯 TPROXY 脚本会自动获取本机的全局 IPv4 CIDR 并加入旁路列表，防止局域网互访流量被错误代理。
5. **现代网络栈**：基于 `nftables` 和 `iproute2` 构建，性能优异且规则清晰。

---

## 📂 目录与文件结构

建议将所有文件按以下结构放置：

```text
/usr/local/libexec/
├── redir-tproxy.sh      # 混合模式脚本 (TCP REDIRECT + UDP TPROXY)
└── tproxy.sh            # 纯 TPROXY 模式脚本 (TCP + UDP TPROXY)

/etc/systemd/system/
├── redir-tproxy@.service
└── tproxy@.service

/etc/pxm/                # 配置文件目录 (需手动创建)
├── sing-box_redir-tproxy.conf
├── mihomo_tproxy.conf
└── xray_redir-tproxy.conf
```

---

## 🛠️ 安装与配置步骤

### 1. 部署脚本与服务
```bash
# 1. 赋予脚本执行权限
sudo chmod +x /usr/local/libexec/redir-tproxy.sh
sudo chmod +x /usr/local/libexec/tproxy.sh

# 2. 创建统一的配置目录
sudo mkdir -p /etc/pxm
sudo chmod 700 /etc/pxm

# 3. 重载 systemd 守护进程
sudo systemctl daemon-reload
```

### 2. 编写配置文件
在 `/etc/pxm/` 目录下创建配置文件。文件名必须遵循 `<实例名>_<模式>.conf` 的格式。

#### 示例 A：混合模式配置 (`/etc/pxm/sing-box_redir-tproxy.conf`)
```ini
# 代理软件监听的端口
REDIRECT_PORT=7892
TPROXY_PORT=7893

# 路由与标记 (需与代理软件内部配置一致)
FWMARK=0x80
TABLE_ID=80
NFTABLES_TABLE=tproxy_singbox

# 自身流量绕过规则 (二选一，同时存在时优先使用 EXCLUDE_GID)
# 获取方法: id -g <运行代理软件的用户名> (例如 sing-box 或 mihomo)
EXCLUDE_GID=65534
# ROUTING_MARK=0x100
```

#### 示例 B：纯 TPROXY 模式配置 (`/etc/pxm/xray_tproxy.conf`)
```ini
TPROXY_PORT=1081
FWMARK=0xFF
TABLE_ID=255
NFTABLES_TABLE=tproxy_xray

# 绕过规则
EXCLUDE_GID=65534
```

> **💡 提示：如何获取 `EXCLUDE_GID`？**
> 如果您的代理软件以独立用户运行（推荐），请运行：`id -g 用户名`。
> 例如：`id -g sing-box` 或 `id -g mihomo`。

---

## 🚀 使用方法

脚本通过 systemd 的实例化服务 (`@`) 进行管理。`@` 后面的名称即为**实例名**，它必须与配置文件的 `<实例名>` 部分完全匹配，且通常应与底层代理服务的名称一致。

### 启动与停止

```bash
# 启动 sing-box 的混合透明代理规则
sudo systemctl start redir-tproxy@sing-box

# 停止 mihomo 的纯 TPROXY 规则
sudo systemctl stop tproxy@mihomo

# 查看规则运行状态
sudo systemctl status redir-tproxy@sing-box
```

### 开机自启

```bash
sudo systemctl enable redir-tproxy@sing-box
sudo systemctl enable tproxy@xray
```

### 命名对照表

| 执行的 systemd 命令 | 读取的配置文件 | 依赖的底层服务 |
| :--- | :--- | :--- |
| `redir-tproxy@sing-box` | `/etc/pxm/sing-box_redir-tproxy.conf` | `sing-box.service` |
| `tproxy@mihomo` | `/etc/pxm/mihomo_tproxy.conf` | `mihomo.service` |
| `redir-tproxy@xray@home` | `/etc/pxm/xray@home_redir-tproxy.conf` | `xray@home.service` |

---

## 🔍 故障排查 (Troubleshooting)

### 1. 提示 `FATAL: TPROXY_INSTANCE not set`
**原因**：未通过 systemd 启动，或手动执行脚本时未设置环境变量。
**解决**：始终使用 `systemctl start redir-tproxy@<实例名>` 启动。若需手动测试，请执行：
```bash
sudo TPROXY_INSTANCE=sing-box /usr/local/libexec/redir-tproxy.sh start
```

### 2. 提示 `FATAL: Either EXCLUDE_GID or ROUTING_MARK must be set`
**原因**：配置文件中既没有填写 `EXCLUDE_GID`，也没有填写 `ROUTING_MARK`。
**解决**：检查 `/etc/pxm/*.conf`，确保至少填写了其中一项，且没有拼写错误。

### 3. 代理软件重启后，网络断开或无法上网
**原因**：代理软件崩溃，但透明代理规则未被清理，导致流量被黑洞。
**解决**：检查 systemd 服务是否配置了 `BindsTo=%i.service`。正确配置后，代理软件停止时规则会自动清除。可手动执行 `sudo systemctl stop redir-tproxy@<实例名>` 清理残留规则。

### 4. 局域网设备无法访问本机服务 (如 SMB, SSH)
**原因**：`redir-tproxy.sh` 中的静态 bypass 列表可能未覆盖您的特殊网段，或 `tproxy.sh` 的动态获取失败。
**解决**：
- 对于 `redir-tproxy.sh`：可手动修改脚本中的 `bypass_list` 元素，添加您的特殊网段。
- 对于 `tproxy.sh`：检查脚本运行日志 `journalctl -u tproxy@<实例名>`，查看是否有 `WARN: No local IPv4 CIDRs detected` 警告。

### 5. 规则未生效 (流量未进入代理)
**检查清单**：
1. 确认代理软件内部已开启 `tproxy` 或 `redir` 监听，且端口与配置文件一致。
2. 确认代理软件内部的 `mark` 或 `so_mark` 设置与配置文件中的 `FWMARK` 一致。
3. 运行 `nft list table ip <NFTABLES_TABLE>` 检查规则是否已成功注入。
4. 运行 `ip rule show` 和 `ip route show table <TABLE_ID>` 检查路由策略是否生效。

---

## 📜 许可证
本脚本遵循 MIT 许可证开源。自由使用、修改和分发。

--- 
