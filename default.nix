{ mkDerivation, aeson, base, bytestring, cereal, containers
, criterion, geojson, hspec, lens, microlens, microlens-platform
, optparse-applicative, optparse-generic, protobuf, QuickCheck
, scientific, stdenv, stm, text, trifecta, unordered-containers
, utf8-string, vector, vectortiles
}:
mkDerivation {
  pname = "zellige";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson base bytestring containers geojson optparse-applicative
    scientific stm text trifecta unordered-containers utf8-string
    vector vectortiles
  ];
  executableHaskellDepends = [ base optparse-applicative text ];
  testHaskellDepends = [
    aeson base containers geojson hspec lens QuickCheck scientific text
    vector vectortiles
  ];
  benchmarkHaskellDepends = [
    base bytestring cereal containers criterion microlens
    microlens-platform optparse-generic protobuf text vector
    vectortiles
  ];
  homepage = "https://github.com/githubuser/zellige#readme";
  license = stdenv.lib.licenses.asl20;
}
