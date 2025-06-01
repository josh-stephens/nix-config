-- Clipboard configuration for remote/local compatibility

-- Always use system clipboard
vim.opt.clipboard = "unnamedplus"

-- Enable OSC52 support for SSH/ET sessions
-- Both regular SSH and Eternal Terminal support OSC52
if vim.env.SSH_TTY and vim.fn.has('nvim-0.10') == 1 then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
end