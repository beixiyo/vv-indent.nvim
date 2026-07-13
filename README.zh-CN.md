<div align="center">
  <h1>vv-indent.nvim</h1>
  <p><a href="./README.md">English</a> | 中文</p>
  <img src="./docs/assets/vv-indent.png" alt="vv-indent 演示" width="900" />
  <p>想要我的 Neovim 配置？查看 <a href="https://github.com/beixiyo/dotfiles">dotfiles</a></p>
  <em>轻量级缩进参考线 — 当前作用域彩虹色、光标移动实时更新</em>
  <p>
  <img src="https://img.shields.io/badge/Neovim-0.10+-57A143?style=flat-square&logo=neovim&logoColor=white" alt="Requires Neovim 0.10+" />
  <img src="https://img.shields.io/badge/Lua-2C2D72?style=flat-square&logo=lua&logoColor=white" alt="Lua" />
  </p>
</div>

---

## 为什么要这个插件

`indent-blankline.nvim` 基于 treesitter 检测作用域 — 整个函数/块是一个 scope，光标在函数体内上下移动时颜色不变

vv-indent 基于**缩进级别**检测作用域，光标一移动颜色就跟着换，体验更接近 VSCode。无外部依赖，基于 `nvim_set_decoration_provider` 按需渲染，内存占用恒定

## 安装

```lua
{
  'beixiyo/vv-indent.nvim',
  dependencies = { 'beixiyo/vv-utils.nvim' },
  event = { 'BufReadPost', 'BufNewFile' },
  ---@type VVIndentConfig
  opts = {
    enabled = true,
    style = {
      scope  = 'solid',    -- 当前作用域竖线：'dashed' | 'solid'（→ │ / ┆）
      indent = 'dashed',   -- 非作用域缩进线：'dashed' | 'solid'
    },
    char = {
      scope  = nil,        -- 自定义字符，设置后优先于 style.scope
      indent = nil,        -- 自定义字符，设置后优先于 style.indent
    },
    priority = 1,          -- 非作用域 extmark 优先级
    scope_priority = 200,  -- 作用域 extmark 优先级
    exclude_ft = {
      'help', 'dashboard', 'neo-tree', 'Trouble', 'lazy', 'mason',
      'notify', 'toggleterm', 'lazyterm', 'gitcommit', 'man',
    },
    exclude_bt = { 'nofile', 'terminal', 'prompt', 'quickfix' },
    animate = {
      enabled = true,      -- 是否启用 scope 展开动画
      step_ms = 20,        -- 每步间隔（ms）
      total_ms = 500,      -- 最大动画时长（ms）
      style = 'out',       -- 展开方向：'out' | 'down' | 'up'
      easing = 'linear',   -- 缓动函数：linear / outQuad / outCubic / inQuad / inOutQuad
    },
    colors = {
      indent = '#3B4048',  -- 非作用域缩进线颜色
      scope = {            -- 作用域按深度循环的彩虹色
        '#E06C75', '#E5C07B', '#61AFEF', '#D19A66',
        '#98C379', '#C678DD', '#56B6C2',
      },
    },
  },
}
```

## 配置

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enabled` | `boolean` | `true` | 全局开关 |
| `style.scope` | `'dashed' \| 'solid'` | `'solid'` | 作用域竖线样式（`solid` → `│`，`dashed` → `┆`） |
| `style.indent` | `'dashed' \| 'solid'` | `'dashed'` | 非作用域缩进线样式 |
| `char.scope` | `string?` | `nil` | 自定义字符，设置后优先于 `style.scope` |
| `char.indent` | `string?` | `nil` | 自定义字符，设置后优先于 `style.indent` |
| `priority` | `integer` | `1` | 非作用域 extmark 优先级 |
| `scope_priority` | `integer` | `200` | 作用域 extmark 优先级 |
| `exclude_ft` | `string[]` | `{ 'help', 'dashboard', ... }` | 排除的 filetype |
| `exclude_bt` | `string[]` | `{ 'nofile', 'terminal', ... }` | 排除的 buftype |
| `animate.enabled` | `boolean` | `true` | 是否启用 scope 展开动画 |
| `animate.step_ms` | `number` | `20` | 每步间隔（ms） |
| `animate.total_ms` | `number` | `500` | 最大动画时长（ms） |
| `animate.style` | `'out' \| 'down' \| 'up'` | `'out'` | 展开方向（out=从光标向两端） |
| `animate.easing` | `string` | `'linear'` | 缓动函数（linear / outQuad / outCubic / inQuad / inOutQuad） |
| `colors.indent` | `string` | `'#3B4048'` | 非作用域缩进线颜色 |
| `colors.scope` | `string[]` | *7 色彩虹* | 作用域按深度循环的颜色列表 |
