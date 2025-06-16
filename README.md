# Presenter.nvim

A smart Neovim plugin for presentations and code demonstrations. Automatically highlights changes between the last two saves and allows manual selection of important code sections.

## ✨ Features

- **Automatic change detection**: Smart diff algorithm compares the last two file saves and highlights only actual changes
- **Manual selections**: Add specific code sections to highlight using visual selection
- **Intelligent highlighting**: Code in focus keeps normal syntax colors, everything else is dimmed
- **Auto-update**: Focus updates automatically when you save or add selections
- **Theme adaptive**: Colors automatically adapt to your current theme

## 🚀 Installation

### LazyVim

```lua
-- ~/.config/nvim/lua/plugins/presenter.lua
return {
  "Olprog59/presenter.nvim",
  cmd = { "Presenter", "PresenterAdd", "PresenterReset", "PresenterStatus" },
  keys = {
    { "<leader>pp", desc = "Presenter: Toggle focus" },
    { "<leader>pa", mode = "v", desc = "Presenter: Add selection" },
    { "<leader>pr", desc = "Presenter: Reset selections" },
  },
  opts = {
    keymaps = {
      toggle = "<leader>pp",
      add = "<leader>pa", 
      reset = "<leader>pr"
    },
    dim_highlight = { fg = "#6c7086", italic = true }
  }
}
```

### AstroNvim

Place plugin files in your AstroNvim user configuration:

```
~/.config/nvim/lua/user/
├── plugins/presenter.lua
└── presenter/init.lua
```

### Other Plugin Managers

```lua
return {
  "Olprog59/presenter.nvim",
  config = function()
    require("presenter").setup({
      keymaps = { toggle = "<C-p>", add = "<C-a>" },
      dim_highlight = { fg = "#888888" }
    })
  end
}
```

### Manual Installation

```bash
git clone https://github.com/Olprog59/presenter.nvim ~/.config/nvim/pack/plugins/start/presenter.nvim
```

## 🎯 Usage

### Basic Workflow

1. Code and save (`:w`) - First save recorded
2. Continue coding and save again (`:w`) - Second save recorded  
3. Press `<leader>pp` → Highlights all changes between saves
4. Press `<leader>pp` again → Turn off focus

### Manual Selections

1. Visual select code (`V` or `v`)
2. Press `<leader>pa` → Add selection to focus
3. Press `<leader>pp` → See changes + selections combined

### Example

```bash
:w                    # First save
# Add functions...
:w                    # Second save
<leader>pp           # Show new functions

V                    # Select important lines
<leader>pa          # Add to presentation
<leader>pp          # Show changes + selections
```

## ⌨️ Default Keymaps

| Key | Mode | Action |
|-----|------|--------|
| `<leader>pp` | Normal | Toggle focus |
| `<leader>pa` | Visual | Add selection |
| `<leader>pr` | Normal | Reset selections |

## 🛠️ Commands

| Command | Description |
|---------|-------------|
| `:Presenter` | Toggle focus mode |
| `:PresenterAdd` | Add visual selection |
| `:PresenterReset` | Clear all selections |
| `:PresenterStatus` | Show plugin status |

## ⚙️ Configuration

```lua
require("presenter").setup({
  dim_highlight = { 
    fg = "#666666",
    italic = true
  },
  highlight = {},  -- Keep empty for normal colors
  keymaps = {
    toggle = "<leader>pp",
    add = "<leader>pa",
    reset = "<leader>pr"  -- Set to false to disable
  }
})
```

### Plugin Manager Differences

**LazyVim**: Uses `opts` (auto-calls setup)
```lua
return { "Olprog59/presenter.nvim", opts = {...} }
```

**Others**: Uses `config` function
```lua
return { "Olprog59/presenter.nvim", config = function() require("presenter").setup({...}) end }
```

## 🎨 How It Works

**Smart Diff**: Only highlights actual changes, not all lines after insertions
**Visual Focus**: Code in focus keeps normal colors, everything else dims to gray
**Auto-Update**: Focus refreshes automatically on save or selection changes

## 📱 Perfect For

- Live coding presentations
- Code reviews and demos  
- Teaching and documentation
- Focusing on specific code sections

## 🤝 Contributing

Feel free to open issues or submit pull requests!

## 📄 License

MIT License