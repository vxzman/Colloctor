-- WezTerm 配置文件
-- 由 aquawius 提供
-- 这是版本 4 的配置

-- 版本历史：
-- 版本 1: 初始配置
-- 版本 2: 添加对 WSL 的支持
-- 版本 3: 更新主题为紫色风格
-- 版本 4: 修复 "git log" 命令显示 "terminal is not fully functional" 的问题
--         以及 tracert 命令的问题

local wezterm = require("wezterm")  -- 加载 WezTerm 库

local config = {  

    -- 检查是否有 WezTerm 的更新
    check_for_updates = true,  
    -- 当前使用的颜色方案
    color_scheme = "lovelace",  
    -- 可选的颜色方案
    -- color_scheme = "Fahrenheit",  
    -- color_scheme = "Gruvbox Dark",
    -- color_scheme = "Blue Matrix",
    -- color_scheme = "Pandora",
    -- color_scheme = "Grape",
    -- color_scheme = "Firewatch",
    -- color_scheme = "Duotone Dark",
    -- color_scheme = "Sakura",
    -- color_scheme = "Batman",
    -- 设置非活动窗格的颜色
    inactive_pane_hsb = {  
        hue = 1.0,
        saturation = 1.0,
        brightness = 1.0,
    },  -- 注意这里的逗号和闭合括号
    -- 设置字体及其备选字体
    font = wezterm.font_with_fallback({  
        "Roboto Mono",
        "JetBrains Mono",
        "Cascadia Code",
        "Fira Code",
    }),  -- 注意这里的逗号和闭合括号
    -- 设置字体大小
    font_size = 12.0,  
    -- 设置默认启动的程序，这里是 PowerShell 7
    default_prog = { 'pwsh' },  -- 注意这里的逗号
    -- 可以设置默认的工作目录
    -- default_cwd = "$HOME",  
    -- 启动菜单的配置
    launch_menu = {},  -- 注意这里的逗号
    -- 设置 leader 键
    leader = { key = "b", mods = "CTRL" },  -- 注意这里的逗号
    -- 设置环境变量
    set_environment_variables = {},  -- 注意这里的逗号
    -- 使用花哨的标签栏
    use_fancy_tab_bar = true,  -- 注意这里的逗号
    -- 如果只有一个标签，则隐藏标签栏
    hide_tab_bar_if_only_one_tab = false,  -- 注意这里的逗号
    -- 显示新建标签按钮在标签栏上
    show_new_tab_button_in_tab_bar = true,  -- 注意这里的逗号
    -- 将标签栏放置在底部
    -- tab_bar_at_bottom = true,  
    -- 启用标签栏
    enable_tab_bar = true,  -- 注意这里的逗号
    -- 启用滚动条
    enable_scroll_bar = true,  -- 注意这里的逗号
    -- 关闭行为，默认为 "Close"
    exit_behavior = "Close",  -- 注意这里的逗号
    -- 设置窗口背景透明度
    window_background_opacity = 0.94,  -- 注意这里的逗号
    -- 设置文本背景透明度
    text_background_opacity = 0.9,  -- 注意这里的逗号
    -- 更改字体大小时调整窗口大小
    adjust_window_size_when_changing_font_size = true,
    
    colors = {
        tab_bar = {
            -- 标签栏背景颜色
            background = "#282828",
            -- 活动标签的样式
            active_tab = {
                -- 活动标签背景颜色
                bg_color = "#18131e",
                -- 活动标签前景颜色
				fg_color = "#ff00ff",
                -- 强度设置，这里为正常强度
                intensity = "Normal",
                -- 下划线样式，这里为无下划线
                underline = "None",
                -- 是否为斜体
                italic = true,
                -- 是否有删除线
                strikethrough = false,
            },
            -- 非活动标签的样式
            inactive_tab = {
                -- 非活动标签背景颜色
                bg_color = "#282828",
                -- 非活动标签前景颜色
                fg_color = "#d19afc",
            },
            -- 非活动标签悬停时的样式
            inactive_tab_hover = {
                -- 非活动标签悬停时背景颜色
                bg_color = "#202020",
                -- 非活动标签悬停时前景颜色
                fg_color = "#ff65fd",
            },
            -- 新建标签的样式
            new_tab = {
                -- 新建标签背景颜色
                bg_color = "#282828",
                -- 新建标签前景颜色
                fg_color = "#d19afc",
            },
            -- 新建标签悬停时的样式
            new_tab_hover = {
                -- 新建标签悬停时背景颜色
                bg_color = "#18131e",
                -- 新建标签悬停时前景颜色
                fg_color = "#ff65fd",
            },
        },
    },
}

