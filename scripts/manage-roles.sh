#!/bin/bash

# 角色管理脚本
case "$1" in
    start)
        ./scripts/start-all-roles.sh
        ;;
    stop)
        echo "停止所有角色..."
        pkill -f "clawdbot --profile"
        echo "已停止"
        ;;
    status)
        echo "角色运行状态："
        echo "========================================="
        for role in leader thinker executor coordinator; do
            if ps aux | grep -q "clawdbot --profile $role"; then
                echo "✓ $role: 运行中"
            else
                echo "✗ $role: 未运行"
            fi
        done
        echo "========================================="
        ;;
    restart)
        ./scripts/manage-roles.sh stop
        sleep 2
        ./scripts/manage-roles.sh start
        ;;
    logs)
        tail -f logs/*.log 2>/dev/null || echo "没有找到日志文件"
        ;;
    *)
        echo "使用方式: $0 {start|stop|status|restart|logs}"
        echo ""
        echo "命令说明："
        echo "  start    - 启动所有角色"
        echo "  stop     - 停止所有角色"
        echo "  status   - 查看运行状态"
        echo "  restart  - 重启所有角色"
        echo "  logs     - 查看实时日志"
        exit 1
        ;;
esac
