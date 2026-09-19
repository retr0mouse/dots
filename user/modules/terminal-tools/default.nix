{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "waybar";
      theme_background = true;
      truecolor = true;
      rounded_corners = false;
      graph_symbol = "braille";
      update_ms = 1000;
    };
    themes.waybar = ''
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

  # The upstream fzf widget treats multi-line Zsh history as NUL-delimited
  # records. With shared history that can group unrelated commands into one
  # candidate, so feed fzf only the first line of each real history event.
  programs.zsh.initContent = ''
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
  '';
}
