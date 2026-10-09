vim.g.mapleader = " "

local telescope = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", telescope.find_files, {
	desc = "Find files",
})

vim.keymap.set("n", "<leader>fg", telescope.live_grep, {
	desc = "Search project text",
})

vim.keymap.set("n", "<leader>fb", telescope.buffers, {
	desc = "Find buffers",
})

vim.keymap.set("n", "<leader>fh", telescope.help_tags, {
	desc = "Search help tags",
})

vim.keymap.set("n", "<leader>-", function()
	require("yazi").yazi()
end, {
	desc = "Open file manager",
})

vim.keymap.set("n", "grn", vim.lsp.buf.rename, {
	desc = "Rename symbol",
})

vim.keymap.set("n", "gra", vim.lsp.buf.code_action, {
	desc = "Code action",
})

vim.keymap.set("n", "grr", vim.lsp.buf.references, {
	desc = "Find references",
})

vim.keymap.set("n", "gri", vim.lsp.buf.implementation, {
	desc = "Go to implementation",
})

vim.keymap.set("n", "grt", vim.lsp.buf.type_definition, {
	desc = "Go to type definition",
})

vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
	desc = "Go to definition",
})

vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {
	desc = "Go to declaration",
})

vim.keymap.set("n", "K", vim.lsp.buf.hover, {
	desc = "Show hover documentation",
})

vim.keymap.set("n", "gO", vim.lsp.buf.document_symbol, {
	desc = "List document symbols",
})

vim.keymap.set("n", "<leader>-", function()
	require("yazi").yazi()
end, {
	desc = "Open Yazi",
})

vim.keymap.set("n", "<leader>F", function()
	require("conform").format({
		async = true,
		lsp_fallback = true,
	})
end, {
	desc = "Format buffer",
})

vim.keymap.set("n", "<leader>x", function()
	require("trouble").toggle("diagnostics")
end, {
	desc = "Toggle diagnostics",
})
