return { -- You can easily change to a different colorscheme.
  -- Change the name of the colorscheme plugin below, and then
  -- change the command in the config to whatever the name of that colorscheme is.
  --
  -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
  -- 'folke/tokyonight.nvim',
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1001, -- Make sure to load this before all the other start plugins.
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('catppuccin').setup {
      flavour = 'macchiato',
      custom_highlights = function(colors)
        return {
          LineNr = {
            fg = '#8C92AB',
          },
          CursorLineNr = { fg = '#FFFFFF' },
        }
      end,
      -- styles = {
      --   comments = { italic = false }, -- Disable italics in comments
      -- },
    }
    vim.schedule(function()
      vim.cmd.colorscheme 'catppuccin-macchiato'
    end)

    -- Load the colorscheme here.
    -- Like many other themes, this one has different styles, and you could load
    -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
  end,
}
