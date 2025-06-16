-- Example LazyVim plugin configuration
-- File: ~/.config/nvim/lua/plugins/presenter.lua

return {
  "Olprog59/presenter.nvim",

  -- Lazy loading options
  cmd = { "Presenter", "PresenterAdd", "PresenterReset", "PresenterStatus" },
  keys = {
    { "<leader>pp", desc = "Presenter: Toggle focus" },
    { "<leader>pa", mode = "v", desc = "Presenter: Add selection" },
    { "<leader>pr", desc = "Presenter: Reset selections" },
  },

  -- Configuration options (LazyVim will call setup(opts))
  opts = {
    -- Optional: customize keymaps
    keymaps = {
      toggle = "<leader>pp", -- Toggle focus
      add = "<leader>pa", -- Add visual selection
      reset = "<leader>pr", -- Reset selections
    },

    -- Optional: customize colors
    dim_highlight = {
      fg = "#6c7086", -- Gray color for non-focused lines
      italic = true, -- Optional styling
    },

    -- Optional: add background to focused lines (not recommended)
    -- highlight = { bg = "#2a2a2a" },
  },

  -- Alternative: custom config function
  -- config = function()
  --   require("presenter").setup({
  --     keymaps = {
  --       toggle = "<C-p>",  -- Custom keymap
  --       add = "<C-a>",
  --       reset = false      -- Disable this keymap
  --     }
  --   })
  -- end,
}