-- 如果是 Windows 系统
-- 添加特定于 Windows 的配置
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    -- 设置终端类型（可选）
    -- config.term = ""  -- 设置为空字符串以便 FZF 在 Windows 上正常工作
    -- config.term = "xterm"  -- 修复 "git log" 命令显示 "terminal is not fully functional" 的问题
    -- 或者删除 term = "xxxx" （使用默认值）

    -- 向启动菜单中添加多个 shell 选项
    table.insert(config.launch_menu, {
        label = "PowerShell 7",
        args = { "pwsh.exe", "-NoExit", "-Command", "$Host.UI.RawUI.WindowTitle = 'pwsh'" }
    })
    table.insert(config.launch_menu, {
        label = "PowerShell 5",
        args = { "powershell.exe" }
    })
    table.insert(config.launch_menu, {
        label = "Command Prompt",
        args = { "cmd.exe" }
    })
    table.insert(config.launch_menu, {
        label = "Bash",
        args = { "C:\\Program Files\\Git\\bin\\bash.exe" ,"--login","-i"}
    })
    table.insert(config.launch_menu, {
        label = "Cmder",
        args = { "cmd.exe", "/k", "title Cmder & C:\\Userbin\\cmder\\vendor\\init.bat" }
    })

    -- 添加 Visual Studio 开发者命令提示符选项
    table.insert(config.launch_menu, {
        label = "Visual Studio Dev Shell",
        args = {
            "powershell.exe",
            "-NoExit",  "-Command", 
            "& {Import-Module 'C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\Common7\\Tools\\Microsoft.VisualStudio.DevShell.dll'; Enter-VsDevShell 4d37fb70 -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'}"
        }
    })
end
   
    
config.keys = { 
    { key = "n", mods = "ALT", action = wezterm.action { SpawnTab = "DefaultDomain" } },
    ---使用 ALT+w关闭标签页
    { key = "w", mods = "ALT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
    -- 使用 Alt+左箭头切换到前一个标签页
    { key = "LeftArrow", mods = "ALT", action = wezterm.action { ActivateTabRelative = -1 } },
    -- 使用 Alt+右箭头切换到后一个标签页
    { key = "RightArrow", mods = "ALT", action = wezterm.action { ActivateTabRelative = 1 } },
	--打开一个新的标签页键入命令
	{ key = 'o', mods = 'ALT', action = wezterm.action.SpawnCommandInNewTab{ args = { 'ssh', 'openbsd-gw' } } },
	
	
	--窗格操作
    -- 使用 Alt+h 垂直分割当前窗格
    { key = "e", mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },  
    -- 使用 Alt+z 水平分割当前窗格
    { key = "h", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    -- 使用 Alt+q关闭窗格
    { key = "q", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
    -- 将焦点移动到左边的窗格
    { key = "LeftArrow", mods = "SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
    -- 将焦点移动到右边的窗格
    { key = "RightArrow", mods = "SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
    -- 将焦点移动到上面的窗格
    { key = "UpArrow", mods = "SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
    -- 将焦点移动到下面的窗格
    { key = "DownArrow", mods = "SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },

	--ssh配置
	--链接在配置文件中定义的ssh
	{ key = 'U', mods = 'CTRL|SHIFT', action = wezterm.action.AttachDomain 'openbsd' },

}

-- 定义 Alt+数字 切换到对应标签页的快捷键
for i = 1, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = 'ALT',
        action = wezterm.action.ActivateTab(i - 1),
    })
end

config.mouse_bindings = {  -- 定义鼠标绑定行为
    -- 当鼠标右键按下时，执行粘贴操作（从剪贴板粘贴）
    { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = wezterm.action { PasteFrom = 'Clipboard' } },
    -- 当鼠标左键弹起时，完成文本选择并设置为主要选择
    { event = { Up = { streak = 1, button = 'Left' } }, mods = 'NONE', action = wezterm.action { CompleteSelection = 'PrimarySelection' } },
    -- 当按下 Ctrl 键同时鼠标左键弹起时，打开鼠标光标处的链接
    { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = 'OpenLinkAtMouseCursor' }
}


return config  -- 返回配置表