
let
  pkgs = nixpkgs;

  nixpkgs-mozilla-src = builtins.fetchGit {
    #url = "git://github.com/mozilla/nixpkgs-mozilla";
    #rev = "42a0926f2f36cac2da53782259948ba071b6c6c5";
    url = "https://github.com/layus/nixpkgs-mozilla";
    rev = "4572166d74d32df94fa5cafae7de68790be02586";
    ref = "gecko-tup";
    name = "nixpkgs-mozilla";
  };
  
  nixpkgs-src = builtins.fetchGit {
    url = "git://github.com/NixOS/nixpkgs";
    #rev = "ed070354a9e307fdf20a94cb2af749738562385d"; // Too old
    #rev = "7a04c2ca296c0698f1c7d5c17be7f931f77691f7"; // master, as of 2018-03-13
    rev = "77fead018146843ae8dce908af0c6d9404c8c87e"; # The channel, some time ago.
    ref = "master";
    name = "nixpkgs";
  };
  
  nixpkgs = import nixpkgs-src rec {
    localSystem = { system = "x86_64-linux"; };
  };

  nixpkgs-mozilla = import "${nixpkgs-mozilla-src}/release.nix" {
    nixpkgsSrc = nixpkgs-src;
    lib = pkgs.lib;
  };
  
  geckoDrv = (nixpkgs-mozilla.gecko.x86_64-linux.gcc.override {
    rust = null;
    inNixShell = true;
  }).overrideDerivation (oldAttrs: {
    shellHook = oldAttrs.shellHook + ''
      builtin cd ./gecko-dev
      export __ETC_PROFILE_DONE=1 __ETC_ZSHENV_SOURCED=1
      MY_HISTFILE=$PWD/.zhistory exec ${pkgs.zsh}/bin/zsh
    '';
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.rustc pkgs.cargo pkgs.zsh ];
  });

in geckoDrv

