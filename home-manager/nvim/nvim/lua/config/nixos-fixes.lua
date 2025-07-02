-- Workaround for Neovim issue #34730 on NixOS
-- This fixes the ENOENT error when plugins try to run external commands
-- See: https://github.com/neovim/neovim/issues/34730

-- Apply the fix immediately before any plugins load
local orig_system = vim.system

vim.system = function(cmd, opts)
  opts = opts or {}
  
  -- The bug: when clear_env=true and env=nil, Neovim incorrectly
  -- clears the environment, breaking command execution on NixOS
  if opts.clear_env == true and opts.env == nil then
    -- Fix: don't clear the environment when env is nil
    opts.clear_env = false
  end
  
  return orig_system(cmd, opts)
end

-- Also patch the older vim.fn.system if needed
local orig_fn_system = vim.fn.system
vim.fn.system = function(cmd, input)
  -- Ensure PATH is available for the command
  local env = vim.fn.environ()
  if env.PATH then
    cmd = 'PATH=' .. env.PATH .. ' ' .. cmd
  end
  return orig_fn_system(cmd, input)
end