{pkgs, ...}: let
  filePreview = pkgs.writeShellApplication {
    name = "dots-file-preview";
    runtimeInputs = [
      pkgs.bat
      pkgs.unzip
    ];
    text = ''
      file="$1"

      case "''${file,,}" in
        *.zip)
          unzip -l "$file"
          ;;
        *)
          bat --color=always --style=numbers -- "$file"
          ;;
      esac
    '';
  };

  contentSearch = pkgs.writeShellApplication {
    name = "dots-content-search";
    runtimeInputs = [pkgs.ripgrep];
    text = ''
      query="''${1:-}"

      if [[ -z "$query" ]]; then
        exit 0
      fi

      exec rg \
        --column \
        --line-number \
        --no-heading \
        --color=never \
        --field-match-separator=$'\t' \
        --hidden \
        --glob '!**/.git/**' \
        --glob '!**/.cache/**' \
        --glob '!**/.local/**' \
        --glob '!**/.codex/**' \
        --glob '!**/.claude/**' \
        --glob '!**/.config/JetBrains/**' \
        --glob '!**/.zsh_history' \
        --glob '!**/.bash_history' \
        -- "$query" . 2>/dev/null
    '';
  };
in {
  home.packages = with pkgs; [
    bat
    fd
    unzip
    xdg-utils
  ];

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "dots";
      theme_background = true;
      truecolor = true;
      rounded_corners = false;
      graph_symbol = "braille";
      update_ms = 1000;
    };
    themes.dots = ''
      theme[main_bg]="#101211"
      theme[main_fg]="#c5c8c5"
      theme[title]="#98a87c"
      theme[hi_fg]="#7f9f9f"
      theme[selected_bg]="#1a1d1b"
      theme[selected_fg]="#98a87c"
      theme[inactive_fg]="#303630"
      theme[graph_text]="#c5c8c5"
      theme[meter_bg]="#1a1d1b"
      theme[proc_misc]="#7f9f9f"
      theme[cpu_box]="#303630"
      theme[mem_box]="#303630"
      theme[net_box]="#303630"
      theme[proc_box]="#303630"
      theme[div_line]="#303630"
      theme[temp_start]="#7f9f9f"
      theme[temp_mid]="#98a87c"
      theme[temp_end]="#d08770"
      theme[cpu_start]="#98a87c"
      theme[cpu_mid]="#7f9f9f"
      theme[cpu_end]="#c5c8c5"
      theme[free_start]="#d08770"
      theme[free_mid]="#7f9f9f"
      theme[free_end]="#98a87c"
      theme[cached_start]="#303630"
      theme[cached_mid]="#7f9f9f"
      theme[cached_end]="#98a87c"
      theme[available_start]="#303630"
      theme[available_mid]="#7f9f9f"
      theme[available_end]="#98a87c"
      theme[used_start]="#98a87c"
      theme[used_mid]="#7f9f9f"
      theme[used_end]="#d08770"
      theme[download_start]="#303630"
      theme[download_mid]="#7f9f9f"
      theme[download_end]="#98a87c"
      theme[upload_start]="#303630"
      theme[upload_mid]="#98a87c"
      theme[upload_end]="#d08770"
      theme[process_start]="#98a87c"
      theme[process_mid]="#7f9f9f"
      theme[process_end]="#d08770"
    '';
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "yy";
    theme = {
      app.overall = {
        fg = "#c5c8c5";
        bg = "#101211";
      };

      mgr = {
        syntect_theme = "${./alabaster-dark.tmTheme}";
        cwd = {
          fg = "#98a87c";
          bold = true;
        };
        find_keyword = {
          fg = "#7f9f9f";
          bold = true;
          underline = true;
        };
        find_position = {fg = "#303630";};
        marker_copied = {
          fg = "#98a87c";
          bg = "#98a87c";
        };
        marker_cut = {
          fg = "#d08770";
          bg = "#d08770";
        };
        marker_marked = {
          fg = "#7f9f9f";
          bg = "#7f9f9f";
        };
        marker_selected = {
          fg = "#98a87c";
          bg = "#98a87c";
        };
        border_symbol = "│";
        border_style = {fg = "#303630";};
      };

      filetype.rules = [
        {
          mime = "image/*";
          fg = "yellow";
        }
        {
          mime = "{audio,video}/*";
          fg = "magenta";
        }
        {
          mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
          fg = "red";
        }
        {
          mime = "application/{pdf,doc,rtf}";
          fg = "cyan";
        }
        {
          mime = "vfs/{absent,stale}";
          fg = "darkgray";
        }
        {
          url = "*";
          is = "orphan";
          bg = "red";
        }
        {
          url = "*";
          is = "exec";
          fg = "green";
        }
        {
          url = "*";
          is = "dummy";
          bg = "red";
        }
        {
          url = "*/";
          is = "dummy";
          bg = "red";
        }
        {
          url = "*/";
          fg = "#98a87c";
        }
      ];

      icon.prepend_dirs = [
        {
          name = ".config";
          text = "";
          fg = "#98a87c";
        }
        {
          name = ".git";
          text = "";
          fg = "#98a87c";
        }
        {
          name = ".github";
          text = "";
          fg = "#98a87c";
        }
        {
          name = ".npm";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Desktop";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Development";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Documents";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Downloads";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Library";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Movies";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Music";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Pictures";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Public";
          text = "";
          fg = "#98a87c";
        }
        {
          name = "Videos";
          text = "";
          fg = "#98a87c";
        }
      ];

      icon.prepend_conds = [
        {
          "if" = "dir & hovered";
          text = "";
          fg = "#98a87c";
        }
        {
          "if" = "dir";
          text = "";
          fg = "#98a87c";
        }
      ];

      tabs = {
        active = {
          fg = "#101211";
          bg = "#98a87c";
          bold = true;
        };
        inactive = {
          fg = "#c5c8c5";
          bg = "#1a1d1b";
        };
      };

      mode = {
        normal_main = {
          fg = "#101211";
          bg = "#98a87c";
          bold = true;
        };
        normal_alt = {
          fg = "#98a87c";
          bg = "#1a1d1b";
        };
        select_main = {
          fg = "#101211";
          bg = "#7f9f9f";
          bold = true;
        };
        select_alt = {
          fg = "#7f9f9f";
          bg = "#1a1d1b";
        };
        unset_main = {
          fg = "#101211";
          bg = "#d08770";
          bold = true;
        };
        unset_alt = {
          fg = "#d08770";
          bg = "#1a1d1b";
        };
      };

      indicator = {
        parent = {fg = "#303630";};
        current = {
          fg = "#101211";
          bg = "#98a87c";
        };
        preview = {
          fg = "#7f9f9f";
          underline = true;
        };
      };

      status = {
        overall = {
          fg = "#c5c8c5";
          bg = "#101211";
        };
        perm_sep = {fg = "#303630";};
        perm_type = {fg = "#98a87c";};
        perm_read = {fg = "#c5c8c5";};
        perm_write = {fg = "#7f9f9f";};
        perm_exec = {fg = "#d08770";};
        progress_label = {
          fg = "#c5c8c5";
          bold = true;
        };
        progress_normal = {
          fg = "#98a87c";
          bg = "#1a1d1b";
        };
        progress_error = {
          fg = "#d08770";
          bg = "#1a1d1b";
        };
      };

      input = {
        border = {fg = "#303630";};
        title = {fg = "#98a87c";};
        value = {fg = "#c5c8c5";};
        selected = {
          fg = "#101211";
          bg = "#98a87c";
        };
      };

      cmp = {
        border = {fg = "#303630";};
        active = {
          fg = "#98a87c";
          bg = "#1a1d1b";
        };
        inactive = {fg = "#c5c8c5";};
      };

      tasks = {
        border = {fg = "#303630";};
        title = {fg = "#98a87c";};
        hovered = {
          fg = "#98a87c";
          bg = "#1a1d1b";
        };
      };

      which = {
        mask = {bg = "#101211";};
        cand = {fg = "#98a87c";};
        rest = {fg = "#c5c8c5";};
        desc = {fg = "#7f9f9f";};
        separator = " | ";
        separator_style = {fg = "#303630";};
      };

      help = {
        on = {fg = "#98a87c";};
        run = {fg = "#7f9f9f";};
        desc = {fg = "#c5c8c5";};
        hovered = {
          fg = "#98a87c";
          bg = "#1a1d1b";
          bold = true;
        };
        footer = {
          fg = "#303630";
          bg = "#101211";
        };
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    colors = {
      bg = "#101211";
      "bg+" = "#1a1d1b";
      fg = "#c5c8c5";
      "fg+" = "#98a87c";
      hl = "#7f9f9f";
      "hl+" = "#7f9f9f";
      info = "#303630";
      marker = "#98a87c";
      pointer = "#98a87c";
      prompt = "#98a87c";
      spinner = "#7f9f9f";
      header = "#303630";
      border = "#303630";
      label = "#98a87c";
    };
    defaultOptions = [
      "--height=45%"
      "--layout=reverse"
      "--border=sharp"
      "--border-label=[fzf]"
      "--info=inline-right"
      "--prompt=[find|] "
      "--pointer=>"
      "--marker=+"
      "--padding=1"
    ];
  };

  programs.zsh.initContent = ''
    # Fuzzy history search (Ctrl-R)
    fzf-line-history-widget() {
      setopt localoptions pipefail no_aliases
      local selected

      selected="$(
        builtin fc -rl 1 |
          awk '
            match($0, /^[ \t]*[0-9]+\**[ \t]+/) {
              command = substr($0, RLENGTH + 1)
              if (!seen[command]++) print command
            }
          ' |
          fzf \
            --height=55% \
            --scheme=history \
            --exact \
            --no-multi \
            --no-wrap \
            --cycle \
            --prompt='[history] ' \
            --border-label='[history]' \
            --header='Enter insert · Ctrl-R sort · Ctrl-/ wrap · Esc cancel' \
            --bind='ctrl-r:toggle-sort+first,ctrl-/:toggle-wrap' \
            --query="$LBUFFER"
      )"
      local result=$?

      if (( result == 0 )) && [[ -n "$selected" ]]; then
        BUFFER="$selected"
        CURSOR=$#BUFFER
      fi

      zle reset-prompt
      return $result
    }

    zle -N fzf-line-history-widget
    bindkey -M emacs '^R' fzf-line-history-widget

    dots-fzf-file-widget() {
      local file absolute_file mime_type default_app

      file="$(
        fd --type f --hidden --exclude .git |
          fzf \
            --height=80% \
            --scheme=path \
            --border-label='[files]' \
            --prompt='[files] ' \
            --no-multi \
            --cycle \
            --header='Enter open · Ctrl-J/K navigate · Esc cancel' \
            --bind='ctrl-j:down,ctrl-k:up' \
            --preview='${filePreview}/bin/dots-file-preview {}' \
            --preview-window='right:55%:wrap'
      )"
      local result=$?

      if (( result == 0 )) && [[ -n "$file" ]]; then
        absolute_file="''${file:A}"
        mime_type="$(xdg-mime query filetype "$absolute_file" 2>/dev/null || true)"

        if [[ -n "$mime_type" ]]; then
          default_app="$(xdg-mime query default "$mime_type" 2>/dev/null || true)"
        else
          default_app=""
        fi

        if [[ "$default_app" == nvim.desktop ]]; then
          nvim -- "$absolute_file"
          result=$?
        else
          case "$mime_type" in
            text/* | application/json | application/*+json | application/yaml | application/x-yaml | application/toml | application/xml | application/*+xml | application/javascript | application/x-javascript | application/x-shellscript)
              nvim -- "$absolute_file"
              result=$?
              ;;
            *)
              case "''${absolute_file:l}" in
                *.ts | *.tsx | *.jsx | *.vue | *.svelte | *.astro | *.templ | *.tf | *.hcl | *.proto)
                  nvim -- "$absolute_file"
                  result=$?
                  ;;
                *)
                  case "$default_app" in
                    "" | org.gnome.FileRoller.desktop)
                      builtin cd -- "''${absolute_file:h}"
                      result=$?
                      ;;
                    *)
                      xdg-open "$absolute_file"
                      result=$?
                      ;;
                  esac
                  ;;
              esac
              ;;
          esac
        fi
      fi

      zle reset-prompt
      return $result
    }

    zle -N dots-fzf-file-widget
    bindkey -M emacs '^F' dots-fzf-file-widget

    dots-fzf-content-widget() {
      local selected file line column

      selected="$(
        : | fzf \
          --height=80% \
          --disabled \
          --delimiter=$'\t' \
          --with-nth='1,2,4' \
          --border-label='[grep]' \
          --prompt='[grep] ' \
          --no-multi \
          --cycle \
          --header='Type to search · Enter open · Ctrl-J/K navigate · Esc cancel' \
          --bind='ctrl-j:down,ctrl-k:up' \
          --bind='start:reload(${contentSearch}/bin/dots-content-search {q} || true),change:reload(${contentSearch}/bin/dots-content-search {q} || true)' \
          --preview='bat --color=always --style=numbers --highlight-line {2} -- {1}' \
          --preview-window='right:55%:wrap:~3:+{2}+3/2'
      )"
      local result=$?

      if (( result == 0 )) && [[ -n "$selected" ]]; then
        IFS=$'\t' read -r file line column _ <<< "$selected"

        if [[ -n "$file" && "$line" == <-> && "$column" == <-> ]]; then
          nvim "+call cursor($line, $column)" -- "$file"
          result=$?
        else
          result=1
        fi
      fi

      zle reset-prompt
      return $result
    }

    zle -N dots-fzf-content-widget
    bindkey -M emacs '^G' dots-fzf-content-widget
  '';
}
