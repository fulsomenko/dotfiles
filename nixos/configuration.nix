# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config = {
      allowUnfree = true;
      programs.vim.enable = true;
    };
  };

  external-ip = pkgs.writeScriptBin "external-ip" ''
    dig @resolver4.opendns.com myip.opendns.com +short
  ''; 

in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nix = {
    package = pkgs.nixUnstable; # or versioned attributes like nix_2_4
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  
  # Allow unfree stuff
  nixpkgs.config.allowUnfree = true;
  
  # Save builder configuration.nix /run/current-system/full-config
  system.extraSystemBuilderCmds = "ln -s ${./.} $out/full-config";

  users.users.max = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "libvirtd" "usb" "docker" "network" ];
    shell = pkgs.zsh;
  };

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.kernelModules = [ "amdgpu" ];
    supportedFilesystems = [ "zfs" "ntfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
    pulseaudio.enable = true;
    #opengl = {
    #  enable = true;
      #driSupport = true;
      #driSupport32Bit = true;
   # };  
  };

  sound.enable = true;

  networking = {
    firewall.enable = false;
    wireless = {
      enable = true;
      interfaces = [ "wlp4s0" ];
    };
    useDHCP = false;
    interfaces.enp3s0.useDHCP = true;
    interfaces.wlp4s0.useDHCP = true;
    nameservers = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ];
    hostId = "ab79cb21";
    hostName = "a-smol-workstation";
#   Configure network proxy if necessary
#   proxy.default = "http://user:password@proxy:port/";
#   proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
     font = "Lat2-Terminus16";
     keyMap = "us";
  };

  
  environment = {
    variables.EDITOR = "nvim";
    # Depending on the details of your configuration, this section might be necessary or not;
    # feel free to experiment
    shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    '';
    systemPackages = with pkgs; [ 
      ocaml
      ocamlPackages.merlin
      

      xsel xautomation
      unstable.tdesktop
      unstable.arcan.arcan
      unstable.arcan.xarcan
      unstable.arcan.pipeworld
      pavucontrol
      gnupg pinentry-curses pinentry-qt paperkey wget
      unstable.discord
      external-ip
      killall
      openfortivpn
      (import ./vim.nix)
      taskwarrior
      zoom-us signal-desktop
      virt-manager
      dig
      gimp
      libsecret
      xorg.xbacklight
      xdotool xclip
      bat
      hplip
      mdp
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
      #haskellPackages.OpenGL
      libGL libGLU freeglut
      go lua
      gcc
      unstable.rustup
      unstable.rust-analyzer
      unzip
      zig
      unstable.deno
      stow
      unstable.glibc
      gtk2-x11
      gtk3-x11
      libnotify
      # GConfri2
      nss
      xorg.libXScrnSaver
      alsaLib
      docker-compose
     # ghc stack
      mkpasswd
      scrot capture fswebcam
      godot
      firefox brave chromium
      google-chrome
      electron
      lastpass-cli
      #unstable.vscode
      unstable.vscode-fhs
      #dotnetCorePackages.sdk_3_1
      awscli
      unstable.bluemix-cli
      slack
      spotify vlc
      i3lock
      betterlockscreen
      xorg.xdpyinfo
      bc
      feh
      keybase-gui
      (pkgs.firefox.override {
        extraPolicies = {
          DontCheckDefaultBrowser = true;
          DisablePocket = true;
        };
      })
    ];
  };

  services = {
    xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "eurosign:e";
      videoDrivers = [ "amdgpu" ];
      libinput.enable = true;
      windowManager.bspwm.enable = true;    
    };
    picom = {
      enable = false;
      shadow = true;
      inactiveOpacity = 0.85;
      fade = true;
      opacityRules = ["99:'fullscreen' = 'i3lock$"];
      backend = "glx";
      vSync = true; 
    };
    printing = {
      enable = true;
      drivers = [ pkgs.hplip pkgs.hplipWithPlugin ];
    };
    avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        userServices = true;
      };
    };  
    keybase.enable = true;
    kbfs.enable = true;
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
    zfs = {
      trim = {
        enable = true;
        interval = "weekly";
      };
      autoScrub = {
        enable = true;
        interval = "monthly";
      };
      autoSnapshot = {
        enable = true;
        #autoSnapshot.interval = "monthly";
      };
    };
    openssh.enable = true; 
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  fileSystems."/mnt/concourse-workdir0" = {
    device = "/dev/zvol/rpool/concourse-workdir0-ext4";
    fsType = "ext4";
  };

  time.timeZone = "Europe/Berlin";

  # Docker
  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  fonts.fonts = with pkgs; [
    ubuntu_font_family
    mononoki
    noto-fonts-cjk
    fira-code
  ];

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    tmux = {
      enable = true;
      clock24 = true;
      extraConfig = '''';
    };
#   Some programs need SUID wrappers, can be configured further or are
#   started in user sessions.
    mtr.enable = true;
    gnupg.agent.pinentryFlavor = "curses";
    ssh.extraConfig = "ServerAliveInterval 60";
    mosh.enable = true;
    mosh.withUtempter = true;
    dconf.enable = true;
    neovim = {
      enable = true;
      withNodeJs = true;
      configure = {
        customRC = ''
        

          let g:coc_config_home = '~/.config/coc/coc-settings.json'
    	    syntax enable
          filetype plugin indent on
          let g:rustfmt_autosave = 1
          let g:rustfmt_command = 'rustup run stable rustfmt'
      '';
            packages.myVimPackage = with pkgs.vimPlugins; {
          # loaded on launch
          start = [
            gruvbox
            vim-prettier
            
            nvim-lspconfig
            fugitive
            vim-polyglot
            vim-solidity
            vim-surround
            #ale
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
            coc-nvim
            coc-tsserver
            coc-go
            coc-rls
            coc-lua
            coc-git
            coc-css
            coc-yaml
            coc-json
            coc-jest
            coc-java
            coc-html
            coc-cmake
            coc-tslint
            coc-python
            coc-eslint
            coc-prettier
            coc-markdownlint
            coc-tslint-plugin
            coc-spell-checker
            coc-rust-analyzer
  	      ];
  #       manually loadable by calling `:packadd $plugin-name`
          opt = [ ];
        };
      };
    };
  };
}
