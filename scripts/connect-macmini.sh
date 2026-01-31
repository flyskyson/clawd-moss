#!/bin/bash
# connect-macmini.sh
# 一键连接到家里的Mac mini
# 创建时间：2026-01-31
# 创建目的：简化SSH连接流程，提高远程操作效率

echo "🚀 正在连接到Mac mini..."
echo "主机：192.168.3.8"
echo "用户：lijian"
echo ""

# 检查网络连通性
echo "📡 检查网络连接..."
if ping -c 1 -W 2 192.168.3.8 > /dev/null 2>&1; then
    echo "✅ 网络连接正常"
else
    echo "⚠️  无法ping通192.168.3.8，请检查："
    echo "   1. Mac mini是否开机"
    echo "   2. 是否在同一网络"
    echo "   3. 防火墙设置"
    read -p "是否继续尝试SSH连接？(y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 连接取消"
        exit 1
    fi
fi

# 检查SSH服务
echo "🔍 检查SSH服务端口..."
if nc -z -w 2 192.168.3.8 22 > /dev/null 2>&1; then
    echo "✅ SSH服务可用（端口22开放）"
else
    echo "❌ SSH服务不可用，可能的原因："
    echo "   1. SSH服务未开启"
    echo "   2. 防火墙阻止了端口22"
    echo "   3. Mac mini的SSH配置问题"
    echo ""
    echo "💡 解决方案："
    echo "   在Mac mini上开启SSH服务："
    echo "   系统设置 → 通用 → 共享 → 远程登录（打开）"
    read -p "是否继续尝试SSH连接？(y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 连接取消"
        exit 1
    fi
fi

# 建立SSH连接
echo "🔗 建立SSH连接..."
echo "----------------------------------------"
echo "如果提示' authenticity of host'，输入: yes"
echo "如果提示'Password:'，输入Mac mini的登录密码"
echo "连接成功后，输入 'exit' 退出"
echo "----------------------------------------"
echo ""

# 执行SSH连接
ssh lijian@192.168.3.8

# 连接后的提示
echo ""
echo "----------------------------------------"
echo "SSH连接已结束"
echo "返回代码: $?"
echo "----------------------------------------"

# 使用说明
echo ""
echo "📖 使用说明："
echo "1. 将此脚本保存到方便的位置，如 ~/scripts/"
echo "2. 添加执行权限：chmod +x connect-macmini.sh"
echo "3. 可以直接执行：./connect-macmini.sh"
echo "4. 或创建别名：alias ssh-mac='~/scripts/connect-macmini.sh'"
echo ""
echo "🔄 更新记录："
echo "2026-01-31: 创建初始版本，包含网络检查和错误处理"