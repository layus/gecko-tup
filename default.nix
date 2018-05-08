
let
  pkgs = nixpkgs;

  nixpkgs-mozilla-src = builtins.fetchGit {
    #url = "git://github.com/mozilla/nixpkgs-mozilla";
    #rev = "42a0926f2f36cac2da53782259948ba071b6c6c5";
    url = "https://github.com/layus/nixpkgs-mozilla";
    rev = "fe050d7a80017823a404429f4ed919afe2cb45f8";
    ref = "gecko-tup";
    name = "nixpkgs-mozilla";
  };

  nixpkgs-src = builtins.fetchGit {
    url = "git://github.com/NixOS/nixpkgs";
    #rev = "ed070354a9e307fdf20a94cb2af749738562385d"; // Too old
    #rev = "7a04c2ca296c0698f1c7d5c17be7f931f77691f7"; // master, as of 2018-03-13
    rev = "77fead018146843ae8dce908af0c6d9404c8c87e"; # The channel, some time ago.
    #ref = "master";
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
      set -x
      bash -e ${./mozconfig.in}

      export MY_HISTFILE=$PWD/.zhistory
      export __ETC_PROFILE_DONE=1
      export __ETC_ZSHENV_SOURCED=1

      builtin cd ./gecko-dev
      exec ${pkgs.zsh}/bin/zsh
    '';
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.rustc pkgs.cargo pkgs.zsh fake-tup fake-fusermount ];
    phases = [ "buildPhase" ];
    buildCommand = "mkdir $out";
  });

  fake-tup = pkgs.writeShellScriptBin "tup" ''
    exec /home/gmaudoux/projets/tup/bin/tup "$@"
  '';
  fake-fusermount = pkgs.runCommand "fusermount" { } ''
    mkdir -p $out/bin
    ln -sfn /run/wrappers/bin/fusermount $out/bin/fusermount
  '';

  env = (pkgs.buildEnv {
    pathsToLink = [ "/bin" ];
    name = "gecko-dev-env";
    paths = geckoDrv.buildInputs;
  }) // {
    shellHook = ''
      ln -sfn ${placeholder "out"}/bin $PWD/bin
    '';
  };

  firefox-unwrapped = {
    __toString = _: "/home/gmaudoux/projets/gecko-tup/gecko-dev/obj-tup/dist";
    meta = {};
  };
  firefox = pkgs.wrapFirefox firefox-unwrapped {
    browserName = "firefox";
    name = "gecko-HEAD";
  };

in {
  inherit geckoDrv env;
  inherit (pkgs) firefox;
}

