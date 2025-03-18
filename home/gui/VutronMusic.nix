{
  stdenv,
  fetchurl,
  electron,
  makeWrapper,
  ...
}:
stdenv.mkDerivation rec {
  pname = "VutronMusic";
  version = "1.6.0";
  src = fetchurl {
    url = "https://gh.hitaoboy.top/github.com/stark81/VutronMusic/releases/download/v${version}/VutronMusic.${version}_amd64.deb";
    sha256 = "ndFuBC/lT81Fsu6UQs3NlAKOLKoA/05VPKYChqw+j6o=";
  };

  unpackPhase = ''
    ar x ${src}
    tar xf data.tar.xz
  '';

  buildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall
    mkdir -p $out

    cp -r usr/share $out/share
    sed -i "s|Exec=.*|Exec=$out/bin/VutronMusic|" $out/share/applications/*.desktop

    cp -r opt/VutronMusic/resources $out/opt

    makeWrapper ${electron}/bin/electron $out/bin/VutronMusic \
    --add-flags "$out/opt/app.asar"
    runHook postInstall
  '';
}
