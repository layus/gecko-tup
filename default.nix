
let
  pkgs = nixpkgs;

  nixpkgs-mozilla-src = builtins.fetchGit {
    #url = "git://github.com/mozilla/nixpkgs-mozilla";
    #rev = "42a0926f2f36cac2da53782259948ba071b6c6c5";
    url = "https://github.com/layus/nixpkgs-mozilla";
    rev = "c67a1900d477d4521fd3905636b183cc780e1ae6"; # gecko-tup branch
    ref = "gecko-tup";
    name = "nixpkgs-mozilla";
  };
  
  nixpkgs-src = builtins.fetchGit {
    url = "git://github.com/NixOS/nixpkgs";
    rev = "ed070354a9e307fdf20a94cb2af749738562385d";
    ref = "master";
    name = "nixpkgs";
  };
  
  nixpkgs = import nixpkgs-src rec {
    localSystem = { system = "x86_64-linux"; };
  };

  nixpkgs-mozilla = import "${nixpkgs-mozilla-src}/release.nix" {
    nixpkgsSrc = nixpkgs-src;
    lib = pkgs.lib // { inNixShell = true; };
  };
  
  geckoDrv = nixpkgs-mozilla.gecko.x86_64-linux.gcc.overrideDerivation (oldAttrs: {
    shellHook = oldAttrs.shellHook + ''
      MY_HISTFILE=$PWD/.zhistory exec ${pkgs.zsh}/bin/zsh
    '';
  });

in geckoDrv.override {
  rust = null;
}

