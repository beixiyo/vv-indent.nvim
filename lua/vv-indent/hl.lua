-- 高亮组注册：委托给 vv-utils.hl.register（ColorScheme 切换后自动重挂）
-- 非作用域：VVIndent（单色）
-- 作用域：VVIndentScope1..N（与 config.colors.scope 一一对应）

local hl_util = require('vv-utils.hl')

local M = {}

M.INDENT = 'VVIndent'
M.SCOPE_PREFIX = 'VVIndentScope'

---@param config VVIndentConfig
function M.setup(config)
  local specs = {
    [M.INDENT] = { fg = config.colors.indent, nocombine = true },
  }
  for i, color in ipairs(config.colors.scope) do
    specs[M.SCOPE_PREFIX .. i] = { fg = color, nocombine = true }
  end
  hl_util.register('vv-indent.hl', specs)
end

--- 按深度循环取作用域高亮名
---@param level integer  1-based
---@param count integer  颜色列表长度
---@return string
function M.scope_hl(level, count)
  local idx = ((level - 1) % count) + 1
  return M.SCOPE_PREFIX .. idx
end

return M
