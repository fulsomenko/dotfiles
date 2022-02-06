# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Save builder configuration.nix /run/current-system/full-config
  system.extraSystemBuilderCmds = "ln -s ${./.} $out/full-config";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # networking.wireless.userControlled.enable = true;
  # This also enables WIFI
  #networking.wireless.enable = true;
  #networking.wireless.interfaces = [ "wlp4s0" ];
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ]; 
  networking.hostId = "ab79cb21";
  networking.hostName = "a-smol-workstation";
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
     font = "Lat2-Terminus16";
     keyMap = "us";
  };

#  programs.neovim.enable = true;
  #programs.neovim.withNodeJs = true;
  #programs.neovim.withPython3 = true;

  programs.neovim = {
    enable = true;  
    withNodeJs = true;
    configure = {
      customRC = ''
          " here your custom configuration goes!
          syntax enable
          filetype plugin indent on
          let g:rustfmt_autosave = 1
          let g:rustfmt_command = 'rustup run stable rustfmt'
      
" Set completeopt to have a better completion experience
" :help completeopt
" menuone: popup even when there's only one match
" noinsert: Do not insert text until a selection is made
" noselect: Do not select, force user to select one from the menu
set completeopt=menuone,noinsert,noselect

" Avoid showing extra messages when using completion
set shortmess+=c

" Configure LSP through rust-tools.nvim plugin.
" rust-tools will configure and enable certain LSP features for us.
" See https://github.com/simrat39/rust-tools.nvim#configuration
lua <<EOF

-- nvim_lsp object
local nvim_lsp = require'lspconfig'

local opts = {
    tools = {
        autoSetHints = true,
        hover_with_actions = true,
        runnables = {
            use_telescope = true
        },
        inlay_hints = {
            show_parameter_hints = false,
            parameter_hints_prefix = "",
            other_hints_prefix = "",
        },
    },

    -- all the opts to send to nvim-lspconfig
    -- these override the defaults set by rust-tools.nvim
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
    server = {
        -- on_attach is a callback called when the language server attachs to the buffer
        -- on_attach = on_attach,
        settings = {
            -- to enable rust-analyzer settings visit:
            -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
            ["rust-analyzer"] = {
                -- enable clippy on save
                checkOnSave = {
                    command = "clippy"
                },
            }
        }
    },
}

require('rust-tools').setup(opts)
EOF

" Code navigation shortcuts
" as found in :help lsp
nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>

" Quick-fix
nnoremap <silent> ga    <cmd>lua vim.lsp.buf.code_action()<CR>

" Setup Completion
" See https://github.com/hrsh7th/nvim-cmp#basic-configuration
lua <<EOF
local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    -- Add tab support
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    })
  },

  -- Installed sources
  sources = {
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'path' },
    { name = 'buffer' },
  },
})
EOF

" have a fixed column for the diagnostics to appear in
" this removes the jitter when warnings/errors flow in
set signcolumn=yes

" Set updatetime for CursorHold
" 300ms of no cursor movement to trigger CursorHold
set updatetime=300
" Show diagnostic popup on cursor hover
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })

" Goto previous/next diagnostic warning/error
nnoremap <silent> g[ <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent> g] <cmd>lua vim.lsp.diagnostic.goto_next()<CR>

      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        # loaded on launch
        start = [
                  vim-surround
                  nvim-lspconfig
                  fugitive
                  vim-solidity
    	  	  ale
                  rust-vim
                  rust-tools-nvim
		  
		  nvim-cmp
		  cmp-path
		  cmp-buffer
		  cmp-nvim-lsp
		  plenary-nvim
		  # nord-vim
		  vim-vsnip
		  popup-nvim
		  completion-nvim

                  # nvim-completion-manager
                  # nvim-cm-racer
	        ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [ ];
      };
    };
  };
  #environment.variables.EDITOR = "nvim";

  #nixpkgs.overlays = [
  #  (self: super: {
  #    neovim = super.neovim.override {
  #      viAlias = true;
  #      vimAlias = true;
  #    }; 
  #  })
  #];

  services.gnome.gnome-keyring.enable = true;
  # services.gnome3.gnome-keyring.enable = true;
 
  programs.steam.enable = true;
  programs.light.enable = true;
 
  #networking.networkmanager.enable = true;
  #environment.etc."ipsec.secrets".text = ''include ipsec.d/ipsec.nm-l2tp.secrets'';
  # programs.nm-applet.enable = true;
  #services.xl2tpd.enable = true;

