/**
 * 技能管理器
 * 主类，集成所有组件
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const SkillParser = require('./skill-parser');
const RequirementChecker = require('./requirement-checker');
const ConfigOverrider = require('./config-overrider');

class SkillManager {
  /**
   * 构造函数
   * @param {object} config - Clawdbot配置
   * @param {object} options - 选项
   */
  constructor(config = {}, options = {}) {
    this.config = config;
    this.options = {
      verbose: false,
      cache: true,
      watch: false,
      ...options
    };
    
    // 初始化组件
    this.parser = new SkillParser();
    this.checker = new RequirementChecker(config);
    this.overrider = new ConfigOverrider(config);
    
    // 技能存储
    this.skills = new Map(); // name -> skillInfo
    this.skillDirs = new Map(); // directory -> skills[]
    
    // 缓存
    this.cache = {
      loadedAt: null,
      scanDuration: 0
    };
    
    // 状态
    this.isLoading = false;
    this.lastError = null;
    
    this.log('SkillManager initialized');
  }
  
  /**
   * 加载所有技能
   * @returns {Promise<Array>} 加载的技能列表
   */
  async loadSkills() {
    if (this.isLoading) {
      throw new Error('Skill loading already in progress');
    }
    
    this.isLoading = true;
    this.lastError = null;
    const startTime = Date.now();
    
    try {
      this.log('Starting skill loading...');
      
      // 1. 清空现有技能
      this.skills.clear();
      this.skillDirs.clear();
      
      // 2. 获取技能目录
      const skillDirectories = this.getSkillDirectories();
      this.log(`Found ${skillDirectories.length} skill directories`);
      
      // 3. 按优先级加载技能
      const loadedSkills = [];
      
      for (const dir of skillDirectories) {
        const skillsFromDir = await this.loadSkillsFromDirectory(dir);
        loadedSkills.push(...skillsFromDir);
      }
      
      // 4. 解决冲突（基于优先级）
      this.resolveConflicts(loadedSkills);
      
      // 5. 更新缓存
      this.cache.loadedAt = new Date();
      this.cache.scanDuration = Date.now() - startTime;
      this.cache.totalSkills = this.skills.size;
      
      this.log(`Skill loading completed in ${this.cache.scanDuration}ms`);
      this.log(`Loaded ${this.skills.size} skills`);
      
      return Array.from(this.skills.values());
      
    } catch (error) {
      this.lastError = error;
      this.log(`Skill loading failed: ${error.message}`, 'error');
      throw error;
      
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 获取技能目录（按优先级排序）
   * @returns {Array} 技能目录列表
   */
  getSkillDirectories() {
    const dirs = [];
    
    // 1. 工作空间技能 (最高优先级)
    const workspacePath = this.config.skills?.workspacePath || './skills';
    if (fs.existsSync(workspacePath)) {
      dirs.push(path.resolve(workspacePath));
    }
    
    // 2. 本地管理技能
    const localPath = path.join(os.homedir(), '.clawdbot', 'skills');
    if (fs.existsSync(localPath)) {
      dirs.push(localPath);
    }
    
    // 3. 捆绑技能 (最低优先级)
    const bundledPath = this.config.skills?.bundledPath;
    if (bundledPath && fs.existsSync(bundledPath)) {
      dirs.push(path.resolve(bundledPath));
    }
    
    // 4. 额外目录
    const extraDirs = this.config.skills?.load?.extraDirs || [];
    for (const extraDir of extraDirs) {
      const resolvedDir = path.resolve(extraDir.replace('~', os.homedir()));
      if (fs.existsSync(resolvedDir)) {
        dirs.push(resolvedDir);
      }
    }
    
    // 去重并记录优先级
    const uniqueDirs = [...new Set(dirs)];
    this.log(`Skill directories (priority order): ${uniqueDirs.join(', ')}`);
    
    return uniqueDirs;
  }
  
  /**
   * 从目录加载技能
   * @param {string} directory - 目录路径
   * @returns {Promise<Array>} 加载的技能列表
   */
  async loadSkillsFromDirectory(directory) {
    const skills = [];
    
    if (!fs.existsSync(directory)) {
      this.log(`Directory does not exist: ${directory}`, 'warn');
      return skills;
    }
    
    try {
      const items = fs.readdirSync(directory);
      this.log(`Scanning directory: ${directory} (${items.length} items)`);
      
      for (const item of items) {
        const itemPath = path.join(directory, item);
        const stat = fs.statSync(itemPath);
        
        if (stat.isDirectory()) {
          const skill = await this.loadSkillFromPath(itemPath);
          if (skill) {
            skills.push(skill);
          }
        }
      }
      
      // 记录目录到技能的映射
      if (skills.length > 0) {
        this.skillDirs.set(directory, skills.map(s => s.name));
      }
      
    } catch (error) {
      this.log(`Failed to scan directory ${directory}: ${error.message}`, 'error');
    }
    
    return skills;
  }
  
  /**
   * 从路径加载单个技能
   * @param {string} skillPath - 技能路径
   * @returns {Promise<object|null>} 技能信息或null
   */
  async loadSkillFromPath(skillPath) {
    const skillMdPath = path.join(skillPath, 'SKILL.md');
    
    if (!fs.existsSync(skillMdPath)) {
      // 检查是否有其他技能文件（向后兼容）
      const oldSkillFile = this.findOldSkillFile(skillPath);
      if (!oldSkillFile) {
        return null;
      }
      // 这里可以添加旧格式转换逻辑
      return null;
    }
    
    try {
      // 1. 解析技能文件
      const skillInfo = this.parser.parseSkillFile(skillMdPath);
      
      // 2. 验证技能信息
      const validation = this.parser.validateSkillInfo(skillInfo);
      if (!validation.isValid) {
        this.log(`Invalid skill ${skillInfo.name}: ${validation.errors.join(', ')}`, 'warn');
        return null;
      }
      
      // 3. 检查需求
      const requirementCheck = this.checker.checkRequirements(skillInfo, skillInfo.name);
      if (!requirementCheck.passed) {
        this.log(`Skill ${skillInfo.name} failed requirements: ${requirementCheck.missing.join(', ')}`, 'warn');
        
        // 如果设置了always: true，仍然加载
        if (!skillInfo.metadata?.openclaw?.always) {
          return null;
        }
        this.log(`Skill ${skillInfo.name} has always: true, loading despite failed requirements`, 'warn');
      }
      
      // 4. 检查是否允许（针对捆绑技能）
      if (!this.overrider.isSkillAllowed(skillInfo)) {
        this.log(`Skill ${skillInfo.name} not in allowBundled list, skipping`, 'warn');
        return null;
      }
      
      // 5. 应用配置覆盖
      const finalSkillInfo = this.overrider.applyOverrides(skillInfo);
      
      if (!finalSkillInfo.enabled) {
        this.log(`Skill ${skillInfo.name} is disabled by config`, 'info');
        return null;
      }
      
      // 6. 丰富技能信息
      const enrichedSkill = this.enrichSkillInfo(finalSkillInfo, {
        requirementCheck,
        validation,
        directory: skillPath,
        loadedAt: new Date()
      });
      
      this.log(`✅ Loaded skill: ${enrichedSkill.name}`, 'success');
      
      if (validation.warnings.length > 0) {
        this.log(`⚠️  Warnings for ${enrichedSkill.name}: ${validation.warnings.join(', ')}`, 'warn');
      }
      
      return enrichedSkill;
      
    } catch (error) {
      this.log(`Failed to load skill from ${skillPath}: ${error.message}`, 'error');
      return null;
    }
  }
  
  /**
   * 查找旧格式技能文件（向后兼容）
   * @param {string} skillPath - 技能路径
   * @returns {string|null} 旧技能文件路径
   */
  findOldSkillFile(skillPath) {
    const oldFormats = [
      'skill.json',
      'skill.yaml',
      'skill.yml',
      'skill.js',
      'skill.md'
    ];
    
    for (const format of oldFormats) {
      const filePath = path.join(skillPath, format);
      if (fs.existsSync(filePath)) {
        return filePath;
      }
    }
    
    return null;
  }
  
  /**
   * 丰富技能信息
   * @param {object} skillInfo - 基础技能信息
   * @param {object} metadata - 额外元数据
   * @returns {object} 丰富的技能信息
   */
  enrichSkillInfo(skillInfo, metadata) {
    return {
      // 基础信息
      ...skillInfo,
      
      // 加载元数据
      ...metadata,
      
      // 计算字段
      id: `${skillInfo.name}-${Date.now()}`,
      isActive: true,
      canInvoke: skillInfo['user-invocable'] !== false,
      
      // 统计信息
      stats: {
        loadCount: 1,
        lastUsed: null,
        usageCount: 0
      }
    };
  }
  
  /**
   * 解决技能冲突（基于目录优先级）
   * @param {Array} loadedSkills - 加载的技能列表
   */
  resolveConflicts(loadedSkills) {
    // 按目录优先级排序（后加载的优先级高）
    const skillsByPriority = [...loadedSkills].reverse();
    
    for (const skill of skillsByPriority) {
      const existingSkill = this.skills.get(skill.name);
      
      if (existingSkill) {
        // 冲突解决：后加载的技能覆盖先加载的
        this.log(`Conflict resolved: ${skill.name} from ${skill.directory} overrides from ${existingSkill.directory}`, 'info');
      }
      
      this.skills.set(skill.name, skill);
    }
  }
  
  /**
   * 获取技能
   * @param {string} name - 技能名称
   * @returns {object|null} 技能信息
   */
  getSkill(name) {
    return this.skills.get(name) || null;
  }
  
  /**
   * 获取所有技能
   * @returns {Array} 技能列表
   */
  getAllSkills() {
    return Array.from(this.skills.values());
  }
  
  /**
   * 获取启用的技能
   * @returns {Array} 启用的技能列表
   */
  getEnabledSkills() {
    return this.getAllSkills().filter(skill => skill.enabled);
  }
  
  /**
   * 按类别获取技能
   * @param {string} category - 类别
   * @returns {Array} 技能列表
   */
  getSkillsByCategory(category) {
    // 这里可以根据metadata中的分类信息过滤
    return this.getAllSkills().filter(skill => 
      skill.metadata?.category === category || 
      skill.metadata?.openclaw?.category === category
    );
  }
  
  /**
   * 搜索技能
   * @param {string} query - 搜索查询
   * @returns {Array} 匹配的技能列表
   */
  searchSkills(query) {
    const lowerQuery = query.toLowerCase();
    
    return this.getAllSkills().filter(skill => {
      return (
        skill.name.toLowerCase().includes(lowerQuery) ||
        skill.description.toLowerCase().includes(lowerQuery) ||
        (skill.metadata?.tags && skill.metadata.tags.some(tag => 
          tag.toLowerCase().includes(lowerQuery)
        ))
      );
    });
  }
  
  /**
   * 获取技能统计
   * @returns {object} 统计信息
   */
  getStats() {
    const allSkills = this.getAllSkills();
    const enabledSkills = this.getEnabledSkills();
    
    return {
      total: allSkills.length,
      enabled: enabledSkills.length,
      disabled: allSkills.length - enabledSkills.length,
      bySource: this.getSkillsBySource(),
      byStatus: this.getSkillsByStatus(),
      cache: this.cache
    };
  }
  
  /**
   * 按来源获取技能统计
   * @returns {object} 来源统计
   */
  getSkillsBySource() {
    const sources = {};
    
    for (const skill of this.getAllSkills()) {
      const source = this.getSkillSource(skill.directory);
      sources[source] = (sources[source] || 0) + 1;
    }
    
    return sources;
  }
  
  /**
   * 获取技能来源
   * @param {string} directory - 技能目录
   * @returns {string} 来源标识
   */
  getSkillSource(directory) {
    if (directory.includes('.clawdbot/skills')) {
      return 'local';
    } else if (directory.includes('/skills') && !directory.includes('.clawdbot')) {
      return 'workspace';
    } else if (directory.includes('node_modules') || directory.includes('bundled')) {
      return 'bundled';
    } else {
      return 'extra';
    }
  }
  
  /**
   * 按状态获取技能
   * @returns {object} 状态统计
   */
  getSkillsByStatus() {
    const allSkills = this.getAllSkills();
    
    return {
      ready: allSkills.filter(s => s.enabled && !s.requirementCheck?.missing?.length).length,
      requirementsMissing: allSkills.filter(s => s.enabled && s.requirementCheck?.missing?.length).length,
      disabled: allSkills.filter(s => !s.enabled).length,
      configOverridden: allSkills.filter(s => s.configApplied).length
    };
  }
  
  /**
   * 生成报告
   * @returns {string} 格式化报告
   */
  generateReport() {
    const stats = this.getStats();
    const lines = [];
    
    lines.push('📊 Skill Manager Report');
    lines.push('='.repeat(50));
    lines.push(`Total skills: ${stats.total}`);
    lines.push(`Enabled: ${stats.enabled} | Disabled: ${stats.disabled}`);
    lines.push(`Loaded at: ${this.cache.loadedAt?.toLocaleString() || 'Never'}`);
    lines.push(`Scan duration: ${this.cache.scanDuration}ms`);
    
    lines.push('\n📁 By source:');
    for (const [source, count] of Object.entries(stats.bySource)) {
      lines.push(`  ${source}: ${count}`);
    }
    
    lines.push('\n🎯 By status:');
    lines.push(`  Ready: ${stats.byStatus.ready}`);
    lines.push(`  Requirements missing: ${stats.byStatus.requirementsMissing}`);
    lines.push(`  Disabled: ${stats.byStatus.disabled}`);
    lines.push(`  Config overridden: ${stats.byStatus.configOverridden}`);
    
    lines.push('\n🔧 Components:');
    lines.push(`  Parser: ${this.parser.constructor.name}`);
    lines.push(`  Checker cache: ${JSON.stringify(this.checker.getCacheStats())}`);
    
    if (this.lastError) {
      lines.push(`\n❌ Last error: ${this.lastError.message}`);
    }
    
    lines.push('\n' + '='.repeat(50));
    
    return lines.join('\n');
  }
  
  /**
   * 日志记录
   * @param {string} message - 日志消息
   * @param {string} level - 日志级别
   */
  log(message, level = 'info') {
    if (!this.options.verbose && level === 'info') {
      return;
    }
    
    const timestamp = new Date().toISOString();
    const prefix = {
      info: 'ℹ️',
      warn: '⚠️',
      error: '❌',
      success: '✅',
      debug: '🔍'
    }[level] || 'ℹ️';
    
    console.log(`[${timestamp}] ${prefix} ${message}`);
  }
  
  /**
   * 清理资源
   */
  cleanup() {
    this.skills.clear();
    this.skillDirs.clear();
    this.checker.clearCache();
    this.cache = {
      loadedAt: null,
      scanDuration: 0
    };
    
    this.log('SkillManager cleaned up');
  }
}

module.exports = SkillManager;