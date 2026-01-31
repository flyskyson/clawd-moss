# 🛠️ 技能加载器升级设计文档
**设计时间**: 2026-01-31 23:15  
**目标**: 兼容OpenClaw SKILL.md标准格式
**状态**: 设计阶段

---

## 🎯 **设计目标**

### **核心需求**
```
✅ 完全兼容OpenClaw SKILL.md格式
✅ 支持frontmatter和metadata解析
✅ 实现门控检查 (requires.bins/env/config)
✅ 支持配置覆盖 (skills.entries)
✅ 保持向后兼容性
```

### **设计原则**
```
🎯 兼容性优先: 确保现有技能继续工作
🔧 模块化设计: 易于维护和扩展
⚡ 性能优化: 快速加载和检查
🔄 可配置: 支持灵活配置选项
```

---

## 🏗️ **架构设计**

### **系统架构**
```
┌─────────────────────────┐
│      Skill Manager      │
├─────────────────────────┤
│  - 技能发现和扫描       │
│  - 优先级管理          │
│  - 冲突解决            │
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│     Skill Loader        │
├─────────────────────────┤
│  - SKILL.md解析         │
│  - 门控检查执行         │
│  - 配置覆盖应用         │
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│   Requirement Checker   │
├─────────────────────────┤
│  - 二进制依赖检查       │
│  - 环境变量检查         │
│  - 配置项检查           │
└─────────────────────────┘
```

### **数据流**
```
1. 扫描技能目录 → 发现SKILL.md文件
2. 解析frontmatter → 提取name/description/metadata
3. 执行门控检查 → 验证requires条件
4. 应用配置覆盖 → 应用skills.entries配置
5. 构建技能列表 → 返回可用技能信息
```

---

## 🔧 **详细设计**

### **1. SKILL.md解析器**

#### **输入格式**
```markdown
---
name: skill-name
description: "技能描述"
metadata: {"openclaw": {"requires": {"bins": ["python3"]}}}
---

# 技能名称

技能详细内容...
```

#### **解析逻辑**
```javascript
class SkillParser {
  parseSkillFile(filePath) {
    // 1. 读取文件内容
    const content = fs.readFileSync(filePath, 'utf8');
    
    // 2. 提取frontmatter
    const frontmatter = this.extractFrontmatter(content);
    
    // 3. 解析metadata
    const metadata = this.parseMetadata(frontmatter.metadata);
    
    // 4. 提取技能内容
    const skillContent = this.extractSkillContent(content);
    
    return {
      name: frontmatter.name,
      description: frontmatter.description,
      metadata: metadata,
      content: skillContent,
      filePath: filePath
    };
  }
  
  extractFrontmatter(content) {
    // 匹配 --- 包围的frontmatter
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
    if (!frontmatterMatch) {
      throw new Error('Invalid SKILL.md format: missing frontmatter');
    }
    
    // 解析YAML格式的frontmatter
    return yaml.load(frontmatterMatch[1]);
  }
  
  parseMetadata(metadataStr) {
    try {
      return JSON.parse(metadataStr);
    } catch (error) {
      // 尝试处理单行JSON
      return JSON.parse(metadataStr.replace(/(\w+):/g, '"$1":'));
    }
  }
}
```

### **2. 门控检查器**

#### **检查类型**
```javascript
class RequirementChecker {
  constructor(config) {
    this.config = config;
  }
  
  checkRequirements(skillMetadata) {
    const requirements = skillMetadata?.openclaw?.requires;
    if (!requirements) {
      return { passed: true, missing: [] };
    }
    
    const results = {
      passed: true,
      missing: []
    };
    
    // 检查二进制依赖
    if (requirements.bins) {
      const missingBins = this.checkBins(requirements.bins);
      if (missingBins.length > 0) {
        results.passed = false;
        results.missing.push(`bins: ${missingBins.join(', ')}`);
      }
    }
    
    // 检查环境变量
    if (requirements.env) {
      const missingEnv = this.checkEnv(requirements.env);
      if (missingEnv.length > 0) {
        results.passed = false;
        results.missing.push(`env: ${missingEnv.join(', ')}`);
      }
    }
    
    // 检查配置项
    if (requirements.config) {
      const missingConfig = this.checkConfig(requirements.config);
      if (missingConfig.length > 0) {
        results.passed = false;
        results.missing.push(`config: ${missingConfig.join(', ')}`);
      }
    }
    
    return results;
  }
  
  checkBins(bins) {
    return bins.filter(bin => !this.isBinaryAvailable(bin));
  }
  
  checkEnv(envVars) {
    return envVars.filter(env => !process.env[env] && !this.config.skills?.entries?.[skillName]?.env?.[env]);
  }
  
  checkConfig(configPaths) {
    return configPaths.filter(path => !this.getConfigValue(path));
  }
  
  isBinaryAvailable(bin) {
    try {
      execSync(`which ${bin}`, { stdio: 'ignore' });
      return true;
    } catch {
      return false;
    }
  }
}
```

