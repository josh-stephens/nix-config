return {
  {
    "piknik-clipboard",
    name = "piknik-clipboard",
    lazy = false,
    priority = 1000, -- Load early to set up clipboard
    config = function()
      -- Try to use piknik if available AND server is reachable
      local piknik_available = vim.fn.executable('piknik') == 1
      local piknik_reachable = false
      
      if piknik_available then
        -- Test if piknik server is reachable
        local result = vim.fn.system('timeout 1 piknik -paste 2>&1')
        piknik_reachable = vim.v.shell_error == 0 or result:match("empty")
      end
      
      if piknik_available and piknik_reachable then
        vim.g.clipboard = {
          name = 'piknik',
          copy = {
            ['+'] = {'piknik', '-copy'},
            ['*'] = {'piknik', '-copy'},
          },
          paste = {
            ['+'] = {'piknik', '-paste'},
            ['*'] = {'piknik', '-paste'},
          },
          cache_enabled = true,
        }
        vim.notify("Clipboard: Using piknik for remote sync", vim.log.levels.INFO)
      else
        -- Fall back to OSC52 if piknik is not available or unreachable
        -- This ensures yanking still works even if piknik is down
        if piknik_available then
          vim.notify("Clipboard: Piknik unreachable, using OSC52 fallback", vim.log.levels.WARN)
        else
          vim.notify("Clipboard: Piknik not installed, using OSC52", vim.log.levels.WARN)
        end
        -- OSC52 is automatically used by Neovim when no clipboard is configured
      end
    end,
    -- This is not a real plugin, just a configuration
    dir = vim.fn.stdpath("config"),
  },
}