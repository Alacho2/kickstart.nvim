vim.api.nvim_create_user_command('Bc', function()
  vim.cmd 'e #'
  -- vim.cmd.bprevious()
  vim.cmd 'bd #'
end, { nargs = 0, desc = 'Go to previous buffer, delete the other' })
