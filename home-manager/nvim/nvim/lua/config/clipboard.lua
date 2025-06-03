-- Force Neovim to use system clipboard commands instead of OSC52
-- This ensures our piknik wrappers are used

if vim.fn.executable('xsel') == 1 then
  -- Use xsel (which is our wrapper that uses piknik)
  vim.g.clipboard = {
    name = 'xsel-piknik',
    copy = {
      ['+'] = {'xsel', '--clipboard', '--input'},
      ['*'] = {'xsel', '--primary', '--input'},
    },
    paste = {
      ['+'] = {'xsel', '--clipboard', '--output'},
      ['*'] = {'xsel', '--primary', '--output'},
    },
    cache_enabled = false,
  }
elseif vim.fn.executable('pbcopy') == 1 then
  -- Fallback to pbcopy/pbpaste if available
  vim.g.clipboard = {
    name = 'pbcopy-piknik',
    copy = {
      ['+'] = {'pbcopy'},
      ['*'] = {'pbcopy'},
    },
    paste = {
      ['+'] = {'pbpaste'},
      ['*'] = {'pbpaste'},
    },
    cache_enabled = false,
  }
end