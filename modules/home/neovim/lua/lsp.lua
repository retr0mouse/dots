local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config("lua_ls", {
	capabilities = capabilities,

	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},

			diagnostics = {
				globals = {
					"vim",
				},
			},

			workspace = {
				checkThirdParty = false,
				library = {
					"/run/current-system/sw/share/hypr",
				},
			},

			telemetry = {
				enable = false,
			},
		},
	},
})

local wk = require("which-key")

wk.add({
	{ "gr", group = "LSP" },
})

vim.lsp.config("nil_ls", {
	capabilities = capabilities,
})

vim.lsp.config("pyright", {
	capabilities = capabilities,
})

vim.lsp.config("ts_ls", {
	capabilities = capabilities,
})

vim.lsp.config("cssls", {
	capabilities = capabilities,
})

vim.lsp.enable({
	"nil_ls",
	"lua_ls",
	"pyright",
	"ts_ls",
	"cssls",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "java",
	callback = function()
		require("jdtls").start_or_attach({
			cmd = { "jdtls" },
			root_dir = require("jdtls.setup").find_root({
				"pom.xml",
				"build.gradle",
				".git",
			}),
			capabilities = capabilities,
		})
	end,
})
