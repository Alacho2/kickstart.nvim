vim.api.nvim_create_user_command('Bc', function()
  vim.cmd.bprevious()
  vim.cmd 'bd #'
end, { nargs = 0, desc = 'Go to previous buffer, delete the other' })
