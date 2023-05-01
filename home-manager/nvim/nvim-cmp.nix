{ inputs, lib, config, pkgs, ... }: {
  programs.nixneovim.plugins.nvim-cmp = {
    snippet.luasnip.enable = true;
    enable = true;
    mappingPresets = [ "insert" ];
    mapping = {
      "<Tab>" = ''
        cmp.mapping(function(fallback)
          local has_words_before = function()
            unpack = unpack or table.unpack
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
          end
          local luasnip = require("luasnip")

          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable() 
          -- they way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" })
      '';
      "<S-Tab>" =''
        cmp.mapping(function(fallback)
          local has_words_before = function()
            unpack = unpack or table.unpack
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
          end
          local luasnip = require("luasnip")

          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" })
      '';
      "<C-b>" = "cmp.mapping.scroll_docs(-4)";
      "<C-f>" = "cmp.mapping.scroll_docs(4)";
      "<C-Space>" = "cmp.mapping.complete()";
      "<C-c>" = "cmp.mapping.abort()";
      "<CR>" = "cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })";
    };
    sources = {
      "copilot" = {
        enable = true;
        groupIndex = 2;
      };
      "nvim_lsp" = {
        enable = true;
        groupIndex = 2;
        entryFilter = ''
          function(entry, ctx)
            return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
          end
        '';
      };
      "buffer" = {
        enable = true;
        groupIndex = 2;
        option = {
          keyword_length = 5;
        };
      };
      "luasnip" = {
        enable = true;
        groupIndex = 2;
        option = {
          "use_show_condition" = false;
          show_autosnippets = true;
        };
      };
      "path" = {
        enable = true;
        groupIndex = 2;
      };
      "rg" = {
        enable = true;
        groupIndex = 2;
        option = {
          keyword_length = 5;
        };
      };
    };
    sorting = {
      priority_weight = 2;
      comparators = ''{
        require("copilot_cmp.comparators").prioritize,
        -- Below is the default comparitor list and order for nvim-cmp
        cmp.config.compare.offset,
        -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
        cmp.config.compare.exact,
        cmp.config.compare.score,
        cmp.config.compare.recently_used,
        cmp.config.compare.locality,
        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
      }'';
    };
  };
}
