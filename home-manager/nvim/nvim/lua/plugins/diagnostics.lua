return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy", -- Or `LspAttach`
		priority = 2000, -- needs to be loaded in first
		config = function()
			require("tiny-inline-diagnostic").setup({
				options = {
					transparent_bg = true,
					set_arrow_to_diag_color = true,
					multilines = {
						-- Enable multiline diagnostic messages
						enabled = true,

						-- Always show messages on all lines for multiline diagnostics
						always_show = true,
					},
					break_line = {
						-- Enable the feature to break messages after a specific length
						enabled = true,

						-- Number of characters after which to break the line
						after = 30,
					},
					multiple_diag_under_cursor = true,
					show_all_diags_on_cursorline = true,
					enable_on_insert = true,
				},
			})
			vim.diagnostic.config({ virtual_text = false }) -- Only if needed in your configuration, if you already have native LSP diagnostics
		end,
	},
}
