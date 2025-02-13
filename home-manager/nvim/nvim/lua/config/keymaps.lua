-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

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
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = "Quit all" })
