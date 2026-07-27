---@class VVIndent.Colors
---@field indent string  非作用域缩进线颜色 @default '#3B4048'
---@field scope string[]  作用域按深度循环使用的颜色列表 @default { '#E06C75', '#E5C07B', '#61AFEF', '#D19A66', '#98C379', '#C678DD', '#56B6C2' }
---@class VVIndent.Style
---@field scope 'dashed'|'solid'  当前作用域竖线风格 @default 'solid'
---@field indent 'dashed'|'solid'  非作用域缩进线风格 @default 'dashed'
---@class VVIndent.Char
---@field scope? string  作用域竖线自定义字符，优先级高于 style.scope @default nil
---@field indent? string  非作用域缩进线自定义字符，优先级高于 style.indent @default nil
---@class VVIndent.Animate
---@field enabled boolean  是否启用 scope 展开动画 @default true
---@field step_ms number  每步间隔（ms） @default 20
---@field total_ms number  最大动画时长（ms） @default 500
---@field style 'out'|'down'|'up'  展开方向：out=从光标向两端，down=从顶向下，up=从底向上 @default 'out'
---@field easing string  缓动函数名 @default 'linear'
---@class VVIndent.Config
---@field enabled boolean @default true
---@field style VVIndent.Style
---@field char VVIndent.Char
---@field priority integer  普通缩进线的 extmark 优先级 @default 1
---@field scope_priority integer  作用域线的 extmark 优先级（需高于普通） @default 200
---@field exclude_ft string[]  按 filetype 关闭 @default { 'help', 'dashboard', 'neo-tree', 'Trouble', 'lazy', 'mason', ... }
---@field exclude_bt string[]  按 buftype 关闭 @default { 'nofile', 'terminal', 'prompt', 'quickfix' }
---@field colors VVIndent.Colors
---@field animate VVIndent.Animate

---@class VVIndent.ConfigOptions
---@field enabled? boolean  是否启用 @default true
---@field style? VVIndent.StyleOptions  竖线样式
---@field char? VVIndent.CharOptions  自定义竖线字符
---@field priority? integer  普通缩进线 extmark 优先级 @default 1
---@field scope_priority? integer  作用域线 extmark 优先级 @default 200
---@field exclude_ft? string[]  按 filetype 关闭
---@field exclude_bt? string[]  按 buftype 关闭
---@field colors? VVIndent.ColorsOptions  缩进线颜色
---@field animate? VVIndent.AnimateOptions  作用域动画

---@class VVIndent.ColorsOptions
---@field indent? string  非作用域缩进线颜色
---@field scope? string[]  作用域按深度循环使用的颜色列表

---@class VVIndent.StyleOptions
---@field scope? 'dashed'|'solid'  当前作用域竖线风格
---@field indent? 'dashed'|'solid'  非作用域缩进线风格

---@class VVIndent.CharOptions
---@field scope? string  作用域竖线自定义字符
---@field indent? string  非作用域竖线自定义字符

---@class VVIndent.AnimateOptions
---@field enabled? boolean  是否启用 scope 展开动画
---@field step_ms? number  每步间隔（ms）
---@field total_ms? number  最大动画时长（ms）
---@field style? 'out'|'down'|'up'  展开方向
---@field easing? string  缓动函数名
return {}
