
let
  pkgs = nixpkgs;

  nixpkgs-mozilla-src =  builtins.fetchGit {
    url = "https://github.com/layus/nixpkgs-mozilla";
    rev = "3c152f45d7f4cd1add38bb638ca3ae3a31344f11";
    ref = "gecko-tup";
    name = "nixpkgs-mozilla";
  };

  nixpkgs-src = builtins.fetchGit {
    url = "git://github.com/NixOS/nixpkgs-channels";
    rev = "ef74cafd3e5914fdadd08bf20303328d72d65d6c"; # The 18.03 channel, on 2018-05-14
    ref = "nixos-18.03";
    name = "nixpkgs";
  };

  nixpkgs = import nixpkgs-src rec {
    localSystem = { system = "x86_64-linux"; };
  };

  nixpkgs-mozilla = import "${nixpkgs-mozilla-src}/release.nix" {
    nixpkgsSrc = nixpkgs-src;
    lib = pkgs.lib;
  };

  merge = name: drvs: pkgs.buildEnv {
    pathsToLink = [ "/" "/bin" "/lib" "/include" ];
    name = "${name}-all";
    paths = drvs;
  };
  libevent-all = with pkgs; merge "libevent" [ libevent.dev libevent ];
  libpng-all = with pkgs; merge "libpng" [ libpng.dev libpng ];

  geckoDrv = (nixpkgs-mozilla.gecko.x86_64-linux.gcc.override {
    rust = null;
    inNixShell = true;
  }).overrideDerivation (oldAttrs: {
    shellHook = oldAttrs.shellHook + ''
      set -x
      bash -e ${./mozconfig.in} ${libevent-all} ${libpng-all}
      mach () { env - HOME=$HOME DISPLAY=:0 TERM=$TERM PKG_CONFIG_PATH=$PKG_CONFIG_PATH SHELL=$SHELL PATH=$PATH PYTHONDONTWRITEBYTECODE=True ./mach $@ ; }

      export MY_HISTFILE=$PWD/.zhistory
      export __ETC_PROFILE_DONE=1
      export __ETC_ZSHENV_SOURCED=1

      builtin cd ./gecko-dev
      #exec ${pkgs.zsh}/bin/zsh
    '';
    buildInputs = with nixpkgs.pkgs; oldAttrs.buildInputs ++ [ pkgs.rustc pkgs.cargo pkgs.zsh fake-tup fake-fusermount
      wrapGAppsHook
      icu.dev nss.dev nspr.dev libjpeg.dev zlib bzip2 libpng.dev libvpx.dev hunspell.dev pixman sqlite.dev
      libstartup_notification
    ];
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

