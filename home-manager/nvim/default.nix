{ inputs, lib, config, pkgs, ... }: {
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  imports = [
    inputs.nixneovim.nixosModules.default

    ./lsp.nix
    ./nvim-cmp.nix
    ./telescope.nix
  ];

  programs.nixneovim = {
    enable = true;
    colorscheme = "catppuccin-mocha";

    globals = {
      mapleader = " ";
      maplocalleader = ",";
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    options = {
      textwidth = 0;
      scrolloff = 4;
      wildmode = "longest:full,full";
      wildoptions = "pum";
      inccommand = "nosplit";
      lazyredraw = true;
      showmatch = true;
      ignorecase = true;
      smartcase = true;
      tabstop = 2;
      softtabstop = 0;
      expandtab = true;
      shiftwidth = 2;
      number = true;
      backspace = "indent,eol,start";
      smartindent = true;
      laststatus = 3;
      showmode = false;
      shada = "'20,<50,s10,h,/100";
      hidden = true;
      joinspaces = false;
      updatetime = 100;
      conceallevel = 2;
      concealcursor = "nc";
      previewheight = 5;
      synmaxcol = 500;
      display = "msgsep";
      cursorline = true;
      modeline = false;
      mouse = "nivh";
      signcolumn = "yes:1";
      ruler = true;
      clipboard = "unnamedplus";
      termguicolors = true;
    };

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
      telescope-manix
      trim-nvim
    ];

    mappings = {
      normal = {
        "<leader>t" = "'<cmd>NvimTreeToggle<cr>'";
        "<c-h>" = {
          action = "'<c-w>h'";
          noremap = true;
          silent = true;
        };
        "<c-j>" = {
          action = "'<c-w>j'";
          noremap = true;
          silent = true;
        };
        "<c-k>" = {
          action = "'<c-w>k'";
          noremap = true;
          silent = true;
        };
        "<c-l>" = {
          action = "'<c-w>l'";
          noremap = true;
          silent = true;
        };
        "<leader>n" = "'<cmd>noh<cr>'";
        "<c-p>" = "'<cmd>Telescope buffers show_all_buffers=true theme=get_dropdown<cr>'";
        "<c-P>" = "'<cmd>Telescope commands theme=get_dropdown<cr>'";
        "<c-a>" = "'<cmd>Telescope buffers show_all_buffers=true theme=get_dropdown<cr>'";
        "<c-e>" = "'<cmd>Telescope frecency theme=get_dropdown<cr>'";
        "<c-s>" = "'<cmd>Telescope git_files theme=get_dropdown<cr>'";
        "<c-d>" = "'<cmd>Telescope find_files theme=get_dropdown<cr>'";
        "<c-g>" = "'<cmd>Telescope live_grep theme=get_dropdown<cr>'";
        "<c-n>" = "'<cmd>Telescope manix<cr>'";
        "<leader>e" = "vim.diagnostic.open_float";
        "[d" = "vim.diagnostic.goto_prev";
        "]d" = "vim.diagnostic.goto_next";
        "<leader>q" = "vim.diagnostic.setloclist";
      };
    };

    extraConfigLua = ''
      ${lib.strings.fileContents ./plugins.lua}
    '';
  };
}
