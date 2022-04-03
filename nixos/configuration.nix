# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config = {
      allowUnfree = true;
      programs.vim.enable = true;
#      pulseaudio = true;
    };
  };

  external-ip = pkgs.writeScriptBin "external-ip" ''
    dig @resolver4.opendns.com myip.opendns.com +short
  ''; 

in
{
  imports =
    [
      ./nvim.nix
      ./services/redis.nix
      ./services/registry.nix
      ./hardware-configuration.nix

      <musnix>
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

  musnix.enable = true;

  users.users.max = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "libvirtd" "usb" "docker" "network" "jackaudio" ];
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
    pulseaudio = {
      enable = true;
      daemon.config = {
        default-sample-rate = 44100;
        default-sample-format = "s24le";
        alternate-sample-rate = 48000;
      };
      #support32Bit = true;
      #package = pkgs.pulseaudioFull;
#      extraConfig = "default-sample-rate = 44100";
    #  configFile = pkgs.runCommand "default.pa" {} ''
    #    sed 's/module-udev-detect$/module-udev-detect tsched=0/' \
    #      ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
    #  '';
    };
    #opengl = {
    #  enable = true;
      #driSupport = true;
      #driSupport32Bit = true;
   # };  
  };

  sound = {
    enable = true;
  #  extraConfig = "test";
#    extraConfig = "defaults.pcm.!card \"DNX1600\"\ndefaults.ctl.!card \"DNX1600\"";
  };

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
    extraHosts = ''
      10.10.0.99 a-server
      10.10.0.100 a-workstation
    '';
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
      qjackctl
      unstable.reaper
      bitwarden
      teams
      reaper
      arcan.arcan
      direnv stow
      polybar alacritty rxvt-unicode
      dunst
      rofi
      neofetch
      xsel xautomation
      pavucontrol
      gnupg pinentry-curses pinentry-qt paperkey wget
      unstable.discord
      killall
      openfortivpn
      (import ./vim.nix)
      taskwarrior
      zoom-us # signal-desktop
      barrier
      gimp
      libsecret
      xorg.xbacklight
      xdotool xclip
      bat dig htop external-ip zig
      hplip
      mdp
      niv
      unstable.obsidian
      fly
      linuxPackages.bcc
      unstable.insomnia
      unstable.docker-compose
      libcap
      mesa
      unstable.rustup
      unstable.rust-analyzer
      unzip
      gtk2-x11
      gtk3-x11
      libnotify
      nss
      xorg.libXScrnSaver
      alsaLib
      scrot capture fswebcam
      godot
      git
      #unstable.vscode
      unstable.vscode-fhs
      slack
      unstable.spotify unstable.vlc
      i3lock betterlockscreen
      xorg.xdpyinfo
      bc
      feh
      unstable.keybase-gui
      unstable.firefox unstable.brave unstable.chromium
      (unstable.firefox.override {
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
    jack = {
      jackd.enable = true;
      alsa.enable = false;
      loopback = {
        enable = true;
      };
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
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
     # zsh.shellAliases = {
      
     # };
    };
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
