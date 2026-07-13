<div align="center">
  <h1>vv-indent.nvim</h1>
  <p>English | <a href="./README.zh-CN.md">中文</a></p>
  <img src="./docs/assets/vv-indent.png" alt="vv-indent demo" width="900" />
  <p>Want my Neovim config? See <a href="https://github.com/beixiyo/dotfiles">dotfiles</a></p>
  <em>Lightweight indent guides with rainbow-colored active scopes that update as the cursor moves</em>
  <p>
    <img src="https://img.shields.io/badge/Neovim-0.10+-57A143?style=flat-square&logo=neovim&logoColor=white" alt="Requires Neovim 0.10+" />
    <img src="https://img.shields.io/badge/Lua-2C2D72?style=flat-square&logo=lua&logoColor=white" alt="Lua" />
  </p>
</div>

---

## Why this plugin?

`indent-blankline.nvim` detects scopes with treesitter, treating an entire function or block as one scope. Its color therefore remains unchanged while the cursor moves through the function body.

vv-indent detects scopes by **indentation level**, so the active color follows every cursor movement for an experience closer to VS Code. It has no external dependencies and renders on demand with `nvim_set_decoration_provider`, keeping memory usage constant.

## Installation

```lua
{
  'beixiyo/vv-indent.nvim',
  dependencies = { 'beixiyo/vv-utils.nvim' },
  event = { 'BufReadPost', 'BufNewFile' },
  ---@type VVIndentConfig
  opts = {
    enabled = true,
    style = {
      scope  = 'solid',    -- Active scope: 'dashed' | 'solid' (→ ┆ / │)
      indent = 'dashed',   -- Inactive indent guides
    },
    char = {
      scope  = nil,        -- Overrides style.scope when set
      indent = nil,        -- Overrides style.indent when set
    },
    priority = 1,          -- Inactive extmark priority
    scope_priority = 200,  -- Active-scope extmark priority
    exclude_ft = {
      'help', 'dashboard', 'neo-tree', 'Trouble', 'lazy', 'mason',
      'notify', 'toggleterm', 'lazyterm', 'gitcommit', 'man',
    },
    exclude_bt = { 'nofile', 'terminal', 'prompt', 'quickfix' },
    animate = {
      enabled = true,      -- Animate scope expansion
      step_ms = 20,        -- Delay between steps in milliseconds
      total_ms = 500,      -- Maximum animation duration
      style = 'out',       -- Direction: 'out' | 'down' | 'up'
      easing = 'linear',   -- linear / outQuad / outCubic / inQuad / inOutQuad
    },
    colors = {
      indent = '#3B4048',
      scope = {
        '#E06C75', '#E5C07B', '#61AFEF', '#D19A66',
        '#98C379', '#C678DD', '#56B6C2',
      },
    },
  },
}
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `boolean` | `true` | Global enable switch |
| `style.scope` | `'dashed' \| 'solid'` | `'solid'` | Active-scope line style: `solid` → `│`, `dashed` → `┆` |
| `style.indent` | `'dashed' \| 'solid'` | `'dashed'` | Inactive indent-guide style |
| `char.scope` | `string?` | `nil` | Custom active-scope character, taking precedence over `style.scope` |
| `char.indent` | `string?` | `nil` | Custom inactive-guide character, taking precedence over `style.indent` |
| `priority` | `integer` | `1` | Inactive-guide extmark priority |
| `scope_priority` | `integer` | `200` | Active-scope extmark priority |
| `exclude_ft` | `string[]` | `{ 'help', 'dashboard', ... }` | Excluded filetypes |
| `exclude_bt` | `string[]` | `{ 'nofile', 'terminal', ... }` | Excluded buffer types |
| `animate.enabled` | `boolean` | `true` | Enables scope expansion animation |
| `animate.step_ms` | `number` | `20` | Delay between animation steps in milliseconds |
| `animate.total_ms` | `number` | `500` | Maximum animation duration in milliseconds |
| `animate.style` | `'out' \| 'down' \| 'up'` | `'out'` | Expansion direction; `out` expands from the cursor toward both ends |
| `animate.easing` | `string` | `'linear'` | `linear`, `outQuad`, `outCubic`, `inQuad`, or `inOutQuad` |
| `colors.indent` | `string` | `'#3B4048'` | Inactive-guide color |
| `colors.scope` | `string[]` | *seven-color rainbow* | Colors cycled by active-scope depth |
