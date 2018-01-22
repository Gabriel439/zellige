let
  config = {
    packageOverrides = pkgs: {
      haskellPackages = pkgs.haskellPackages.override {
        overrides = haskellPackagesNew: haskellPackagesOld: {
          zellige = haskellPackagesNew.callPackage ./default.nix { };

          geojson = pkgs.haskell.lib.doJailbreak (haskellPackagesNew.callPackage ./geojson.nix { });

          validation = pkgs.haskell.lib.dontCheck haskellPackagesOld.validation;
        };
      };
    };
  };

  fetchNixpkgs = import ./fetchNixpkgs.nix;

  nixpkgs = fetchNixpkgs {
    rev = "1a8a95e87962bc8ff8514b28e026fc987fbdb010";

    sha256 = "0w4cyp3mwy6m93bc0qdbzk3x58xg9pdjvyp50r1f71nk2lpd0292";
  };

  pkgs = import nixpkgs { inherit config; };

in
  { inherit (pkgs.haskellPackages) zellige;
  }
