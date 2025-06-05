-- Configure linkpearl as clipboard provider if available
if vim.fn.executable('linkpearl') == 1 then
  vim.g.clipboard = {
    name = 'linkpearl',
    copy = {
      ['+'] = {'linkpearl', 'copy'},
      ['*'] = {'linkpearl', 'copy'},
    },
    paste = {
      ['+'] = {'linkpearl', 'paste'},
      ['*'] = {'linkpearl', 'paste'},
    },
    cache_enabled = 0,
  }
else
  -- Neovim will auto-detect the best clipboard provider
  -- No configuration needed - defaults work well across platforms
end