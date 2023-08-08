{ inputs, lib, config, pkgs, ... }: {
  programs.nixneovim.plugins = {
    lsp = {
      enable = true;
      servers = {
        bashls.enable = true;
        html.enable = true;
        jsonls.enable = true;
        lua_ls.enable = true;
        rnix-lsp.enable = true;
        gopls.enable = true;
        rust-analyzer.enable = true;
        terraform-ls.enable = true;
        nil.enable = true;
        csharp_ls.enable = true;
      };
    };
    lspkind = {
      enable = true;
      extraLua.post = ''
        local lspkind = require("lspkind")
        lspkind.init({
          symbol_map = {
            Copilot = "",
          },
        })

        vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {fg ="#6CC644"})
      '';
    };
  };
}
