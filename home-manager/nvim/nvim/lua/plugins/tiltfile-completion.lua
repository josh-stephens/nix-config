return {
  -- Add Tiltfile-specific completions
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      -- Create a custom source for Tiltfile functions
      {
        "ray-x/cmp-treesitter",
        config = function()
          -- Register Tiltfile keywords when in a Tiltfile
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "tiltfile",
            callback = function()
              -- Common Tiltfile functions and their signatures
              local tilt_keywords = {
                -- Resource functions
                "k8s_yaml",
                "docker_build",
                "local_resource",
                "k8s_resource",
                "dc_resource",
                
                -- Configuration functions
                "load",
                "include",
                "watch_file",
                "watch_settings",
                "trigger_mode",
                "update_settings",
                "version_settings",
                "secret_settings",
                
                -- Build functions
                "custom_build",
                "docker_compose",
                "helm",
                
                -- Utility functions
                "fail",
                "warn",
                "read_file",
                "read_json",
                "read_yaml",
                "blob",
                "encode_json",
                "encode_yaml",
                "decode_json",
                "decode_yaml",
                
                -- Port forwarding
                "port_forward",
                "link",
                
                -- Environment
                "os.environ.get",
                "os.path.exists",
                "os.path.join",
                "os.path.basename",
                "os.path.dirname",
                
                -- Tilt-specific globals
                "config.main_path",
                "config.main_dir",
                "config.tilt_subcommand",
              }
              
              -- Add to buffer-local completion
              vim.b.tiltfile_keywords = tilt_keywords
            end,
          })
        end,
      },
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      
      -- Add a custom source for Tiltfile
      table.insert(opts.sources, {
        name = "treesitter",
        group_index = 3,
      })
      
      -- Configure sorting to prioritize Tiltfile functions
      opts.sorting = vim.tbl_deep_extend("force", opts.sorting or {}, {
        comparators = {
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          cmp.config.compare.score,
          cmp.config.compare.recently_used,
          function(entry1, entry2)
            -- Prioritize Tiltfile keywords
            if vim.bo.filetype == "tiltfile" and vim.b.tiltfile_keywords then
              local item1 = entry1:get_word()
              local item2 = entry2:get_word()
              local is_tilt1 = vim.tbl_contains(vim.b.tiltfile_keywords, item1)
              local is_tilt2 = vim.tbl_contains(vim.b.tiltfile_keywords, item2)
              
              if is_tilt1 and not is_tilt2 then
                return true
              elseif not is_tilt1 and is_tilt2 then
                return false
              end
            end
            return nil
          end,
          cmp.config.compare.kind,
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      })
      
      return opts
    end,
  },
}