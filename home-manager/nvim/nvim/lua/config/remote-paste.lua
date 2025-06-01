-- Smart paste for SSH/ET sessions - use terminal paste
-- Check for SSH_CLIENT or SSH_CONNECTION as they're more reliably set than SSH_TTY
if vim.env.SSH_CLIENT or vim.env.SSH_CONNECTION then
  -- Override p in normal mode to use the + register (system clipboard)
  vim.keymap.set('n', 'p', '"+p', { desc = 'Paste after cursor from system clipboard' })
  vim.keymap.set('n', 'P', '"+P', { desc = 'Paste before cursor from system clipboard' })
  
  -- Override p in visual mode
  vim.keymap.set('v', 'p', '"+p', { desc = 'Replace selection with system clipboard' })
  
  -- Also provide explicit clipboard paste commands
  vim.keymap.set({'n', 'v'}, '<leader>p', '"+p', { desc = 'Paste from system clipboard' })
  vim.keymap.set({'n', 'v'}, '<leader>P', '"+P', { desc = 'Paste before from system clipboard' })
end