-- Smart paste for SSH/ET sessions
-- Check for SSH_CLIENT or SSH_CONNECTION as they're more reliably set than SSH_TTY
if vim.env.SSH_CLIENT or vim.env.SSH_CONNECTION then
  -- Use Kitty remote control to access clipboard
  local function kitty_paste()
    -- Check if we have Kitty remote forwarding (set by SSH config)
    if vim.env.KITTY_REMOTE then
      -- Use the forwarded socket explicitly
      local socket_path = "/tmp/kitty-joshsymonds"
      -- Get clipboard content via Kitty remote control using the forwarded socket
      local result = vim.fn.system('kitty @ --to unix:' .. socket_path .. ' get-clipboard 2>/dev/null')
      if vim.v.shell_error == 0 and result ~= "" then
        return result
      end
    end
    
    -- Fallback: try to get from system clipboard register
    return vim.fn.getreg('+')
  end
  
  vim.keymap.set('n', 'p', function()
    local clipboard = kitty_paste()
    if clipboard and clipboard ~= "" then
      -- Use put command to paste at correct position
      local lines = vim.split(clipboard, '\n', { plain = true })
      vim.api.nvim_put(lines, 'c', true, true)
    else
      -- Fallback to default paste
      vim.cmd('normal! p')
    end
  end, { desc = 'Paste from terminal clipboard' })
  
  vim.keymap.set('n', 'P', function()
    local clipboard = kitty_paste()
    if clipboard and clipboard ~= "" then
      -- Use put command to paste before cursor
      local lines = vim.split(clipboard, '\n', { plain = true })
      vim.api.nvim_put(lines, 'c', false, true)
    else
      -- Fallback to default paste
      vim.cmd('normal! P')
    end
  end, { desc = 'Paste before cursor from terminal clipboard' })
  
  -- Visual mode paste
  vim.keymap.set('v', 'p', function()
    -- Delete selection without yanking
    vim.cmd('normal! "_d')
    
    local clipboard = kitty_paste()
    if clipboard and clipboard ~= "" then
      local lines = vim.split(clipboard, '\n', { plain = true })
      vim.api.nvim_put(lines, 'c', false, true)
    else
      vim.cmd('normal! p')
    end
  end, { desc = 'Replace selection with terminal clipboard' })
  
  -- Debug command to check clipboard access
  vim.api.nvim_create_user_command('CheckClipboard', function()
    print("KITTY_REMOTE: " .. (vim.env.KITTY_REMOTE or "not set"))
    print("SSH_CLIENT: " .. (vim.env.SSH_CLIENT or "not set"))
    
    -- Check if socket exists
    local socket_path = "/tmp/kitty-joshsymonds"
    local socket_exists = vim.fn.filereadable(socket_path) == 1
    print("Socket exists at " .. socket_path .. ": " .. tostring(socket_exists))
    
    -- Try to get clipboard
    local clipboard = kitty_paste()
    if clipboard and clipboard ~= "" then
      print("Clipboard content (first 100 chars): " .. string.sub(clipboard, 1, 100))
    else
      print("Unable to get clipboard content")
    end
  end, { nargs = 0 })
end