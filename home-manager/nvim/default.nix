{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.nixneovim.nixosModules.default

    ./lsp.nix
    ./nvim-cmp.nix
    ./telescope.nix
  ];

  nixpkgs = {
    overlays = [
      inputs.nixneovim.overlays.default
    ];
  };

  programs.nixneovim = {
    enable = true;
    colorscheme = "catppuccin-mocha";

    plugins = {
      treesitter = {
        enable = true;
        indent = true;
      };
      mini = {
        enable = true;
        ai.enable = true;
        jump.enable = true;
      };
      lualine = {
        enable = true;
        theme = "catppuccin";
        extensions = [ "fzf" "nvim-tree" ];
      };
      gitsigns.enable = true;
      luasnip.enable = true;
      nvim-tree.enable = true;
      fugitive.enable = true;
    };

    extraPlugins = with pkgs.vimExtraPlugins; [
      catppuccin
      leap-nvim
      nvim-web-devicons
      copilot-lua
      copilot-cmp
      cmp-nvim-lsp
      cmp-luasnip
      cmp-buffer
      cmp-path
      cmp-rg
      Comment-nvim
      indent-blankline-nvim
    ];

    mappings = {
      normal = {
        "<leader>t" = "'<cmd>NvimTreeToggle<cr>'";
        "<c-h>" = "'<c-w>h'";
        "<c-j>" = "'<c-w>j'";
        "<c-k>" = "'<c-w>k'";
        "<c-l>" = "'<c-w>l'";
        "<leader>n" = "'<cmd>noh<cr>'";
        "<c-p>" = "'<cmd>Telescope buffers show_all_buffers=true theme=get_dropdown<cr>'";
        "<c-P>" = "'<cmd>Telescope commands theme=get_dropdown<cr>'";
        "<c-a>" = "'<cmd>Telescope buffers show_all_buffers=true theme=get_dropdown<cr>'";
        "<c-a>" = "'<cmd>Telescope frecency theme=get_dropdown<cr>'";
        "<c-s>" = "'<cmd>Telescope git_files theme=get_dropdown<cr>'";
        "<c-d>" = "'<cmd>Telescope find_files theme=get_dropdown<cr>'";
        "<c-g>" = "'<cmd>Telescope live_grep theme=get_dropdown<cr>'";
        "<leader>e" = "vim.diagnostic.open_float";
        "[d" = "vim.diagnostic.goto_prev";
        "]d" = "vim.diagnostic.goto_next";
        "<leader>q" = "vim.diagnostic.setloclist";
      };
    };

    extraConfigLua = ''
      ${lib.strings.fileContents ./opts.lua}
      ${lib.strings.fileContents ./plugins.lua}
    '';
  };
}
