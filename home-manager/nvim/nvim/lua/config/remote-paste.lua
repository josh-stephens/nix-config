-- Smart paste for SSH sessions - use terminal paste instead of OSC52
if vim.env.SSH_TTY then
  -- Helper function to paste using terminal
  local function terminal_paste(mode, before_cursor)
    -- Save current position
    local pos = vim.api.nvim_win_get_cursor(0)
    
    -- For visual mode, we need to delete the selection first
    if mode == 'v' then
      vim.cmd('normal! "_d')
    end
    
    -- Position cursor
    if before_cursor then
      vim.cmd('normal! i')
    else
      vim.cmd('normal! a')
    end
    
    -- Request paste from terminal (this asks Kitty to paste)
    -- Use bracketed paste mode for proper handling
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-v>', true, false, true), 'n', false)
    
    -- Schedule return to normal mode
    vim.schedule(function()
      vim.cmd('stopinsert')
      -- For 'P' (paste before), we need to move cursor back one position
      if before_cursor and mode == 'n' then
        local new_pos = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_win_set_cursor(0, {new_pos[1], math.max(0, new_pos[2] - 1)})
      end
    end)
  end

  -- Override p in normal mode
  vim.keymap.set('n', 'p', function()
    terminal_paste('n', false)
  end, { desc = 'Paste after cursor (terminal)' })

  -- Override P in normal mode  
  vim.keymap.set('n', 'P', function()
    terminal_paste('n', true)
  end, { desc = 'Paste before cursor (terminal)' })

  -- Override p in visual mode
  vim.keymap.set('v', 'p', function()
    terminal_paste('v', false)
  end, { desc = 'Replace selection with paste (terminal)' })
end