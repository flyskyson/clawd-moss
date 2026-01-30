#!/bin/bash
# MOSS恢复脚本
# 当健康检查发现问题时运行此脚本

echo "🚑 MOSS恢复脚本 - $(date)"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置文件路径
CONFIG_FILE="$HOME/.clawdbot/clawdbot.json"
BACKUP_FILE="$HOME/.clawdbot/clawdbot.json.backup"
MEMORY_DIR="$HOME/clawd/memory"

# 1. 检查并恢复配置文件
echo -e "\n1. ${YELLOW}检查配置文件...${NC}"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "   ${RED}❌ 配置文件不存在${NC}"
    if [ -f "$BACKUP_FILE" ]; then
        echo -e "   ${GREEN}✅ 从备份恢复配置...${NC}"
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        echo "   配置已从备份恢复"
    else
        echo -e "   ${RED}❌ 备份文件也不存在，无法恢复${NC}"
        echo "   请重新运行: clawdbot configure"
        exit 1
    fi
else
    echo -e "   ${GREEN}✅ 配置文件存在${NC}"
fi

# 2. 创建备份（如果不存在）
echo -e "\n2. ${YELLOW}创建配置备份...${NC}"
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo -e "   ${GREEN}✅ 备份已创建${NC}"
else
    echo -e "   ${GREEN}✅ 备份已存在${NC}"
fi

# 3. 检查记忆目录
echo -e "\n3. ${YELLOW}检查记忆系统...${NC}"
if [ ! -d "$MEMORY_DIR" ]; then
    echo -e "   ${YELLOW}⚠️  记忆目录不存在，创建中...${NC}"
    mkdir -p "$MEMORY_DIR"
    echo -e "   ${GREEN}✅ 记忆目录已创建${NC}"
    
    # 创建基本记忆文件
    echo "# 记忆目录" > "$MEMORY_DIR/INDEX.md"
    echo "记忆系统初始化于 $(date)" >> "$MEMORY_DIR/INDEX.md"
else
    echo -e "   ${GREEN}✅ 记忆目录存在${NC}"
    MEMORY_COUNT=$(find "$MEMORY_DIR" -name "*.md" -type f | wc -l)
    echo "   记忆文件数量: $MEMORY_COUNT"
fi

# 4. 重启Gateway
echo -e "\n4. ${YELLOW}重启Gateway...${NC}"
GATEWAY_PID=$(ps aux | grep -i "clawdbot-gateway" | grep -v grep | awk '{print $2}')

if [ -n "$GATEWAY_PID" ]; then
    echo "   当前Gateway PID: $GATEWAY_PID"
    echo "   发送重启信号..."
    kill -USR1 "$GATEWAY_PID" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ 重启信号已发送${NC}"
        echo "   等待5秒让Gateway重启..."
        sleep 5
    else
        echo -e "   ${RED}❌ 发送重启信号失败${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  Gateway未运行${NC}"
    echo "   需要手动启动Gateway"
    echo "   命令: clawdbot gateway start"
fi

# 5. 检查重启后的状态
echo -e "\n5. ${YELLOW}检查重启后状态...${NC}"
sleep 3
NEW_GATEWAY_PID=$(ps aux | grep -i "clawdbot-gateway" | grep -v grep | awk '{print $2}')

if [ -n "$NEW_GATEWAY_PID" ]; then
    echo -e "   ${GREEN}✅ Gateway运行中 (PID: $NEW_GATEWAY_PID)${NC}"
    
    # 检查端口
    if lsof -i :18789 > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ 端口 18789 正在监听${NC}"
    else
        echo -e "   ${YELLOW}⚠️   端口 18789 未监听${NC}"
    fi
else
    echo -e "   ${RED}❌ Gateway启动失败${NC}"
    echo "   请检查日志: tail -100 $HOME/.clawdbot/logs/gateway.log"
fi

# 6. 创建每日备份脚本
echo -e "\n6. ${YELLOW}设置自动备份...${NC}"
BACKUP_SCRIPT="$HOME/clawd/daily-backup.sh"
cat > "$BACKUP_SCRIPT" << 'EOF'
#!/bin/bash
# 每日自动备份脚本
BACKUP_DIR="$HOME/clawd-backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

echo "📦 每日备份 - $(date)"
echo "备份目录: $BACKUP_DIR"

# 备份配置
cp "$HOME/.clawdbot/clawdbot.json" "$BACKUP_DIR/"

# 备份记忆（只备份最近7天）
find "$HOME/clawd/memory" -name "*.md" -mtime -7 -exec cp {} "$BACKUP_DIR/" \;

# 清理旧备份（保留最近30天）
find "$HOME/clawd-backups" -type d -mtime +30 -exec rm -rf {} \;

echo "✅ 备份完成"
EOF

chmod +x "$BACKUP_SCRIPT"
echo -e "   ${GREEN}✅ 备份脚本已创建${NC}"
echo "   位置: $BACKUP_SCRIPT"
echo "   可以添加到cron: 0 2 * * * $BACKUP_SCRIPT"

# 7. 创建快速参考文件
echo -e "\n7. ${YELLOW}创建快速参考...${NC}"
QUICK_REF="$HOME/clawd/MOSS快速参考.md"
cat > "$QUICK_REF" << 'EOF'
# MOSS快速参考

## 当MOSS卡顿/无响应时

### 第一步：运行健康检查
```bash
bash ~/clawd/health-check.sh
```

### 第二步：根据检查结果
1. **如果Gateway未运行**：
   ```bash
   clawdbot gateway start
   ```

2. **如果配置文件问题**：
   ```bash
   bash ~/clawd/recover-moss.sh
   ```

3. **如果只是临时卡顿**：
   ```bash
   # 重启Gateway
   kill -USR1 $(pgrep -f "clawdbot-gateway")
   sleep 10
   ```

### 第三步：检查日志
```bash
tail -100 ~/.clawdbot/logs/gateway.log
```

## 预防措施
1. **每日备份**：运行 `bash ~/clawd/daily-backup.sh`
2. **定期检查**：每周运行健康检查
3. **避免危险操作**：谨慎使用 `clawdbot configure`

## 紧急联系人
- 问题记录：查看 `~/clawd/memory/` 目录
- 配置备份：`~/.clawdbot/clawdbot.json.backup`
- 恢复脚本：`~/clawd/recover-moss.sh`

## 记住
MOSS是脆弱的系统，依赖多个组件。耐心和定期维护很重要。
EOF

echo -e "   ${GREEN}✅ 快速参考已创建${NC}"

# 完成
echo -e "\n${GREEN}✅ 恢复脚本执行完成${NC}"
echo "================================"
echo "建议操作："
echo "1. 测试MOSS是否恢复正常"
echo "2. 运行一次健康检查确认：bash ~/clawd/health-check.sh"
echo "3. 设置每日备份：crontab -e 添加 '0 2 * * * $BACKUP_SCRIPT'"
echo ""
echo "恢复完成于: $(date)"