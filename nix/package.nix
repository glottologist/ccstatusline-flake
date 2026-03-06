{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  bun,
  makeWrapper,
  git,
  version,
  rev,
}:

buildNpmPackage rec {
  pname = "ccstatusline";
  inherit version;

  src = fetchFromGitHub {
    owner = "sirmalloc";
    repo = "ccstatusline";
    inherit rev;
    hash = "sha256-yeZH0nv1TElYildFIpdhgw2WoP0vC0p6zPFe7+/7CuI=";
  };

  postPatch = ''
    cp ${../package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-DG4zPDCW4wZ/iLaXssi1mWwrG7EdiV//1yABhsKT7jA=";

  npmFlags = [ "--legacy-peer-deps" ];

  nodejs = nodejs_22;

  nativeBuildInputs = [
    makeWrapper
    bun
  ];

  # Use bun as the bundler (matching upstream) to produce a self-contained
  # Node.js script. npm handles dependency installation; bun only bundles.
  buildPhase = ''
    runHook preBuild

    # Apply upstream ink patch (from patchedDependencies in bun.lock)
    patch -p1 -d node_modules/ink < patches/ink@6.2.0.patch

    bun build src/ccstatusline.ts \
      --target node \
      --minify \
      --outfile dist/ccstatusline.js

    # Replace version placeholder (mirrors upstream scripts/replace-version.ts)
    substituteInPlace dist/ccstatusline.js \
      --replace-quiet '__PACKAGE_VERSION__' '${version}'

    runHook postBuild
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/ccstatusline $out/bin
    cp dist/ccstatusline.js $out/lib/ccstatusline/ccstatusline.js

    makeWrapper ${nodejs_22}/bin/node $out/bin/ccstatusline \
      --add-flags "$out/lib/ccstatusline/ccstatusline.js" \
      --prefix PATH : ${lib.makeBinPath [ git ]}

    runHook postInstall
  '';

  meta = {
    description = "A customizable status line formatter for Claude Code CLI";
    homepage = "https://github.com/sirmalloc/ccstatusline";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "ccstatusline";
    platforms = lib.platforms.all;
  };
}
