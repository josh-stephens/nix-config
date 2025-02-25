return {
  "folke/snacks.nvim",
  config = function()
    local snacks_ok, snacks = pcall(require, "snacks")
    if not snacks_ok then
      return
    end
    
    -- Store the original open function
    local original_open = snacks.open
    
    -- Override the open function to add split selection
    snacks.open = function(file)
      -- Ask user which split to use
      vim.ui.select(
        { "current", "vertical", "horizontal", "tab" },
        {
          prompt = "Open in which split?",
          format_item = function(item)
            local icons = {
              current = " ",
              vertical = "▎",
              horizontal = "―",
              tab = "󰓩 ",
            }
            return icons[item] .. " " .. item
          end,
        },
        function(choice)
          if not choice then return end
          
          if choice == "current" then
            vim.cmd("edit " .. vim.fn.fnameescape(file))
          elseif choice == "vertical" then
            vim.cmd("vsplit " .. vim.fn.fnameescape(file))
          elseif choice == "horizontal" then
            vim.cmd("split " .. vim.fn.fnameescape(file))
          elseif choice == "tab" then
            vim.cmd("tabnew " .. vim.fn.fnameescape(file))
          end
        end
      )
    end
  end,
}
