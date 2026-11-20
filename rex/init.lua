-- tmux-style key bindings for Rex.
-- Press Ctrl-b, release it, then press one of the keys below.
--
-- Rex client font settings (stored in macOS preferences, not init.lua):
--   family: JetBrains Mono
--   size: 15 pt
--   character spacing: -15.0%
--   ligatures: disabled

rex.mode("tmux")

-- Prefix
rex.bind("ctrl+b", "client.mode.enter", {
  name = "tmux", once = true,
})
rex.bind("tmux/ctrl+b", "pane.send_key", {
  key = "ctrl+b",
})
rex.bind("tmux/q", "client.mode.exit")

-- Tabs (tmux windows)
-- tmux windows map to Rex tabs
rex.bind("tmux/c", "client.tab.new")
rex.bind("tmux/,", "client.tab.rename")
rex.bind("tmux/shift+4", "session.rename")
rex.bind("tmux/shift+7", "client.tab.close")
rex.bind("tmux/n", "client.tab.next")
rex.bind("tmux/p", "client.tab.previous")
rex.bind("tmux/ctrl+n", "client.tab.next")
rex.bind("tmux/ctrl+p", "client.tab.previous")
rex.bind("tmux/g", "session.switch")
rex.bind("tmux/s", "session.switch")

-- Copy mode: Ctrl-b [ enters Rex's tmux-style keyboard copy mode.
-- Rex provides q/Escape to exit, v for character selection, and Ctrl-v for
-- block selection. Match tmux's Shift-Enter binding by copying without exit.
rex.bind("tmux/[", "pane.copy_mode.enter")
rex.bind("shift+enter", "pane.copy")

rex.bind("tmux/0", "client.tab.goto", { index = 0 })
rex.bind("tmux/1", "client.tab.goto", { index = 1 })
rex.bind("tmux/2", "client.tab.goto", { index = 2 })
rex.bind("tmux/3", "client.tab.goto", { index = 3 })
rex.bind("tmux/4", "client.tab.goto", { index = 4 })
rex.bind("tmux/5", "client.tab.goto", { index = 5 })
rex.bind("tmux/6", "client.tab.goto", { index = 6 })
rex.bind("tmux/7", "client.tab.goto", { index = 7 })
rex.bind("tmux/8", "client.tab.goto", { index = 8 })
rex.bind("tmux/9", "client.tab.goto", { index = 9 })

-- Panes
rex.bind("tmux/shift+5", "pane.split.right")
rex.bind("tmux/shift+'", "pane.split.down")
rex.bind("tmux/shift+\\", "pane.split.right")
rex.bind("tmux/-", "pane.split.down")
rex.bind("tmux/o", "pane.focus_next")
rex.bind("tmux/x", "pane.close")
rex.bind("tmux/z", "pane.zoom")
rex.bind("tmux/space", "pane.balance")
rex.bind("tmux/shift+[", "pane.move.left")
rex.bind("tmux/shift+]", "pane.move.right")
rex.bind("tmux/shift+9", "pane.move.up")
rex.bind("tmux/shift+0", "pane.move.down")

-- Pane focus: arrows and Vim keys
rex.bind("tmux/left", "pane.focus.left")
rex.bind("tmux/right", "pane.focus.right")
rex.bind("tmux/up", "pane.focus.up")
rex.bind("tmux/down", "pane.focus.down")
rex.bind("tmux/h", "pane.focus.left")
rex.bind("tmux/l", "pane.focus.right")
rex.bind("tmux/k", "pane.focus.up")
rex.bind("tmux/j", "pane.focus.down")
rex.bind("tmux/ctrl+h", "pane.focus.left")
rex.bind("tmux/ctrl+l", "pane.focus.right")
rex.bind("tmux/ctrl+k", "pane.focus.up")
rex.bind("tmux/ctrl+j", "pane.focus.down")

-- Resize panes (pain-control uses uppercase H/J/K/L)
rex.bind("tmux/shift+h", "pane.resize", { direction = "left", amount = 5 })
rex.bind("tmux/shift+l", "pane.resize", { direction = "right", amount = 5 })
rex.bind("tmux/shift+k", "pane.resize", { direction = "up", amount = 5 })
rex.bind("tmux/shift+j", "pane.resize", { direction = "down", amount = 5 })

-- Resize panes
rex.bind("tmux/ctrl+left", "pane.resize", {
  direction = "left", amount = 5,
})
rex.bind("tmux/ctrl+right", "pane.resize", {
  direction = "right", amount = 5,
})
rex.bind("tmux/ctrl+up", "pane.resize", {
  direction = "up", amount = 5,
})
rex.bind("tmux/ctrl+down", "pane.resize", {
  direction = "down", amount = 5,
})
