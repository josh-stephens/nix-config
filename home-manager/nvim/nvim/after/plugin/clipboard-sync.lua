-- Piknik clipboard integration for remote development
-- Only use piknik if it's available
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
end