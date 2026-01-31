# 领航者 (🚀) 配置说明

## 基本信息
- **角色名称**: 领航者
- **英文标识**: leader
- **性格特征**: 查看 /Users/lijian/clawd/workspaces/leader/SOUL.md
- **创建时间**: 2026年 2月 1日 星期日 07时13分10秒 CST

## 启动方式
```bash
# 方式1：使用启动脚本
./scripts/start-leader.sh

# 方式2：手动启动
export CLAWDBOT_PROFILE=leader
export CLAWDBOT_CONFIG_PATH="/Users/lijian/clawd/config/roles/leader-config.json"
clawdbot --profile leader agent --channel feishu
```

## 配置详情
- **网关端口**: 18800
- **认证令牌**: a698131a55ed0fb20f99c376
- **工作空间**: /Users/lijian/clawd/workspaces/leader
- **飞书群组**: oc_a0553eda9014c201e6f6dbd88a00f0b4

## 文件结构
```
/Users/lijian/clawd/workspaces/leader/
├── SOUL.md              # 角色性格定义
├── IDENTITY.md          # 角色身份信息
├── USER.md             # 用户信息
├── AGENTS.md           # 工作空间说明
└── memory/             # 角色记忆
    └── 2026-02-01.md  # 今日日志
```

## 注意事项
1. 首次启动需要确认飞书群组权限
2. 确保端口 18800 未被占用
3. 角色会主动加入群组 oc_a0553eda9014c201e6f6dbd88a00f0b4
4. 在群组中使用前缀：[领航者]

---
*自动生成于 2026年 2月 1日 星期日 07时13分10秒 CST*
