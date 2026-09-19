{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    # formatters / linters
    alejandra # Nix formatter
    stylua # Lua formatter (Neovim configs, etc.)
    black # Python formatter
    prettier # JS/TS/JSON formatter

    # core runtimes / CLI utilities
    speedtest-cli # Speedtest CLI
    codex # AI

    # terminal / UI apps
    kitty-themes # Kitty color scheme collection
    swaynotificationcenter # notification daemon UI
    pavucontrol # audio volume control GUI
    inputs.wlctl.packages.${pkgs.stdenv.hostPlatform.system}.default # network TUI

    # desktop / communication apps
    discord # chat/voice platform
    telegram-desktop # Telegram messenger
    anki-bin # spaced repetition flashcards
    obs-studio # streaming/recording software
    qbittorrent # torrent client

    # browsing / internet tools
    chromium # open-source browser
    insomnia # API testing client (Postman alternative)

    # development tools / IDEs
    vscode # Visual Studio Code editor
    jetbrains.idea # IntelliJ IDEA IDE
    jetbrains.pycharm # PyCharm IDE

    # system utilities
    libnotify # desktop notifications CLI (notify-send)
    playerctl # media control CLI (play/pause etc.)
    brightnessctl # screen brightness control
    wl-clipboard # Wayland clipboard tools (wl-copy/paste)
    cliphist # clipboard history manager
    sl # fun terminal animation (train)
    hollywood # “hacker screen” fake terminal effect
    unrar # archive utility
    hyprmoncfg # monitors TUI and daemon

    # Wayland graphics / screen tools
    slurp # region selector (screenshots)
    grim # screenshot tool for Wayland
    swappy # screenshot annotation tool
    wf-recorder # screen recording tool (Wayland)
    hyprpaper # wallpaper daemon for Hyprland
    gamescope # gaming compositor (Steam/Proton use)

    # office / productivity
    libreoffice-qt # office suite (documents/spreadsheets/etc.)
    hunspell # spell checker engine
    hunspellDicts.ru_RU # Russian dictionary for hunspell
    hunspellDicts.en-us # English dictionary for hunspell
    foliate # ebook reader
    readest # ebook reader, yes, another one
    koreader

    # media / creative tools
    vlc # media player
    audacity # audio editor
    jellyfin-desktop # media playback service

    # gaming / emulation
    prismlauncher # Minecraft launcher

    # system / hardware utilities
    bluetui # Bluetooth TUI manager

    # password / identity
    # _1password-gui # password manager

    # digital signature / gov tools
    qdigidoc # Estonian digital signing tool

    # miscellaneous / experiments
    waypaper # wallpaper picker frontend
    wireguard-tools # tools for wireguard
  ];
}
