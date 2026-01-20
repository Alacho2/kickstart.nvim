vim.keymap.set('n', 'gp', ':bprevious<CR>', { desc = 'GoTo [P]revious Buffer' })
vim.keymap.set('n', 'gn', ':bnext<CR>', { desc = 'GoTo [N]ext Buffer' })
vim.keymap.set('n', 'ga', ':e #<CR>', { desc = 'GoTo Last [A]ccessed Buffer' })

-- Yank to system clipboard
vim.keymap.set('n', '<leader>Y', '"+y', { desc = 'Yank to system clipboard' })
vim.keymap.set('v', '<leader>Y', '"+y', { desc = 'Yank to system clipboard' })

vim.keymap.set('n', 't', 'vt', { desc = 'Change the behavior for t selection' })

-- Move line down
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { silent = true })
-- Move line up
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { silent = true })

-- move block down
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv==gv", { silent = true })
-- move block up
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv==gv", { silent = true })

-- Go to the right
-- vim.keymap.set('n', 'gl', 'g$', { noremap = true, silent = true })
-- vim.keymap.set('v', 'gl', 'g$', { noremap = true, silent = true })

-- Go to the left
-- vim.keymap.set('n', 'gh', 'g0', { noremap = true, silent = true })
-- vim.keymap.set('v', 'gh', 'g0', { noremap = true, silent = true })

-- A fancy doc version which allows us to split downwards to the right.
vim.keymap.set('n', 'grD', ":belowright split | lua require('telescope.builtin').lsp_definitions()<CR>", { desc = '[G]oto [D]efinition below window' })

-- selection of current line, upwards and downwards
vim.keymap.set('n', 'x', 'V', { noremap = true })
vim.keymap.set('v', 'x', 'j', { noremap = true })
vim.keymap.set('v', '<S-x>', 'k', { noremap = true })

-- Go to end of line
vim.keymap.set('n', 'gl', 'g$')
vim.keymap.set('n', 'gh', 'g0')

-- recent picker
