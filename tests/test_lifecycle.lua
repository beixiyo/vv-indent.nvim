-- Lifecycle regression: repeated setup owns one renderer and fully releases it.

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
  'enabled renderer should own exactly three autocmds')
check(type(latest_provider.on_win) == 'function' and type(latest_provider.on_line) == 'function',
  'enabled renderer should install the decoration provider')

vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.api.nvim_exec_autocmds('CursorMoved', { modeline = false })
check(animate_adds == 1, 'cursor scope change should start one animation')

indent.setup({ enabled = false })
check(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 0,
  'setup enabled=false should remove renderer autocmds')
check(next(latest_provider) == nil, 'setup enabled=false should clear the decoration provider')
check((animate_deletes['vv_indent_' .. vim.api.nvim_get_current_win()] or 0) > 0,
  'setup enabled=false should stop the active window animation')

indent.setup({
  enabled = true,
  char = { scope = '!' },
  animate = { enabled = false },
})
check(indent.get_config().char.scope == '!', 're-enabled renderer should use the new config')
check(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 3,
  're-enabled renderer should still own exactly three autocmds')

indent.setup({
  enabled = true,
  style = { scope = 'dashed' },
  animate = { enabled = false },
})
check(indent.get_config().char.scope == '┆', 'later setup should not retain an old custom character')
check(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 3,
  'repeated enabled setup should not duplicate autocmds')

indent.disable()
mock_api.nvim_set_decoration_provider = original_provider

if #failures > 0 then
  error('vv-indent lifecycle failures:\n- ' .. table.concat(failures, '\n- '))
end

print('vv-indent lifecycle: passed')
