#!/bin/bash
# Git推送辅助脚本

echo "🚀 开始推送代码到远程仓库..."

# 检查远程仓库
echo "📡 检查远程仓库配置..."
git remote -v

# 检查当前分支
echo "🌿 当前分支: $(git branch --show-current)"

# 检查未提交的更改
echo "📋 检查未提交的更改..."
git status --short

# 询问是否继续
read -p "是否继续推送？(y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 用户取消操作"
    exit 1
fi

# 尝试推送
echo "🔄 尝试推送到远程仓库..."
echo "如果提示输入用户名/密码，请使用："
echo "1. GitHub用户名"
echo "2. Personal Access Token（不是密码）"
echo ""

# 设置超时，避免卡住
timeout 30 git push -u origin main

if [ $? -eq 0 ]; then
    echo "✅ 推送成功！"
    echo ""
    echo "📊 仓库状态："
    git log --oneline -3
else
    echo "❌ 推送失败"
    echo ""
    echo "🔧 可能的解决方案："
    echo "1. 检查网络连接"
    echo "2. 确认GitHub凭据"
    echo "3. 使用SSH方式："
    echo "   git remote set-url origin git@github.com:flyskyson/clawd-moss.git"
    echo "4. 生成SSH密钥："
    echo "   ssh-keygen -t ed25519 -C \"你的邮箱\""
    echo "5. 添加公钥到GitHub："
    echo "   cat ~/.ssh/id_ed25519.pub"
fi