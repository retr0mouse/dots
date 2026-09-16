{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    withRuby = true;

    extraPackages = with pkgs; [
      nil # nix
      lua-language-server # lua
      jdt-language-server # java
      pyright # python
      typescript-language-server # ts/js
      vscode-langservers-extracted # html/css/json/ESLint
      yaml-language-server # yaml
      bash-language-server # bash
      dockerfile-language-server # dockerfile
      ripgrep
    ];

    plugins = let
      alabaster-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "alabaster-nvim";
        version = "unstable";

        src = pkgs.fetchFromGitHub {
          owner = "p00f";
          repo = "alabaster.nvim";
          rev = "master";
          hash = "sha256-Rp/nl5dlz55aChrYUL7ir3XtWDFFS99CHS3l3FoCI7c=";
        };
      };
    in
      with pkgs.vimPlugins; [
        alabaster-nvim

        # syntax
        nvim-treesitter.withAllGrammars

        # LSP
        nvim-lspconfig
        nvim-jdtls

        # completion
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        luasnip
        cmp_luasnip

        # formatting
        conform-nvim

        # navigation
        telescope-nvim
        yazi-nvim

        # UI
        lualine-nvim
        bufferline-nvim
        which-key-nvim

        # git
        gitsigns-nvim

        # diagnostics
        trouble-nvim

        # editing
        nvim-autopairs
        indent-blankline-nvim

        plenary-nvim
      ];

    extraConfig = ''
      set termguicolors
      colorscheme alabaster
    '';

    initLua = ''
      package.path = package.path .. ";${./lua}/?.lua"

      require("options")
      require("keymaps")
      require("plugins")
      require("completion")
      require("lsp")
      require("treesitter")
      require("autocmds")
    '';
  };
}
