# vv-indent.nvim

轻量级缩进参考线插件，**当前作用域**按深度循环使用彩虹色，其余缩进线用统一灰色 —— VSCode 风格。

## 为什么自己造轮子

- `indent-blankline.nvim` 基于 treesitter 检测作用域，整个函数/块是一个 scope，光标在函数体内上下移动时颜色不变
- 想要基于缩进级别的作用域检测，光标一移动颜色就跟着换，体验更接近 VSCode —— 没有足够轻量的现成方案

vv-indent 只做这一件事，无外部依赖，基于 `vim.api.nvim_set_decoration_provider` 实现按需渲染。

## 特性

- 缩进参考线（每层一条竖线）
- 基于**缩进级别**的作用域检测，光标移动时作用域实时更新
- 作用域按深度循环彩虹色（7 色可配）
- 空白行自动用邻近行的缩进推断
- decoration provider 按需渲染（ephemeral extmark），内存占用恒定
- 横向滚动（`leftcol`）/ 闭合 fold 正确处理
- 高亮注册走 `vv-utils.hl`，ColorScheme 切换后自动重挂
- 仅依赖同仓库内的 `vv-utils`

## 安装

lazy.nvim：

```lua
{
  'beixiyo/vv-indent.nvim',
  dependencies = { 'beixiyo/vv-utils.nvim' },
  event = { 'BufReadPost', 'BufNewFile' },
  opts = {},
}
```

## 默认配置

```lua
require("vv-indent").setup({
  enabled = true,
  style = {
    scope  = "solid",   -- 当前作用域竖线：'dashed' | 'solid'
    indent = "dashed",  -- 非作用域缩进线：'dashed' | 'solid'
  },
  char = {
    scope  = nil,       -- 自定义字符，设置后优先级高于 style.scope
    indent = nil,
  },
  priority = 1,
  scope_priority = 200,
  exclude_ft = {
    "help", "dashboard", "neo-tree", "Trouble", "lazy", "mason",
    "notify", "toggleterm", "lazyterm", "gitcommit", "man",
  },
  exclude_bt = { "nofile", "terminal", "prompt", "quickfix" },
  colors = {
    indent = "#3B4048",
    scope = {
      "#E06C75", -- red
      "#E5C07B", -- yellow
      "#61AFEF", -- blue
      "#D19A66", -- orange
      "#98C379", -- green
      "#C678DD", -- violet
      "#56B6C2", -- cyan
    },
  },
})
```

## API

```lua
require("vv-indent").enable()   -- 启用
require("vv-indent").disable()  -- 禁用
require("vv-indent").get_config()
```

按 buffer 关闭：`vim.b.vv_indent_disabled = true`。

## 高亮组

| 组 | 默认 | 说明 |
|---|---|---|
| `VVIndent` | `#3B4048` | 非作用域缩进线 |
| `VVIndentScope1..N` | 对应 `colors.scope[i]` | 作用域按深度循环 |

所有组均以 `default = true` 定义，主题可覆盖。`default = true` 由 `vv-utils.hl.register()` 在注册时统一设置，而非本插件直接指定。

## 实现要点

- 作用域 = 光标行的**有效缩进**为下限，向上下扩展的最大连续非空白行范围
- 空白行使用 `max(prevnonblank, nextnonblank)` 的缩进推断
- 作用域竖线位于 `scope.indent - shiftwidth` 列（比 body 浅一级）
- 深度 `level = indent / shiftwidth`，颜色按 `((level - 1) % #colors) + 1` 循环

## Testing

Smoke test (zero deps, runs in `-u NONE`):

```bash
nvim --headless -u NONE -l tests/test_smoke.lua
```

Expected: trailing line `X passed, 0 failed`.
