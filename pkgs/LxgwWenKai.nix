{
  stdenv,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  pname = "LxgwWenKai";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "lxgw";
    repo = "LxgwWenKai";
    rev = "v1.511";
    sha256 = "sha256-qBVv4X6gSZoTf0AOwrnEuk2Xk2GF+rqf+EPGZeYyTKc=";
  };

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp -r $src/fonts/TTF/* $out/share/fonts/truetype/
  '';
}
