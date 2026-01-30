#!/bin/bash
# MOSS健康检查脚本
# 当MOSS卡顿或无响应时运行此脚本

echo "🔍 MOSS健康检查 - $(date)"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查Gateway进程
echo -e "\n1. ${YELLOW}检查Gateway进程...${NC}"
GATEWAY_PID=$(ps aux | grep -i "clawdbot-gateway" | grep -v grep | awk '{print $2}')
if [ -n "$GATEWAY_PID" ]; then
    echo -e "   ${GREEN}✅ Gateway运行中 (PID: $GATEWAY_PID)${NC}"
    echo "   进程信息:"
    ps aux | grep -i "clawdbot-gateway" | grep -v grep
else
    echo -e "   ${RED}❌ Gateway未运行${NC}"
fi

# 2. 检查Clawdbot进程
echo -e "\n2. ${YELLOW}检查Clawdbot进程...${NC}"
CLAWDBOT_PID=$(ps aux | grep -i "clawdbot$" | grep -v grep | awk '{print $2}')
if [ -n "$CLAWDBOT_PID" ]; then
    echo -e "   ${GREEN}✅ Clawdbot运行中 (PID: $CLAWDBOT_PID)${NC}"
else
    echo -e "   ${RED}❌ Clawdbot未运行${NC}"
fi

# 3. 检查端口监听
echo -e "\n3. ${YELLOW}检查端口监听...${NC}"
PORT=18789
if lsof -i :$PORT > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ 端口 $PORT 正在监听${NC}"
else
    echo -e "   ${RED}❌ 端口 $PORT 未监听${NC}"
fi

# 4. 检查配置文件
echo -e "\n4. ${YELLOW}检查配置文件...${NC}"
CONFIG_FILE="$HOME/.clawdbot/clawdbot.json"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "   ${GREEN}✅ 配置文件存在${NC}"
    CONFIG_SIZE=$(stat -f%z "$CONFIG_FILE" 2>/dev/null || stat -c%s "$CONFIG_FILE" 2>/dev/null)
    echo "   文件大小: $CONFIG_SIZE 字节"
    echo "   最后修改: $(stat -f%Sm "$CONFIG_FILE" 2>/dev/null || stat -c%y "$CONFIG_FILE" 2>/dev/null)"
else
    echo -e "   ${RED}❌ 配置文件不存在${NC}"
fi

# 5. 检查备份文件
echo -e "\n5. ${YELLOW}检查备份文件...${NC}"
BACKUP_FILE="$HOME/.clawdbot/clawdbot.json.backup"
if [ -f "$BACKUP_FILE" ]; then
    echo -e "   ${GREEN}✅ 备份文件存在${NC}"
else
    echo -e "   ${YELLOW}⚠️  备份文件不存在${NC}"
fi

# 6. 检查记忆系统
echo -e "\n6. ${YELLOW}检查记忆系统...${NC}"
MEMORY_DIR="$HOME/clawd/memory"
if [ -d "$MEMORY_DIR" ]; then
    MEMORY_COUNT=$(find "$MEMORY_DIR" -name "*.md" -type f | wc -l)
    echo -e "   ${GREEN}✅ 记忆目录存在${NC}"
    echo "   记忆文件数量: $MEMORY_COUNT"
    echo "   最近的文件:"
    ls -lt "$MEMORY_DIR"/*.md 2>/dev/null | head -3
else
    echo -e "   ${RED}❌ 记忆目录不存在${NC}"
fi

# 7. 检查日志文件
echo -e "\n7. ${YELLOW}检查日志文件...${NC}"
LOG_FILE="$HOME/.clawdbot/logs/gateway.log"
if [ -f "$LOG_FILE" ]; then
    echo -e "   ${GREEN}✅ 日志文件存在${NC}"
    LOG_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null)
    echo "   日志大小: $((LOG_SIZE / 1024)) KB"
    echo "   最后5条日志:"
    tail -5 "$LOG_FILE"
else
    echo -e "   ${YELLOW}⚠️  日志文件不存在${NC}"
fi

# 8. 简单网络测试
echo -e "\n8. ${YELLOW}网络连接测试...${NC}"
if ping -c 1 -W 2 api.deepseek.com > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ DeepSeek API可达${NC}"
else
    echo -e "   ${RED}❌ DeepSeek API不可达${NC}"
fi

# 总结
echo -e "\n${YELLOW}📊 健康检查总结${NC}"
echo "================================"

PROBLEMS=0
if [ -z "$GATEWAY_PID" ]; then
    echo -e "${RED}❌ 问题: Gateway未运行${NC}"
    PROBLEMS=$((PROBLEMS+1))
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ 问题: 配置文件丢失${NC}"
    PROBLEMS=$((PROBLEMS+1))
fi

if [ $PROBLEMS -eq 0 ]; then
    echo -e "${GREEN}✅ 系统状态正常${NC}"
    echo "建议: 如果MOSS仍然卡顿，可能是临时API问题，请等待几分钟再试"
else
    echo -e "${YELLOW}⚠️  发现 $PROBLEMS 个问题${NC}"
    echo "建议运行恢复脚本: bash $HOME/clawd/recover-moss.sh"
fi

echo -e "\n${YELLOW}🚀 快速恢复命令${NC}"
echo "1. 重启Gateway: kill -USR1 $GATEWAY_PID 2>/dev/null || echo 'Gateway未运行'"
echo "2. 查看详细日志: tail -100 $LOG_FILE"
echo "3. 从备份恢复: cp $BACKUP_FILE $CONFIG_FILE"

echo -e "\n检查完成于: $(date)"
echo "================================"