-- Clipboard configuration for remote/local compatibility

-- For SSH/ET sessions, use OSC52 for copying to local clipboard
if (vim.env.SSH_CLIENT or vim.env.SSH_CONNECTION or vim.env.ET_VERSION) and vim.fn.has('nvim-0.10') == 1 then
  -- Use OSC52 for copy operations only
  -- Paste will use the default clipboard behavior (Cmd-V in terminal)
  vim.g.clipboard = {
    name = 'OSC52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      -- Return false to use Neovim's built-in paste behavior
      ['+'] = function() return false end,
      ['*'] = function() return false end,
    },
  }
end

-- Always use system clipboard
vim.opt.clipboard = "unnamedplus"