-- Clipboard configuration for remote/local compatibility

-- For SSH/ET sessions, use OSC52 for copying to local clipboard
if (vim.env.SSH_CLIENT or vim.env.SSH_CONNECTION) and vim.fn.has('nvim-0.10') == 1 then
  vim.g.clipboard = {
    name = 'OSC52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      -- Paste is handled by remote-paste.lua with terminal integration
      ['+'] = function() return {vim.fn.getreg('"'), vim.fn.getregtype('"')} end,
      ['*'] = function() return {vim.fn.getreg('"'), vim.fn.getregtype('"')} end,
    },
  }
end

-- Always use system clipboard
vim.opt.clipboard = "unnamedplus"