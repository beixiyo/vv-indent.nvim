-- ================================
-- vv-indent.nvim - 缩进参考线 + 光标作用域彩虹高亮
-- ================================
-- 基于缩进层级的作用域检测（而非 treesitter），光标上下移动时
-- 当前作用域的竖线颜色按深度循环，其余竖线用灰色。

---@class VVIndentColors
---@field indent string            非作用域缩进线颜色
---@field scope string[]           作用域按深度循环使用的颜色列表

---@class VVIndentStyle
---@field scope 'dashed'|'solid'   当前作用域竖线风格
---@field indent 'dashed'|'solid'  非作用域缩进线风格

---@class VVIndentChar
---@field scope string|nil         作用域竖线自定义字符，优先级高于 style.scope
---@field indent string|nil        非作用域缩进线自定义字符，优先级高于 style.indent

---@class VVIndentConfig
---@field enabled boolean
---@field style VVIndentStyle
---@field char VVIndentChar
---@field priority integer         普通缩进线的 extmark 优先级
---@field scope_priority integer   作用域线的 extmark 优先级（需高于普通）
---@field exclude_ft string[]      按 filetype 关闭
---@field exclude_bt string[]      按 buftype 关闭
---@field colors VVIndentColors

local M = {}

local STYLE_CHARS = { dashed = '┆', solid = '│' }

---@type VVIndentConfig
local default_config = {
  enabled = true,
  style = {
    scope = 'solid',
    indent = 'dashed',
  },
  char = {
    scope = nil,
    indent = nil,
  },
  priority = 1,
  scope_priority = 200,
  exclude_ft = {
    'help', 'dashboard', 'neo-tree', 'Trouble', 'lazy', 'mason',
    'notify', 'toggleterm', 'lazyterm', 'gitcommit', 'man',
  },
  exclude_bt = { 'nofile', 'terminal', 'prompt', 'quickfix' },
  colors = {
    indent = '#3B4048',
    scope = {
      '#E06C75', -- red
      '#E5C07B', -- yellow
      '#61AFEF', -- blue
      '#D19A66', -- orange
      '#98C379', -- green
      '#C678DD', -- violet
      '#56B6C2', -- cyan
    },
  },
}

---@type VVIndentConfig
local config

---@param opts VVIndentConfig|nil
function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend('force', default_config, opts)
  local user_char = opts.char or {}
  if user_char.scope == nil then
    config.char.scope = STYLE_CHARS[config.style.scope] or STYLE_CHARS.solid
  end
  if user_char.indent == nil then
    config.char.indent = STYLE_CHARS[config.style.indent] or STYLE_CHARS.dashed
  end
  require('vv-indent.hl').setup(config)
  require('vv-indent.render').setup(config)
  if config.enabled then
    require('vv-indent.render').enable()
  end
end

function M.enable()
  require('vv-indent.render').enable()
end

function M.disable()
  require('vv-indent.render').disable()
end

---@return VVIndentConfig
function M.get_config()
  return vim.deepcopy(config)
end

return M