#   users.users.max.packages = with pkgs; [
#     (wineWowPackages.full.override {
#       wineRelease = "staging";
#       mingwSupport = true;
#     })
#     (winetricks.override {
#       wine = wineWowPackages.staging;
#     })
#   ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     taskwarrior
     unstable.minecraft
     zoom-us signal-desktop
     virt-manager
     dig
     gimp
     libsecret
     gnome.gnome-keyring
     xorg.xbacklight
     xdotool xclip
     bat
     hplip 
     mdp
     #kdeApplications.print-manager
     google-drive-ocamlfuse
     neofetch
     niv
     htop
     obsidian
     nebula
     barrier
     unstable.fly
     linuxPackages.bcc
     direnv
     wget
     insomnia
     dunst
     polybar
     rofi
     alacritty rxvt-unicode
     git
     libcap
     mesa
     haskellPackages.OpenGL
     libGL libGLU freeglut
     go lua
     gcc
     unstable.rustup
     unstable.rust-analyzer
     unzip
     zig
     vim #neovim vimPlugins.nvim-lspconfig
     unstable.deno
     unstable.nodejs
     unstable.nodePackages.typescript
     stow
     unstable.cypress
     steam-run
     unstable.glibc
     gtk2-x11
     gtk3-x11
     libnotify
     # GConf2
     nss
     xorg.libXScrnSaver
     alsaLib     

     docker-compose
     ghc stack
     mkpasswd
     scrot capture fswebcam
     godot
     firefox brave chromium
     google-chrome
     electron
     lastpass-cli
     #unstable.vscode
     unstable.vscode-fhs
     dotnetCorePackages.sdk_3_1
     awscli
     unstable.bluemix-cli
     slack
     spotify vlc
     i3lock
     betterlockscreen
     xorg.xdpyinfo
     bc
     feh
     # How to fix vscode liveshare? 
     #openssl
     #krb5
     #zlib
     keybase-gui
  
  (pkgs.firefox.override {
    extraPolicies = {
      DontCheckDefaultBrowser = true;
      DisablePocket = true;
    };
  })
];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
     pinentryFlavor = "gnome3";
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 10000 12345 ];
  networking.firewall.allowedUDPPorts = [ 12345 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  services.picom = {
    enable = true;
    shadow = true;
    inactiveOpacity = 0.85;
    fade = true;
    opacityRules = ["99:'fullscreen' = 'i3lock$"];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip pkgs.hplipWithPlugin ];
  services.avahi.publish.userServices = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  #Enable keybase
  services.keybase.enable = true;
  services.kbfs.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
 # services.xserver.displayManager.sddm.enable = true;
 # services.xserver.desktopManager.plasma5.enable = true;

  # Enable bspwm
  services.xserver.windowManager.bspwm.enable = true;

  # Allow unfree stuff
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  # ZFS - https://timklampe.cool/docs/example/nixos/nixos_install/
  boot.supportedFilesystems = [ "zfs" "ntfs" ];

  services.zfs.trim.enable = true;

  fileSystems."/mnt/concourse-workdir0" = {
    device = "/dev/zvol/rpool/concourse-workdir0-ext4";
    fsType = "ext4";
  };

  time.timeZone = "Europe/Berlin";

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  hardware.bluetooth.enable = true;

  hardware.cpu.amd.updateMicrocode = true;

  # only when using an AMD GPU
  hardware.enableRedistributableFirmware = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Docker
  virtualisation.docker.enable = true;

  # Vm
  #virtualisation.virtualbox.host.enable = true;
  virtualisation.libvirtd.enable = true;

  fonts.fonts = with pkgs; [
    ubuntu_font_family
    mononoki
    noto-fonts-cjk
    fira-code
  ];

  # not necessary but recommended
  services.openssh.enable = true;
  programs.ssh.extraConfig = "ServerAliveInterval 60";
  programs.mosh.enable = true;
  programs.mosh.withUtempter = true;

  programs.dconf.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  users.users.max = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "libvirtd" "usb" "docker" "network" ];
    shell = pkgs.zsh;
  };
}
