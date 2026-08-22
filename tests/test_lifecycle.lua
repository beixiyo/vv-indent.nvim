-- 生命周期回归：重复 setup 只应拥有一个渲染器并完全释放

local failures = {}

local function check(condition, message)
  if not condition then
    failures[#failures + 1] = message
  end
end

local test_file = debug.getinfo(1, 'S').source:sub(2)
local plugin_root = vim.fn.fnamemodify(test_file, ':p:h:h')
local vendors = vim.fn.fnamemodify(plugin_root, ':h')
vim.opt.runtimepath:append(plugin_root)
vim.opt.runtimepath:append(vendors .. '/vv-utils.nvim')

local animate_adds = 0
local animate_deletes = {}
package.loaded['vv-utils.animate'] = {
  add = function()
    animate_adds = animate_adds + 1
  end,
  del = function(id)
    animate_deletes[id] = (animate_deletes[id] or 0) + 1
  end,
}

---@type any
local mock_api = vim.api
local original_provider = mock_api.nvim_set_decoration_provider
local latest_provider = {}
mock_api.nvim_set_decoration_provider = function(namespace, provider)
  latest_provider = provider
  return original_provider(namespace, provider)
end

local indent = require('vv-indent')
vim.bo.shiftwidth = 2
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  'root',
  '  first',
  '  second',
  '  third',
  'root',
})

indent.setup({ enabled = true })
check(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 3,
  '启用渲染器时应恰好拥有三个 autocmd')
check(type(latest_provider.on_win) == 'function' and type(latest_provider.on_line) == 'function',
  '启用渲染器时应安装 decoration provider')

vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.api.nvim_exec_autocmds('CursorMoved', { modeline = false })
check(animate_adds == 1, '光标范围变更应启动一次动画')

indent.setup({ enabled = false })
check(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 0,
  'setup enabled=false 时应移除渲染器的 autocmd')
check(next(latest_provider) == nil, 'setup enabled=false 时应清空 decoration provider')
check((animate_deletes['vv_indent_' .. vim.api.nvim_get_current_win()] or 0) > 0,
  'setup enabled=false 时应停止当前窗口的动画')

indent.setup({
  enabled = true,
  char = { scope = '!' },
  animate = { enabled = false },
})
check(indent.get_config().char.scope == '!', '重新启用后应使用新配置')
check(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 3,
  '重新启用后渲染器仍应恰好拥有三个 autocmd')

indent.setup({
  enabled = true,
  style = { scope = 'dashed' },
  animate = { enabled = false },
})
check(indent.get_config().char.scope == '┆', '后续 setup 不应保留旧的自定义字符')
check(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 3,
  '重复启用的 setup 不应重复创建 autocmd')

indent.disable()
mock_api.nvim_set_decoration_provider = original_provider

if #failures > 0 then
  error('vv-indent 生命周期校验失败：\n- ' .. table.concat(failures, '\n- '))
end

print('vv-indent 生命周期测试通过')
