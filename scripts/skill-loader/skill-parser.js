/**
 * SKILL.md解析器
 * 兼容OpenClaw SKILL.md标准格式
 */

const fs = require('fs');
const path = require('path');
const yaml = require('yaml');

class SkillParser {
  /**
   * 解析SKILL.md文件
   * @param {string} filePath - SKILL.md文件路径
   * @returns {object} 解析后的技能信息
   */
  parseSkillFile(filePath) {
    try {
      // 1. 读取文件内容
      const content = fs.readFileSync(filePath, 'utf8');
      
      // 2. 提取frontmatter
      const frontmatter = this.extractFrontmatter(content);
      
      // 3. 解析metadata
      const metadata = this.parseMetadata(frontmatter.metadata);
      
      // 4. 提取技能内容
      const skillContent = this.extractSkillContent(content);
      
      // 5. 构建技能信息
      const skillInfo = {
        name: frontmatter.name,
        description: frontmatter.description,
        metadata: metadata,
        content: skillContent,
        filePath: filePath,
        directory: path.dirname(filePath)
      };
      
      // 6. 提取可选字段
      this.extractOptionalFields(frontmatter, skillInfo);
      
      return skillInfo;
      
    } catch (error) {
      throw new Error(`Failed to parse skill file ${filePath}: ${error.message}`);
    }
  }
  
  /**
   * 提取frontmatter
   * @param {string} content - 文件内容
   * @returns {object} frontmatter对象
   */
  extractFrontmatter(content) {
    // 匹配 --- 包围的frontmatter
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
    
    if (!frontmatterMatch) {
      // 尝试匹配旧格式或简化的frontmatter
      const simplifiedMatch = content.match(/^---\s*\n([\s\S]*?)\n---\s*\n/);
      if (simplifiedMatch) {
        return this.parseSimplifiedFrontmatter(simplifiedMatch[1]);
      }
      
      // 如果没有frontmatter，尝试从内容推断
      return this.inferFromContent(content);
    }
    
    try {
      return yaml.load(frontmatterMatch[1]);
    } catch (yamlError) {
      // 如果YAML解析失败，尝试简化解析
      return this.parseSimplifiedFrontmatter(frontmatterMatch[1]);
    }
  }
  
  /**
   * 解析简化的frontmatter（兼容旧格式）
   * @param {string} frontmatterText - frontmatter文本
   * @returns {object} 解析后的frontmatter
   */
  parseSimplifiedFrontmatter(frontmatterText) {
    const lines = frontmatterText.split('\n').filter(line => line.trim());
    const result = {};
    
    for (const line of lines) {
      const match = line.match(/^(\w+):\s*(.+)$/);
      if (match) {
        const [, key, value] = match;
        result[key] = value.trim();
      }
    }
    
    return result;
  }
  
  /**
   * 从内容推断技能信息（向后兼容）
   * @param {string} content - 文件内容
   * @returns {object} 推断的技能信息
   */
  inferFromContent(content) {
    const lines = content.split('\n');
    const result = {
      name: 'unknown',
      description: 'No description available'
    };
    
    // 尝试从第一行标题提取名称
    for (const line of lines) {
      if (line.startsWith('# ')) {
        result.name = line.substring(2).trim().toLowerCase().replace(/\s+/g, '-');
        result.description = line.substring(2).trim();
        break;
      }
    }
    
    return result;
  }
  
