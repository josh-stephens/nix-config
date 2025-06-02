return {
  {
    "piknik-clipboard",
    name = "piknik-clipboard",
    lazy = false,
    priority = 1000, -- Load early to set up clipboard
    config = function()
      -- Only configure piknik if it's available
      if vim.fn.executable('piknik') == 1 then
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
        -- Fall back to OSC52 if piknik is not available
        vim.notify("Clipboard: Piknik not available, using OSC52", vim.log.levels.WARN)
      end
    end,
    -- This is not a real plugin, just a configuration
    dir = vim.fn.stdpath("config"),
  },
}