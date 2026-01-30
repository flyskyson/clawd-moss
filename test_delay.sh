#!/bin/bash

echo "=== BlueBubbles 延迟测试 ==="
echo "开始时间: $(date '+%H:%M:%S')"

# 测试 1: Ping 服务器
echo -n "1. Ping 服务器: "
start=$(python3 -c 'import time; print(int(time.time() * 1000))')
curl -s "http://localhost:1234/api/v1/ping?password=Flyskylj1" > /dev/null
end=$(python3 -c 'import time; print(int(time.time() * 1000))')
echo "$((end - start))ms"

# 测试 2: 检查服务器状态
echo -n "2. 服务器状态: "
if curl -s "http://localhost:1234/api/v1/ping?password=Flyskylj1" | grep -q "pong"; then
    echo "正常"
else
    echo "异常"
fi

echo "结束时间: $(date '+%H:%M:%S')"