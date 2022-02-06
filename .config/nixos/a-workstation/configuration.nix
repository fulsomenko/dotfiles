#v Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:


## Packages from the nixos unstable channel ##
let
  unstable = import <nixos-unstable> {
    config = config.nixpkgs.config; 
  };
in
{
  programs.zsh.enable = true;
  programs.zsh.autosuggestions.enable = true;
  # programs.zsh.syntaxHighlighting.enable = true;

  programs.tmux.enable = true;

  # nix.package = pkgs.nixUnstable;
  # nix.extraOptions = ''
  #  experimental-features = nix-command flakes
  # '';

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./geoip.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
     font = "Lat2-Terminus16";
     keyMap = "us";
  };

  # This was supposed to make vim neovim, it didnt work
  # programs.neovim.enable = true;

  nixpkgs.overlays = [
    (self: super: {
      neovim = super.neovim.override {
        viAlias = true;
        vimAlias = true;
      };
    })
  ];
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     ardour
     minecraft
     yadm 
     udev libudev
     solaar logitech-udev-rules
     protontricks steam-run playonlinux
     zoom-us
     barrier
     htop
     fish
     direnv
     file
     stow
     nebula
     wget
     insomnia
     podman-compose
     docker-compose
     blender
     obsidian
     i3lock betterlockscreen xorg.xdpyinfo bc feh
     polybar rofi rxvt-unicode alacritty
     git
     neofetch
     vim neovim nodePackages.neovim
     go
     gcc glibc
     ghc stack
     haskellPackages.gl
     libcap
     linuxPackages.bcc
     linuxPackages.nvidia_x11
     libGL libGLU freeglut
     zlib
     mkpasswd
     keybase-gui
     yubioath-desktop
     yubikey-manager
     scrot gimp
     wireshark
     # dotnetCorePackages.sdk_3_0
     # dotnetCorePackages.netcore_3_0
     unstable.firefox chromium google-chrome electron
     yubikey-manager lastpass-cli _1password awscli
     unstable.vscode unstable.vscodium unstable.vscodium-fhs
     unstable.fly
     slack signal-desktop discord
     spotify spotify-tui
     unstable.deno
     unstable.nodejs
     unstable.yarn
     nodePackages.typescript
     unstable.cypress
     unstable.capture slop
     ffmpeg
     coreutils unstable.vlc
     networkmanager_l2tp
     networkmanagerapplet
  ];

  environment.variables = { GOROOT = [ "${pkgs.go.out}/share/go" ]; }; 


  networking.networkmanager.enable = true;
  # Make strongSwan aware of NetworkManager config (see NixOS/nixpkgs#64965)
  environment.etc."ipsec.secrets".text = ''include ipsec.d/ipsec.nm-l2tp.secrets'';

  # PCSCD (for yubi)
  services.pcscd.enable = true;
  # Keybase
  services.keybase.enable = true;
  services.kbfs.enable = true;

  # services.compton.enable = true;
  # services.compton.shadow = true;
  # services.compton.inactiveOpacity = 0.8;
  services.picom = {
      enable = true;
      shadow = true;
      inactiveOpacity = 0.85;
      fade = true;
      opacityRules = ["99:'fullscreen' = 'i3lock$'"];
  };
  

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
     pinentryFlavor = "gnome3";
  };

  # Steam
  #nixpkgs.config.packageOverrides = pkgs: {
  #  steam = pkgs.steam.override {
  #    nativeOnly = true;
  #  };
  #};
  programs.steam.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;

  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.opengl.extraPackages = with pkgs; [ rocm-opencl-icd rocm-opencl-runtime rocm-runtime ]; 
  ### Unclear ###

  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

  security.pam.loginLimits = [{
    domain = "*";
    type = "hard";
    item = "nofile";
    value = "1048576";
  }];

  ### Unclear ###

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.extraConfig = ''
    ServerAliveInterval 120
    ServerAliveCountMax 10
  '';
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 4222 9222 24800 ];
  networking.firewall.allowedUDPPorts = [ 24800 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip pkgs.hplipWithPlugin ];
  services.avahi.publish.userServices = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;



  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.opengl.setLdLibraryPath = true;
  hardware.opengl.enable = true;
  services.xserver = {
    exportConfiguration = true; # link /usr/share/X11/ properly
    # Enable the X11 windowing system.
    enable = true;
    layout = "us,se";
    xkbOptions = "eurosign:e,grp:alt_space_toggle";
    videoDrivers = [ "nvidia" ];
  };

  # Enable touchpad support.
  #services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
 # services.xserver.displayManager.sddm.enable = true;
 # services.xserver.desktopManager.plasma5.enable = true;

  # Enable bspwm
  services.xserver.windowManager.bspwm.enable = true;

  # Allow unfree stuff
  nixpkgs.config.allowUnfree = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  # ZFS - https://timklampe.cool/docs/example/nixos/nixos_install/
  boot.supportedFilesystems = [ "zfs" "ntfs" ];
  #boot.extraModulePackages = [ config.boot.kernelPackages.rtl8812au ];

  # services.zfs.autoSnapshot.enable = true;
  services.zfs.trim.enable = true;

  fileSystems."/mnt/concourse-workdir0" = {
    device = "/dev/zvol/rpool/concourse-workdir0-ext4";
    fsType = "ext4";
  };

  networking.hostId = "ab79c420";
  networking.hostName = "a-workstation";

  time.timeZone = "Europe/Berlin";

  #boot.kernelPackages = linuxPackages_latest;

  hardware.bluetooth.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

  # Docker
  virtualisation.docker.enable = true;

  fonts.fonts = with pkgs; [
   ubuntu_font_family
   fira-code
   #mononoki
   noto-fonts-cjk
   corefonts
  ];

  programs.mosh.enable = true;
  programs.mosh.withUtempter = true;

  users.users.max = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "libvirtd" "usb" "docker" "wireshark" ];
    shell = pkgs.zsh;
  };
  users.users.max.packages = with pkgs; [
    (wineWowPackages.full.override {
      wineRelease = "staging";
      mingwSupport = true;
    })
    (winetricks.override {
      wine = wineWowPackages.staging;
    })
  ];

#  nix.gc = {
#    automatic = true;
#    dates = "weekly";
#    options = "--delete-older-than 30d";
#  };
}