### **3. 配置覆盖系统**

#### **配置结构**
```javascript
// ~/.clawdbot/clawdbot.json 中的配置
{
  "skills": {
    "entries": {
      "skill-name": {
        "enabled": true,
        "apiKey": "YOUR_KEY",
        "env": {
          "API_KEY": "YOUR_KEY"
        },
        "config": {
          "endpoint": "https://api.example.com",
          "model": "default"
        }
      }
    }
  }
}
```

#### **覆盖逻辑**
```javascript
class ConfigOverrider {
  applyOverrides(skillInfo, config) {
    const skillConfig = config.skills?.entries?.[skillInfo.name];
    if (!skillConfig) {
      return skillInfo;
    }
    
    // 应用enabled配置
    if (skillConfig.enabled === false) {
      return { ...skillInfo, enabled: false };
    }
    
    // 应用环境变量覆盖
    const mergedEnv = {
      ...skillInfo.metadata?.openclaw?.requires?.env?.reduce((acc, env) => {
        acc[env] = process.env[env] || skillConfig.env?.[env];
        return acc;
      }, {}),
      ...skillConfig.env
    };
    
    // 应用配置覆盖
    const mergedConfig = {
      ...skillInfo.metadata?.openclaw,
      ...skillConfig.config
    };
    
    return {
      ...skillInfo,
      enabled: true,
      config: {
        ...skillInfo.config,
        env: mergedEnv,
        ...mergedConfig
      }
    };
  }
}
```

### **4. 技能管理器**

#### **主类设计**
```javascript
class SkillManager {
  constructor(config) {
    this.config = config;
    this.parser = new SkillParser();
    this.checker = new RequirementChecker(config);
    this.overrider = new ConfigOverrider();
    this.skills = new Map();
  }
  
  async loadSkills() {
    // 1. 扫描技能目录
    const skillDirs = this.getSkillDirectories();
    
    // 2. 加载每个技能
    for (const dir of skillDirs) {
      await this.loadSkillFromDirectory(dir);
    }
    
    // 3. 应用优先级和冲突解决
    this.resolveConflicts();
    
    return Array.from(this.skills.values());
  }
  
  getSkillDirectories() {
    const dirs = [];
    
    // 工作空间技能 (最高优先级)
    if (this.config.skills?.workspacePath) {
      dirs.push(this.config.skills.workspacePath);
    }
    
    // 本地管理技能
    dirs.push(path.join(os.homedir(), '.clawdbot', 'skills'));
    
    // 捆绑技能 (最低优先级)
    if (this.config.skills?.bundledPath) {
      dirs.push(this.config.skills.bundledPath);
    }
    
    // 额外目录
    if (this.config.skills?.load?.extraDirs) {
      dirs.push(...this.config.skills.load.extraDirs);
    }
    
    return dirs.filter(dir => fs.existsSync(dir));
  }
  
  async loadSkillFromDirectory(skillDir) {
    const skillMdPath = path.join(skillDir, 'SKILL.md');
    
    if (!fs.existsSync(skillMdPath)) {
      console.warn(`No SKILL.md found in ${skillDir}`);
      return;
    }
    
    try {
      // 解析技能文件
      const skillInfo = this.parser.parseSkillFile(skillMdPath);
      
      // 执行门控检查
      const checkResult = this.checker.checkRequirements(skillInfo.metadata);
      if (!checkResult.passed) {
        console.warn(`Skill ${skillInfo.name} failed requirements: ${checkResult.missing.join(', ')}`);
        return;
      }
      
      // 应用配置覆盖
      const finalSkillInfo = this.overrider.applyOverrides(skillInfo, this.config);
      
      // 存储技能
      this.skills.set(skillInfo.name, {
        ...finalSkillInfo,
        directory: skillDir,
        loadedAt: new Date()
      });
      
      console.log(`✅ Loaded skill: ${skillInfo.name}`);
      
    } catch (error) {
      console.error(`Failed to load skill from ${skillDir}:`, error.message);
    }
  }
  
  resolveConflicts() {
    // 基于目录优先级解决冲突
    // 后加载的技能覆盖先加载的技能
    // 实际实现需要记录加载顺序
  }
  
  getSkill(name) {
    return this.skills.get(name);
  }
  
  listSkills() {
    return Array.from(this.skills.values()).map(skill => ({
      name: skill.name,
      description: skill.description,
      enabled: skill.enabled,
      directory: skill.directory
    }));
  }
}
```

