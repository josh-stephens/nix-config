-- Smart paste for SSH/ET sessions
-- Check for SSH_CLIENT or SSH_CONNECTION as they're more reliably set than SSH_TTY
if vim.env.SSH_CLIENT or vim.env.SSH_CONNECTION then
  -- Alternative approach: Use Kitty's OSC 52 paste functionality
  -- First, let's try to sync the clipboard using OSC 52 paste query
  
  local function get_terminal_clipboard()
    -- Create a temporary buffer to capture the response
    local tmpfile = vim.fn.tempname()
    
    -- Send OSC 52 query for clipboard contents
    -- This asks the terminal to send back the clipboard contents
    io.stdout:write('\x1b]52;c;?\x07')
    io.stdout:flush()
    
    -- Give terminal time to respond
    vim.wait(50)
    
    -- For now, return nil to fall back to default behavior
    return nil
  end
  
  -- Simpler approach: Just use terminal's paste buffer through special key sequence
  vim.keymap.set('n', 'p', function()
    -- Enter insert mode and let terminal handle the paste
    vim.cmd('set paste')
    vim.cmd('normal! a')
    -- Try different paste sequences that might work with Kitty
    -- First try: Shift+Insert (common terminal paste)
    local keys = vim.api.nvim_replace_termcodes('<S-Insert>', true, false, true)
    vim.api.nvim_feedkeys(keys, 'n', false)
    vim.defer_fn(function()
      vim.cmd('set nopaste')
      vim.cmd('stopinsert')
    end, 100)
  end, { desc = 'Paste from terminal clipboard' })
  
  vim.keymap.set('n', 'P', function()
    vim.cmd('set paste')
    vim.cmd('normal! i')
    local keys = vim.api.nvim_replace_termcodes('<S-Insert>', true, false, true)
    vim.api.nvim_feedkeys(keys, 'n', false)
    vim.defer_fn(function()
      vim.cmd('set nopaste')
      vim.cmd('stopinsert')
    end, 100)
  end, { desc = 'Paste before cursor from terminal clipboard' })
  
  -- Visual mode paste
  vim.keymap.set('v', 'p', function()
    vim.cmd('normal! "_d')
    vim.cmd('set paste')
    vim.cmd('normal! i')
    local keys = vim.api.nvim_replace_termcodes('<S-Insert>', true, false, true)
    vim.api.nvim_feedkeys(keys, 'n', false)
    vim.defer_fn(function()
      vim.cmd('set nopaste')
      vim.cmd('stopinsert')
    end, 100)
  end, { desc = 'Replace selection with terminal clipboard' })
  
  -- Also provide a command to test different paste methods
  vim.api.nvim_create_user_command('TestPaste', function(opts)
    local method = opts.args
    vim.cmd('set paste')
    vim.cmd('normal! a')
    
    if method == 'shift-insert' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<S-Insert>', true, false, true), 'n', false)
    elseif method == 'ctrl-shift-v' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-S-v>', true, false, true), 'n', false)
    elseif method == 'middle-click' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<MiddleMouse>', true, false, true), 'n', false)
    else
      print("Unknown method. Try: shift-insert, ctrl-shift-v, or middle-click")
    end
    
    vim.defer_fn(function()
      vim.cmd('set nopaste')
      vim.cmd('stopinsert')
    end, 100)
  end, { nargs = 1 })
end