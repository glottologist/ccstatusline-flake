{
  description = "A customizable status line formatter for Claude Code CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      version = "2.2.2";
      rev = "34fa51277864ef111d51b072d7edd66f8772ca02";
    in
    {
      overlays.default = final: _prev: {
        ccstatusline = final.callPackage ./nix/package.nix {
          inherit version rev;
        };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          ccstatusline = pkgs.callPackage ./nix/package.nix {
            inherit version rev;
          };
          default = self.packages.${system}.ccstatusline;
        }
      );
    };
}
