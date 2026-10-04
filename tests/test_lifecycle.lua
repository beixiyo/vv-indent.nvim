-- 真实场景在独立子进程中执行；收集阶段仅注册具名用例。
local H = dofile(vim.env.VV_TEST_REPO .. '/tests/helpers.lua')
local T, child = H.new_set()

T["重配置释放旧资源并只保留当前渲染与键位所有权"] = function()
  child.lua_func(function()
    -- 生命周期回归：重复 setup 只应拥有一个渲染器并完全释放


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
    assert(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 3,
      '启用渲染器时应恰好拥有三个 autocmd')
    assert(type(latest_provider.on_win) == 'function' and type(latest_provider.on_line) == 'function',
      '启用渲染器时应安装 decoration provider')

    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.api.nvim_exec_autocmds('CursorMoved', { modeline = false })
    assert(animate_adds == 1, '光标范围变更应启动一次动画')

    indent.setup({ enabled = false })
    assert(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 0,
      'setup enabled=false 时应移除渲染器的 autocmd')
    assert(next(latest_provider) == nil, 'setup enabled=false 时应清空 decoration provider')
    assert((animate_deletes['vv_indent_' .. vim.api.nvim_get_current_win()] or 0) > 0,
      'setup enabled=false 时应停止当前窗口的动画')

    indent.setup({
      enabled = true,
      char = { scope = '!' },
      animate = { enabled = false },
    })
    assert(indent.get_config().char.scope == '!', '重新启用后应使用新配置')
    assert(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 3,
      '重新启用后渲染器仍应恰好拥有三个 autocmd')

    indent.setup({
      enabled = true,
      style = { scope = 'dashed' },
      animate = { enabled = false },
    })
    assert(indent.get_config().char.scope == '┆', '后续 setup 不应保留旧的自定义字符')
    assert(#vim.api.nvim_get_autocmds({ group = 'vv-indent.render' }) == 3,
      '重复启用的 setup 不应重复创建 autocmd')

    indent.disable()
    mock_api.nvim_set_decoration_provider = original_provider

  end)
end

return T
