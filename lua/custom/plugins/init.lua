-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- require 'custom.plugins.whichkey'

require('custom.wordy').setup()

-- MIght be nedded. Supposedly to turn off floating LSP diag
vim.api.nvim_create_autocmd('WinEnter', {
  callback = function()
    -- local floating = vim.api.nvim_win_get_config(0).relative ~= ''
    vim.diagnostic.config {
      virtual_text = false,
      -- virtual_lines = not floating,
    }
  end,
})

-- Resize splits automatically
vim.api.nvim_create_autocmd('VimResized', {
  pattern = '*',
  callback = function()
    vim.cmd 'tabdo wincmd ='
  end,
})

-- Set formatting for lua, because tabs really suck
vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function()
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'kotlin',
  group = vim.api.nvim_create_augroup('CustomKotlinFormat', { clear = true }),
  callback = function()
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'rust',
  group = vim.api.nvim_create_augroup('CustomRustFormat', { clear = true }),
  callback = function()
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})

return {
  -- Telescope filebrowser extension
  {
    'nvim-telescope/telescope-file-browser.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
  },

  -- Bufferline extension
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
      options = {
        show_buffer_icons = true,
        show_buffer_close_icons = false,
      },
    },
  },
  -- LSP-lines to try to tame them.
  {
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    config = function()
      require('lsp_lines').setup()
      -- Disable standard virtual_text to avoid duplication
      vim.diagnostic.config {
        virtual_text = false,
        virtual_lines = { only_current_line = true }, -- only show for current line
      }
    end,
  },
}
