-- 基于缩进的作用域检测
-- 光标所在块 = 以光标行的有效缩进为下限，向上下扩展的最大连续非空白行范围。

---@class VVIndentScope
---@field from integer    起始行（1-based，inclusive）
---@field to integer      结束行（1-based，inclusive）
---@field indent integer  作用域缩进（列数）
---@field level integer   作用域深度（indent / shiftwidth，1-based）

local M = {}

---@param bufnr integer
---@return integer
local function get_shiftwidth(bufnr)
  local sw = vim.bo[bufnr].shiftwidth
  if sw == 0 then sw = vim.bo[bufnr].tabstop end
  if sw == 0 then sw = 2 end
  return sw
end

--- 有效缩进：空白行用邻近非空行的最大缩进推断
---@param bufnr integer
---@param row integer  1-based
---@return integer
function M.effective_indent(bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
  if not line then return 0 end
  
  -- 必须在目标 buffer 上下文中调用 vim.fn.indent 等函数，
  -- 否则在未 focus 的窗口中绘制时，会读取 active buffer 的缩进导致算错
  return vim.api.nvim_buf_call(bufnr, function()
    if not line:match('^%s*$') then
      return vim.fn.indent(row)
    end
    local prev = vim.fn.prevnonblank(row)
    local next_row = vim.fn.nextnonblank(row)
    local prev_i = prev > 0 and vim.fn.indent(prev) or 0
    local next_i = next_row > 0 and vim.fn.indent(next_row) or 0
    return math.max(prev_i, next_i)
  end)
end

---@param bufnr integer
---@param cursor_row integer  1-based
---@return VVIndentScope|nil
function M.find(bufnr, cursor_row)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if cursor_row < 1 or cursor_row > line_count then return nil end

  local indent = M.effective_indent(bufnr, cursor_row)
  if indent <= 0 then return nil end

  local sw = get_shiftwidth(bufnr)

  local from = cursor_row
  local to = cursor_row

  vim.api.nvim_buf_call(bufnr, function()
    -- 向上扩展：遇到缩进 < indent 的非空行则停止
    local cur = cursor_row
    while cur > 1 do
      local prev = vim.fn.prevnonblank(cur - 1)
      if prev == 0 then break end
      if vim.fn.indent(prev) < indent then break end
      from = prev
      cur = prev
    end

    -- 向下扩展
    cur = cursor_row
    while cur < line_count do
      local next_row = vim.fn.nextnonblank(cur + 1)
      if next_row == 0 or next_row == cur then break end
      if vim.fn.indent(next_row) < indent then break end
      to = next_row
      cur = next_row
    end
  end)

  return {
    from = from,
    to = to,
    indent = indent,
    level = math.floor(indent / sw),
  }
end

---@param bufnr integer
---@return integer
M.get_shiftwidth = get_shiftwidth

return M
