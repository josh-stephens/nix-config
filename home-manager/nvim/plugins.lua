-- Telescope
-- Do not display cmp autocompletions in telescope search windows
require("cmp").setup({
  enabled = function ()
    buftype = vim.api.nvim_buf_get_option(0, "buftype")
    if buftype == "prompt" then return false end
    return true
end
})

local transform_mod = require('telescope.actions.mt').transform_mod
local actions = require('telescope.actions')
local mod = {}
mod.open_in_nvim_tree = function(prompt_bufnr)
    local cur_win = vim.api.nvim_get_current_win()
    if not cur_win or cur_win == "1000" or cur_win == 1000 then return true end
    vim.cmd("NvimTreeFindFile")
    vim.api.nvim_set_current_win(cur_win)
end

mod = transform_mod(mod)

--- Open Telescope-selected file in nvim-tree
require("telescope").setup{
  defaults = {
    mappings = {
      i = {
          ["<CR>"] = actions.select_default + mod.open_in_nvim_tree,
      },
      n = {
          ["<CR>"] = actions.select_default + mod.open_in_nvim_tree,
      },
    },
  },
}
require("telescope").load_extension('manix')

-- LSP Attachment
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- LSPConfig
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
local lsp_on_attach = function(bufnr)
  vim.api.nvim_clear_autocmds({group = augroup, buffer = bufnr})
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = augroup,
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.format()
      filter = function(client)
        return client.name == "null-ls"
      end
    end,
  })
  vim.api.nvim_create_autocmd("CursorHold", {
    buffer = bufnr,
    callback = function()
      local opts = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = 'rounded',
        source = 'always',
        prefix = ' ',
        scope = 'cursor',
      }
      vim.diagnostic.open_float(nil, opts)
    end
  })
end

local servers = { 'bashls', 'html', 'jsonls', 'rnix', 'gopls', 'rust_analyzer' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = function(client, bufnr)
      lsp_on_attach(bufnr)
    end,
    capabilities = capabilities,
  }
end

-- Copilot
require("copilot_cmp").setup({
  formatters = {
    insert_text = require("copilot_cmp.format").remove_existing
  },
})

-- Catppuccin
require("catppuccin").setup({
  transparent_background = true
})

-- Comment
require('Comment').setup()

-- Trim
require('trim').setup()

-- Leap
require('leap').add_default_mappings()

-- nvim-tree
require("nvim-tree").setup {
  renderer = {
    icons = {
      glyphs = {
        git = {
          untracked = "󰓎",
        },
      },
    },
  },
}
