#!/bin/bash

# 批量启动所有角色
echo "启动所有Clawdbot角色..."
echo "========================================="

# 启动领导者
echo "1. 启动领航者 (🚀)..."
./scripts/start-leader.sh &
sleep 2

# 启动思考者
echo "2. 启动哲思者 (💡)..."
./scripts/start-thinker.sh &
sleep 2

# 启动执行者
echo "3. 启动实干家 (⚡)..."
./scripts/start-executor.sh &
sleep 2

# 启动协调者
echo "4. 启动和谐者 (🤝)..."
./scripts/start-coordinator.sh &
sleep 2

echo "========================================="
echo "所有角色启动完成！"
echo ""
echo "检查进程："
ps aux | grep "clawdbot --profile" | grep -v grep
echo ""
echo "查看日志："
ls -la logs/*.log 2>/dev/null || echo "日志目录为空"
echo "========================================="
