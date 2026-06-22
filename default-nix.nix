{ nixpkgs ? import <nixpkgs> {},
  haskell-tools ? import (builtins.fetchTarball "https://github.com/emberdart/haskell-tools/archive/master.tar.gz") {
    inherit nixpkgs;
    inherit compiler;
  },
  compiler ? "ghc914"
}:
let
  gitignore = nixpkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ];
  tools = haskell-tools compiler;
  inherit (nixpkgs.pkgs.haskell) lib;
  myHaskellPackages = nixpkgs.pkgs.haskell.packages.${compiler}.override {
    overrides = self: super: rec {
      family = lib.dontHaddock (self.callCabal2nix "family" (gitignore ./.) {});
      text-all = lib.doJailbreak (lib.markUnbroken super.text-all);
      # gedcom = lib.doJailbreak (super.gedcom);

      # Release to cabal not yet made
      gedcom = lib.doJailbreak (self.callCabal2nix "gedcom" (nixpkgs.fetchFromGitHub {
        owner = "emberdart";
        repo = "hs-gedcom";
        rev = "901c7f611381cfb7a59e5cc2e0327adc04ae4d65";
        sha256 = "fLP69x++nzkAwWAtaWWfL84AvfIDMW7bX+/z148n7f4=";
      }) {});

      text = self.callHackage "text" "2.1.2" {};
    };
  };
  shell = myHaskellPackages.shellFor {
    packages = p: [
      p.family
    ];
    shellHook = ''
      gen-hie > hie.yaml
      for i in $(find . -type f | grep -v "dist-*"); do krank $i; done
    '';
    buildInputs = tools.defaultBuildTools;
    withHoogle = false;
  };
  in
{
  inherit shell;
  family = lib.justStaticExecutables myHaskellPackages.family;
}