  /**
   * 解析metadata字符串
   * @param {string} metadataStr - metadata字符串
   * @returns {object} 解析后的metadata对象
   */
  parseMetadata(metadataStr) {
    if (!metadataStr) {
      return {};
    }
    
    try {
      // 尝试直接解析JSON
      return JSON.parse(metadataStr);
    } catch (error1) {
      try {
        // 尝试修复常见的JSON格式问题
        const fixedStr = metadataStr
          .replace(/(\w+):/g, '"$1":')  // 键加引号
          .replace(/'/g, '"');          // 单引号转双引号
        
        return JSON.parse(fixedStr);
      } catch (error2) {
        try {
          // 尝试解析为YAML
          return yaml.parse(metadataStr);
        } catch (error3) {
          console.warn(`Failed to parse metadata: ${metadataStr}`);
          return {};
        }
      }
    }
  }
  
  /**
   * 提取技能内容（移除frontmatter）
   * @param {string} content - 文件内容
   * @returns {string} 技能内容
   */
  extractSkillContent(content) {
    // 移除frontmatter部分
    const withoutFrontmatter = content.replace(/^---\n[\s\S]*?\n---\n/, '');
    return withoutFrontmatter.trim();
  }
  
  /**
   * 提取可选字段
   * @param {object} frontmatter - frontmatter对象
   * @param {object} skillInfo - 技能信息对象
   */
  extractOptionalFields(frontmatter, skillInfo) {
    const optionalFields = [
      'homepage',
      'user-invocable',
      'disable-model-invocation',
      'command-dispatch',
      'command-tool',
      'command-arg-mode'
    ];
    
    for (const field of optionalFields) {
      if (frontmatter[field] !== undefined) {
        skillInfo[field] = frontmatter[field];
      }
    }
    
    // 处理布尔值字段
    const booleanFields = ['user-invocable', 'disable-model-invocation'];
    for (const field of booleanFields) {
      if (skillInfo[field] !== undefined) {
        skillInfo[field] = this.parseBoolean(skillInfo[field]);
      }
    }
  }
  
  /**
   * 解析布尔值
   * @param {any} value - 要解析的值
   * @returns {boolean} 解析后的布尔值
   */
  parseBoolean(value) {
    if (typeof value === 'boolean') {
      return value;
    }
    
    if (typeof value === 'string') {
      const lowerValue = value.toLowerCase();
      return lowerValue === 'true' || lowerValue === 'yes' || lowerValue === '1';
    }
    
    return Boolean(value);
  }
  
  /**
   * 验证技能信息
   * @param {object} skillInfo - 技能信息
   * @returns {object} 验证结果
   */
  validateSkillInfo(skillInfo) {
    const errors = [];
    const warnings = [];
    
    // 必需字段检查
    if (!skillInfo.name) {
      errors.push('Missing required field: name');
    }
    
    if (!skillInfo.description) {
      warnings.push('Missing description field');
    }
    
    // 名称格式检查
    if (skillInfo.name && !/^[a-z0-9-]+$/.test(skillInfo.name)) {
      warnings.push(`Skill name "${skillInfo.name}" contains invalid characters. Use lowercase letters, numbers, and hyphens only.`);
    }
    
    // metadata格式检查
    if (skillInfo.metadata && typeof skillInfo.metadata !== 'object') {
      errors.push('metadata must be an object');
    }
    
    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }
  
  /**
   * 批量解析技能目录
   * @param {string} directory - 技能目录
   * @returns {Array} 解析后的技能列表
   */
  parseSkillDirectory(directory) {
    const skills = [];
    
    if (!fs.existsSync(directory)) {
      console.warn(`Skill directory does not exist: ${directory}`);
      return skills;
    }
    
    try {
      const items = fs.readdirSync(directory);
      
      for (const item of items) {
        const itemPath = path.join(directory, item);
        const stat = fs.statSync(itemPath);
        
        if (stat.isDirectory()) {
          // 检查目录中是否有SKILL.md文件
          const skillMdPath = path.join(itemPath, 'SKILL.md');
          if (fs.existsSync(skillMdPath)) {
            try {
              const skillInfo = this.parseSkillFile(skillMdPath);
              const validation = this.validateSkillInfo(skillInfo);
              
              if (validation.isValid) {
                skills.push({
                  ...skillInfo,
                  validation
                });
                console.log(`✅ Parsed skill: ${skillInfo.name}`);
              } else {
                console.warn(`❌ Invalid skill ${item}: ${validation.errors.join(', ')}`);
              }
              
              if (validation.warnings.length > 0) {
                console.warn(`⚠️  Warnings for ${skillInfo.name}: ${validation.warnings.join(', ')}`);
              }
              
            } catch (error) {
              console.error(`Failed to parse skill ${item}:`, error.message);
            }
          }
        }
      }
      
    } catch (error) {
      console.error(`Failed to read skill directory ${directory}:`, error.message);
    }
    
    return skills;
  }
}

module.exports = SkillParser;