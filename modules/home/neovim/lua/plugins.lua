require("gitsigns").setup()

require("lualine").setup()

require("yazi").setup({
	open_for_directories = true,
})

require("which-key").setup()

require("conform").setup({
	formatters_by_ft = {
		nix = { "alejandra" },
		lua = { "stylua" },
		python = { "black" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		json = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
	},

	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
})