---

## 🚀 **实施计划**

### **阶段1: 基础解析器 (今晚)**
```
✅ 设计SKILL.md解析器
✅ 实现frontmatter提取
✅ 实现metadata解析
🔜 编写单元测试
```

### **阶段2: 门控检查器 (明天上午)**
```
🔜 设计RequirementChecker类
🔜 实现二进制依赖检查
🔜 实现环境变量检查
🔜 实现配置项检查
```

### **阶段3: 配置覆盖系统 (明天下午)**
```
🔜 设计ConfigOverrider类
🔜 实现enabled/env/apiKey/config覆盖
🔜 集成到SkillManager
```

### **阶段4: 技能管理器 (后天)**
```
🔜 设计SkillManager主类
🔜 实现技能目录扫描
🔜 实现冲突解决逻辑
🔜 集成所有组件
```

### **阶段5: 测试和优化 (大后天)**
```
🔜 编写全面测试套件
🔜 性能测试和优化
🔜 向后兼容性测试
🔜 文档编写
```

---

## 📊 **向后兼容性**

### **兼容现有技能**
```
🎯 目标: 现有技能无需修改继续工作
🔧 策略: 检测旧格式，自动转换
🔄 迁移: 提供迁移工具和指南
```

### **迁移路径**
```
1. 检测旧格式技能
2. 提供自动转换选项
3. 生成转换报告
4. 验证转换结果
```

### **过渡期支持**
```
📅 时间: 1个月过渡期
🔧 功能: 同时支持新旧格式
📊 监控: 跟踪格式使用情况
🎯 目标: 平滑过渡到新格式
```

---

## 🔍 **测试策略**

### **单元测试**
```
🧪 测试: SKILL.md解析器
🧪 测试: 门控检查器
🧪 测试: 配置覆盖系统
🧪 测试: 技能管理器
```

### **集成测试**
```
🔗 测试: 完整技能加载流程
🔗 测试: 配置覆盖生效
🔗 测试: 门控检查正确性
🔗 测试: 冲突解决逻辑
```

### **性能测试**
```
⚡ 测试: 技能加载速度
⚡ 测试: 内存使用情况
⚡ 测试: 并发加载能力
⚡ 测试: 大规模技能处理
```

### **兼容性测试**
```
🔄 测试: 向后兼容性
🔄 测试: 格式迁移工具
🔄 测试: 现有技能工作正常
🔄 测试: 配置升级路径
```

---

## 📚 **文档计划**

### **开发者文档**
```
📖 API文档: 技能加载器API
🔧 开发指南: 如何开发新技能
⚙️ 配置指南: 技能配置选项
🧪 测试指南: 如何测试技能
```

### **用户文档**
```
🎯 使用指南: 如何使用技能系统
🔧 管理指南: 如何管理技能
🔄 迁移指南: 从旧格式迁移
📊 故障排除: 常见问题解决
```

### **运维文档**
```
⚙️ 部署指南: 如何部署技能系统
📊 监控指南: 如何监控技能使用
🔒 安全指南: 安全最佳实践
🔄 升级指南: 系统升级步骤
```

---

## 🎯 **成功标准**

### **功能标准**
```
✅ 完全兼容OpenClaw SKILL.md格式
✅ 支持所有门控检查类型
✅ 支持完整配置覆盖
✅ 保持向后兼容性
✅ 性能满足生产要求
```

### **质量标准**
```
🎯 代码质量: 通过代码审查
🧪 测试覆盖: >90%测试覆盖率
🔧 文档完整: 完整的文档体系
🔄 易于维护: 清晰的代码结构
```

### **用户体验**
```
🚀 加载速度: <1秒加载所有技能
🔧 配置简便: 易于理解和配置
📊 监控完善: 完整的监控指标
🔄 迁移平滑: 无缝迁移体验
```

---

## 🚀 **立即开始执行！**

### **今晚任务 (23:15 ~ 00:00)**
```
1. 🔜 创建SKILL.md解析器原型
2. 🔜 编写基础测试用例
3. 🔜 设计数据结构和接口
```

### **代码位置**
```
📁 项目: /Users/lijian/clawd
📂 代码: scripts/skill-loader/
📄 入口: skill-loader.js
🧪 测试: test/skill-loader.test.js
```

### **开发环境**
```
🔧 语言: JavaScript/Node.js
📦 依赖: yaml, fs, path, child_process
🧪 测试: Jest
📝 文档: JSDoc + Markdown
```

**开始编码！** 💻

*设计文档完成时间: 2026-01-31 23:15*