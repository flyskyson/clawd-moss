#!/usr/bin/env python3
"""
check_json_error.py
检查JSON解析错误并修复
"""

import json
import sys
import re

def find_json_error(json_string, position=18039):
    """查找JSON错误位置"""
    print(f"检查JSON字符串，错误位置: {position}")
    print(f"字符串长度: {len(json_string)}")
    
    # 显示错误位置附近的字符
    start = max(0, position - 50)
    end = min(len(json_string), position + 50)
    
    print(f"\n错误位置附近的字符:")
    print("-" * 60)
    print(json_string[start:end])
    print("-" * 60)
    
    # 高亮显示错误位置
    if position < len(json_string):
        print(f"\n错误字符: '{json_string[position]}' (ASCII: {ord(json_string[position])})")
    
    # 检查未闭合的引号
    quote_count = 0
    in_string = False
    escape_next = False
    
    for i, char in enumerate(json_string[:position + 100]):
        if escape_next:
            escape_next = False
            continue
            
        if char == '\\':
            escape_next = True
            continue
            
        if char == '"':
            if not in_string:
                in_string = True
                quote_count += 1
            else:
                in_string = False
    
    print(f"\n引号状态: {'在字符串内' if in_string else '不在字符串内'}")
    print(f"引号计数: {quote_count}")
    
    return in_string

def fix_json_string(json_string):
    """修复JSON字符串"""
    print("\n尝试修复JSON字符串...")
    
    # 方法1: 转义特殊字符
    fixed = json_string
    
    # 转义未转义的控制字符
    control_chars = {
        '\n': '\\n',
        '\r': '\\r',
        '\t': '\\t',
        '\b': '\\b',
        '\f': '\\f',
        '\\': '\\\\',
        '"': '\\"'
    }
    
    # 但要注意不要转义已经转义的字符
    # 简单方法：使用json.dumps重新编码
    try:
        # 先尝试解析
        parsed = json.loads(json_string)
        # 如果能解析，重新编码
        fixed = json.dumps(parsed, ensure_ascii=False)
        print("✅ JSON可以正常解析，重新编码解决格式问题")
        return fixed
    except json.JSONDecodeError as e:
        print(f"解析错误: {e}")
        
        # 方法2: 手动修复常见问题
        # 修复未闭合的字符串
        lines = json_string.split('\n')
        fixed_lines = []
        
        for line in lines:
            # 统计引号
            quote_count = line.count('"') - line.count('\\"')
            if quote_count % 2 != 0:
                # 奇数引号，可能有问题
                print(f"⚠️  行引号不平衡: {line[:50]}...")
                # 在行尾添加闭合引号
                line = line.rstrip() + '"'
            
            fixed_lines.append(line)
        
        fixed = '\n'.join(fixed_lines)
        
        # 再次尝试解析
        try:
            json.loads(fixed)
            print("✅ 手动修复成功")
            return fixed
        except json.JSONDecodeError as e2:
            print(f"手动修复后仍然错误: {e2}")
            
            # 方法3: 使用更宽松的解析
            # 移除可能的BOM字符
            fixed = fixed.replace('\ufeff', '')
            
            # 修复常见的JSON问题
            # 1. 修复未转义的特殊字符
            fixed = re.sub(r'(?<!\\)"', '"', fixed)
            
            # 2. 修复末尾的逗号
            fixed = re.sub(r',\s*}', '}', fixed)
            fixed = re.sub(r',\s*]', ']', fixed)
            
            return fixed

def validate_json(json_string):
    """验证JSON"""
    print("\n验证JSON...")
    
    try:
        data = json.loads(json_string)
        print(f"✅ JSON验证通过")
        print(f"数据类型: {type(data)}")
        
        if isinstance(data, dict):
            print(f"键数量: {len(data)}")
            print(f"键: {list(data.keys())[:5]}...")
        elif isinstance(data, list):
            print(f"列表长度: {len(data)}")
        
        return True, data
    except json.JSONDecodeError as e:
        print(f"❌ JSON验证失败: {e}")
        print(f"错误位置: {e.pos}")
        print(f"错误行: {e.lineno}, 列: {e.colno}")
        print(f"错误消息: {e.msg}")
        
        # 显示错误位置附近的上下文
        if e.pos:
            start = max(0, e.pos - 50)
            end = min(len(json_string), e.pos + 50)
            print(f"\n错误上下文:")
            print(json_string[start:end])
            print("^" * (e.pos - start))
        
        return False, None

def main():
    """主函数"""
    print("🔧 JSON错误检查工具")
    print("=" * 60)
    
    # 检查是否有文件参数
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                json_string = f.read()
            print(f"从文件读取: {file_path}")
        except FileNotFoundError:
            print(f"文件不存在: {file_path}")
            return
    else:
        # 检查最近的错误
        print("请提供JSON文件路径或字符串")
        print("用法: python check_json_error.py <file_path>")
        return
    
    # 验证原始JSON
    is_valid, data = validate_json(json_string)
    
    if not is_valid:
        # 查找错误
        find_json_error(json_string)
        
        # 尝试修复
        fixed_json = fix_json_string(json_string)
        
        # 验证修复后的JSON
        print(f"\n修复后的JSON长度: {len(fixed_json)}")
        is_fixed, fixed_data = validate_json(fixed_json)
        
        if is_fixed:
            print("\n✅ 修复成功！")
            
            # 保存修复后的文件
            output_file = file_path.replace('.json', '_fixed.json')
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(fixed_data, f, indent=2, ensure_ascii=False)
            
            print(f"修复后的文件已保存: {output_file}")
            
            # 显示修复的差异
            print(f"\n修复摘要:")
            print(f"原始长度: {len(json_string)}")
            print(f"修复后长度: {len(fixed_json)}")
            
            if isinstance(fixed_data, dict):
                print(f"修复后的数据结构:")
                for key, value in fixed_data.items():
                    if isinstance(value, (str, int, float, bool, type(None))):
                        print(f"  {key}: {type(value).__name__} = {repr(value)[:50]}...")
                    else:
                        print(f"  {key}: {type(value).__name__}")
        else:
            print("\n❌ 修复失败")
    
    else:
        print("\n✅ 原始JSON已经是有效的")
        
        # 显示JSON结构
        if isinstance(data, dict):
            print(f"\nJSON结构:")
            for key, value in data.items():
                if isinstance(value, (str, int, float, bool, type(None))):
                    print(f"  {key}: {type(value).__name__}")
                elif isinstance(value, (list, dict)):
                    print(f"  {key}: {type(value).__name__} (长度: {len(value)})")

if __name__ == "__main__":
    main()