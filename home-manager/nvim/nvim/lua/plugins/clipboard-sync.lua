return {
  {
    "piknik-clipboard",
    name = "piknik-clipboard",
    lazy = false,
    priority = 1000, -- Load early to set up clipboard
    config = function()
      -- Don't do ANY network checks on startup - just check if piknik exists
      local piknik_available = vim.fn.executable('piknik') == 1
      
      if not piknik_available then
        -- No piknik installed, just use default clipboard
        return
      end
      
      -- Create a smart clipboard provider that handles failures gracefully
      vim.g.clipboard = {
        name = 'piknik-with-fallback',
        copy = {
          ['+'] = function(lines, regtype)
            -- Try piknik with very short timeout
            local cmd = 'timeout 0.2 piknik -copy 2>/dev/null'
            local job = vim.fn.jobstart(cmd, {
              on_stdin = function(job_id, data, event)
                -- Send data to piknik
                vim.fn.chansend(job_id, lines)
                vim.fn.chanclose(job_id, 'stdin')
              end,
              on_exit = function(job_id, exit_code)
                if exit_code ~= 0 then
                  -- Piknik failed, use OSC52 fallback
                  -- This is silent and doesn't block
                  pcall(function()
                    require('vim.ui.clipboard.osc52').copy('+')(lines, regtype)
                  end)
                end
              end
            })
          end,
          ['*'] = function(lines, regtype)
            -- Same for * register
            local cmd = 'timeout 0.2 piknik -copy 2>/dev/null'
            local job = vim.fn.jobstart(cmd, {
              on_stdin = function(job_id, data, event)
                vim.fn.chansend(job_id, lines)
                vim.fn.chanclose(job_id, 'stdin')
              end,
              on_exit = function(job_id, exit_code)
                if exit_code ~= 0 then
                  pcall(function()
                    require('vim.ui.clipboard.osc52').copy('*')(lines, regtype)
                  end)
                end
              end
            })
          end,
        },
        paste = {
          ['+'] = function()
            -- Try piknik paste with short timeout
            local result = vim.fn.system('timeout 0.2 piknik -paste 2>/dev/null')
            if vim.v.shell_error == 0 and result ~= '' then
              -- Remove trailing newline if present
              result = result:gsub('\n$', '')
              return vim.split(result, '\n')
            else
              -- Fallback to OSC52 or native clipboard
              local ok, clipboard = pcall(function()
                return require('vim.ui.clipboard.osc52').paste('+')()
              end)
              if ok and clipboard then
                return clipboard
              end
              -- Ultimate fallback - return empty
              return {}
            end
          end,
          ['*'] = function()
            -- Same logic for * register
            local result = vim.fn.system('timeout 0.2 piknik -paste 2>/dev/null')
            if vim.v.shell_error == 0 and result ~= '' then
              result = result:gsub('\n$', '')
              return vim.split(result, '\n')
            else
              local ok, clipboard = pcall(function()
                return require('vim.ui.clipboard.osc52').paste('*')()
              end)
              if ok and clipboard then
                return clipboard
              end
              return {}
            end
          end,
        },
        cache_enabled = true,
      }
      
      -- Check piknik status asynchronously after startup
      vim.defer_fn(function()
        local result = vim.fn.system('timeout 0.5 nc -z ultraviolet 8075 2>/dev/null')
        if vim.v.shell_error == 0 then
          vim.notify("Clipboard: Piknik server reachable", vim.log.levels.INFO)
        else
          vim.notify("Clipboard: Piknik unreachable, using fallback", vim.log.levels.WARN)
        end
      end, 1000)  -- Check 1 second after startup
    end,
    -- This is not a real plugin, just a configuration
    dir = vim.fn.stdpath("config"),
  },
}