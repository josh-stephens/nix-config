local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- Terminal mode mappings
map('t', '<Esc>', [[<C-\><C-n>]])

-- Window navigation
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')
map('n', '<Tab>', '<C-W>w')
map('n', '<S-Tab>', '<C-W>W')
map('n', '<BS>', ':b#<CR>')

-- Other mappings
map('n', '<leader>n', '<cmd>noh<cr>')
map('n', '<cr>', 'ciw')
map('v', 'y', 'ygv<esc>')
