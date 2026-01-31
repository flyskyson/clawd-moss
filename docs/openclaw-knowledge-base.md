# OpenClaw 官方文档知识库
**创建时间**: 2026-01-31 22:05  
**最后更新**: 2026-01-31 22:05
**文档版本**: 基于 docs.openclaw.ai 官方文档
**状态**: 学习中，定期更新

---

## 📚 目录
- [1. OpenClaw 概述](#1-openclaw-概述)
- [2. 核心架构](#2-核心架构)
- [3. 技能系统](#3-技能系统)
- [4. 安装与配置](#4-安装与配置)
- [5. 渠道集成](#5-渠道集成)
- [6. 安全与最佳实践](#6-安全与最佳实践)
- [7. 生态系统](#7-生态系统)
- [8. 学习路线](#8-学习路线)
- [9. 更新日志](#9-更新日志)

---

## 1. OpenClaw 概述

### 1.1 什么是 OpenClaw？
```
🦞 开源AI Agent网关框架
🔗 连接WhatsApp/Telegram/Discord/iMessage与AI代理
🛠️ 基于AgentSkills标准的技能系统
🌐 拥有ClawHub公共技能仓库 (700+技能)
```

### 1.2 核心定位
- **目标**: 让AI代理通过常用通信平台与用户交互
- **设计理念**: 模块化、安全、易扩展
- **技术栈**: Node.js ≥ 22, WebSocket, 多协议适配

### 1.3 关键特性
```
📱 多平台支持: WhatsApp, Telegram, Discord, iMessage
🤖 AI代理集成: Pi编码代理 (RPC模式)
🔄 流式响应: 实时消息流和工具调用
🔐 安全设计: 权限控制、环境隔离、秘密管理
📅 自动化: Cron作业、Webhook、Gmail集成
```

---

## 2. 核心架构

### 2.1 系统架构图
```
WhatsApp / Telegram / Discord / iMessage (+ plugins)
 │
 ▼
 ┌───────────────────────────┐
 │ Gateway                   │ ws://127.0.0.1:18789 (loopback-only)
 │ (single source)           │
 │                           │ http://<gateway-host>:18793
 │                           │ /__openclaw__/canvas/ (Canvas host)
 └───────────┬───────────────┘
             │
 ├─ Pi agent (RPC)
 ├─ CLI (openclaw …)
 ├─ Chat UI (SwiftUI)
 ├─ macOS app (OpenClaw.app)
 ├─ iOS node via Gateway WS + pairing
 └─ Android node via Gateway WS + pairing
```

### 2.2 网关 (Gateway)
- **角色**: 核心进程，管理所有渠道连接
- **默认端口**: 18789 (WebSocket), 18793 (Canvas HTTP)
- **运行模式**: 每个主机一个网关（推荐）
- **远程访问**: 支持Tailscale、SSH隧道

### 2.3 网络模型
```
🔒 安全优先: 默认本地回环 (127.0.0.1:18789)
🌐 远程支持: Tailnet访问、SSH隧道
📱 节点连接: iOS/Android设备通过WebSocket配对
🖥️ Canvas主机: HTTP文件服务器用于节点WebView
```

---

## 3. 技能系统 (重点!)

### 3.1 技能加载位置 (优先级从高到低)
```
1. 🏢 工作空间技能: /skills (当前工作目录)
2. 🏠 本地管理技能: ~/.openclaw/skills (用户目录)
3. 📦 捆绑技能: 安装包自带技能 (最低优先级)
4. ➕ 额外目录: 通过配置添加的目录
```

### 3.2 技能文件格式 (SKILL.md)

#### 基本结构
```markdown
---
name: skill-name
description: 技能描述
metadata: {"openclaw": {"requires": {"bins": ["python3"]}}}
---

# 技能名称

技能详细说明和使用方法...
```

#### 必需字段
- `name`: 技能名称 (唯一标识)
- `description`: 简短描述
- `metadata`: JSON格式的元数据 (单行)

#### 可选字段
- `homepage`: 技能网站链接
- `user-invocable`: true/false (是否用户可调用)
- `disable-model-invocation`: true/false (是否从模型提示中排除)
- `command-dispatch`: tool (直接调用工具)
- `command-tool`: 工具名称
- `command-arg-mode`: raw (原始参数模式)

### 3.3 技能门控系统 (Gating)

#### 加载时过滤条件
```json
{
  "openclaw": {
    "requires": {
      "bins": ["python3", "node"],      // 必须存在的二进制文件
      "env": ["API_KEY"],               // 必须的环境变量
      "config": ["browser.enabled"]     // 必须的配置项
    },
    "os": ["darwin", "linux"],          // 支持的操作系统
    "always": true,                     // 总是加载 (跳过其他检查)
    "emoji": "🔧",                      // 技能图标
    "primaryEnv": "API_KEY"             // 主要环境变量
  }
}
```

### 3.4 配置覆盖系统

#### 配置文件 (~/.openclaw/openclaw.json)
```json
{
  "skills": {
    "entries": {
      "skill-name": {
        "enabled": true,                // 启用/禁用技能
        "apiKey": "YOUR_KEY",           // API密钥
        "env": {                        // 环境变量注入
          "API_KEY": "YOUR_KEY"
        },
        "config": {                     // 技能特定配置
          "endpoint": "https://api.example.com",
          "model": "default"
        }
      }
    },
    "allowBundled": ["skill1", "skill2"] // 允许的捆绑技能白名单
  }
}
```

### 3.5 ClawHub 技能仓库

#### 公共技能注册中心
- **网站**: https://clawhub.com
- **功能**: 发现、安装、更新、备份技能
- **同步**: 与本地技能系统同步

#### 常用命令
```bash
# 安装技能到工作空间
clawhub install

# 更新所有已安装技能
clawhub update --all

# 扫描并发布更新
clawhub sync --all
```

---

## 4. 安装与配置

### 4.1 系统要求
```
📦 运行时: Node.js ≥ 22
🔧 包管理器: npm 或 pnpm
💻 操作系统: macOS, Linux, Windows (WSL2)
```

### 4.2 快速安装
```bash
# 推荐: 全局安装
npm install -g openclaw@latest
# 或: pnpm add -g openclaw@latest

# 初始设置
openclaw onboard --install-daemon

# 登录渠道 (如WhatsApp)
openclaw channels login  # 显示QR码

# 启动网关
openclaw gateway --port 18789
```

### 4.3 控制面板
```
🖥️ 本地访问: http://127.0.0.1:18789/
📊 功能: 聊天、配置、节点管理、会话监控
```

### 4.4 从源码安装
```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build  # 首次运行自动安装UI依赖
pnpm build
openclaw onboard --install-daemon
```

---

## 5. 渠道集成

### 5.1 支持的渠道

#### WhatsApp
- **协议**: WhatsApp Web (Baileys库)
- **特性**: 个人聊天、群组、媒体支持
- **安全**: 需要QR码登录，支持allowFrom白名单

#### Telegram
- **协议**: Bot API (grammY库)
- **特性**: 私聊、群组、频道、内联模式
- **配置**: 需要Bot Token

#### Discord
- **协议**: Bot API (channels.discord.js)
- **特性**: 服务器、频道、线程、Slash命令
- **权限**: 需要适当的Bot权限

#### iMessage
- **协议**: 本地imsg CLI (仅macOS)
- **特性**: 原生消息集成
- **限制**: 仅限macOS系统

### 5.2 群组聊天支持
```
👥 默认模式: 提及触发 (@openclaw)
🔧 配置选项: 可设置为始终响应
🔒 安全控制: 可配置白名单群组
📋 会话隔离: 每个群组独立会话
```

### 5.3 媒体支持
```
🖼️ 图片: 发送和接收
🎵 音频: 支持语音笔记（可选转录）
📎 文档: 文件传输
🎤 语音: 语音消息处理
```

---

## 6. 安全与最佳实践

### 6.1 安全设计原则
```
🔒 最小权限: 默认严格，需要显式配置
🛡️ 环境隔离: 技能运行在独立环境
🔐 秘密管理: 环境变量注入，不写入日志
🌐 网络限制: 默认本地回环，需要显式开启远程
```

### 6.2 配置安全
```json
{
  "channels": {
    "whatsapp": {
      "allowFrom": ["+15555550123"],  // 白名单号码
      "groups": {
        "*": { "requireMention": true }  // 群组需要提及
      }
    }
  },
  "messages": {
    "groupChat": {
      "mentionPatterns": ["@openclaw"]  // 提及模式
    }
  }
}
```

### 6.3 技能安全注意事项
```
⚠️ 第三方技能: 视为可信代码，需要审查
🔒 沙箱运行: 建议用于不受信任的输入
🔐 秘密保护: API密钥等敏感信息不写入提示
📊 权限控制: 限制技能的系统访问权限
```

### 6.4 威胁模型
```
1. 渠道账户安全: 保护登录凭证
2. 技能代码安全: 审查第三方技能
3. 系统访问安全: 限制文件系统访问
4. 网络访问安全: 控制网络出口
5. 数据隐私安全: 保护用户数据
```

---

## 7. 生态系统

### 7.1 核心组件

#### Pi 编码代理
- **角色**: 主要AI代理，专注于编码任务
- **模式**: RPC模式，支持工具流式调用
- **集成**: 通过网关与渠道连接

#### 节点系统 (iOS/Android)
- **功能**: 扩展设备作为计算节点
- **连接**: 通过WebSocket与网关配对
- **能力**: Canvas渲染、摄像头、位置等

#### Canvas 系统
- **用途**: WebView界面渲染
- **访问**: HTTP服务器提供Canvas内容
- **应用**: 自定义UI、仪表板、控制面板

### 7.2 插件系统
- **扩展性**: 插件可以添加新渠道和功能
- **技能集成**: 插件可以自带技能
- **配置**: 通过openclaw.plugin.json定义

### 7.3 配套应用
```
🍎 macOS应用: 原生应用，菜单栏伴侣
📱 iOS应用: 节点功能，Canvas表面
🤖 Android应用: 节点功能，Chat + Camera
🪟 Windows: 通过WSL2支持
🐧 Linux: 原生应用支持
```

---

## 8. 学习路线

### 8.1 初学者路线
```
第1周: 安装体验 → 基础配置 → 简单使用
第2周: 技能系统 → 创建第一个技能
第3周: 渠道配置 → 多平台集成
第4周: 安全配置 → 生产环境部署
```

### 8.2 开发者路线
```
第1月: 源码阅读 → 架构理解 → 插件开发
第2月: 技能开发 → 贡献技能 → 社区参与
第3月: 高级特性 → 性能优化 → 定制开发
```

### 8.3 运维路线
```
第1月: 部署实践 → 监控设置 → 故障排除
第2月: 安全加固 → 备份策略 → 高可用
第3月: 自动化运维 → 规模扩展 → 最佳实践
```

### 8.4 推荐学习资源
1. **官方文档**: docs.openclaw.ai (本知识库来源)
2. **GitHub仓库**: github.com/openclaw/openclaw
3. **ClawHub**: clawhub.com (技能仓库)
4. **社区**: Discord/Twitter社区讨论

---

## 9. 更新日志

### 2026-01-31 v1.0
✅ **知识库创建**: 基于官方文档整理
✅ **核心内容**: 涵盖架构、技能、安装、安全等
✅ **学习路线**: 提供分阶段学习建议
✅ **行动计划**: 包含实施建议和路线图

### 待更新内容
- [ ] 实际使用案例和最佳实践
- [ ] 故障排除和常见问题
- [ ] 性能优化指南
- [ ] 高级配置示例

---

## 📞 联系与贡献

### 核心团队
- **Peter Steinberger** ([@steipete](https://twitter.com/steipete)) - 创建者
- **Mario Zechner** ([@badlogicc](https://twitter.com/badlogicgames)) - Pi创建者
- **Clawd** - 太空龙虾，项目命名灵感

### 核心贡献者
- **Maxim Vovshin** (@Hyaxia) - Blogwatcher技能
- **Nacho Iacovino** (@nachoiacovino) - 位置解析

### 许可证
**MIT** - 自由如海洋中的龙虾 🦞

### 项目名言
> "We're all just playing with our own prompts." — 一个AI，可能token上头了

---

## 🔄 定期更新机制

### 更新频率
```
🔄 每周检查: 官方文档更新
📅 每月同步: 知识库内容更新
🚨 紧急更新: 重大变化立即通知
```

### 更新内容跟踪
1. **版本更新**: OpenClaw新版本特性
2. **文档更新**: 官方文档内容变化
3. **安全更新**: 安全建议和漏洞修复
4. **生态更新**: ClawHub新技能和工具

### 通知机制
- ✅ 飞书即时通知
- 📧 重要更新邮件摘要
- 📊 定期更新报告
- 🔔 紧急安全警报

---

*本知识库将持续更新，保持与官方文档同步*
*最后同步时间: 2026-01-31 22:05*
*下次计划更新: 2026-02-07*