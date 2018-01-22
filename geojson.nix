{ mkDerivation, aeson, base, bytestring, directory, doctest
, filepath, hlint, lens, QuickCheck, semigroups, stdenv
, template-haskell, text, transformers, validation, vector
}:
mkDerivation {
  pname = "geojson";
  version = "1.3.0";
  sha256 = "18fr5n3nmxlr97b7s9a5x1dx91fcg2fjfhlpxpcglkpwpkhabnqs";
  libraryHaskellDepends = [
    aeson base lens semigroups text transformers validation vector
  ];
  testHaskellDepends = [
    base bytestring directory doctest filepath hlint QuickCheck
    template-haskell
  ];
  homepage = "https://github.com/domdere/hs-geojson";
  description = "A thin GeoJSON Layer above the aeson library";
  license = stdenv.lib.licenses.bsd3;
}
