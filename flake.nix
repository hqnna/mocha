{
  inputs = {
    zls.url = "github:zigtools/zls";
    zig.url = "github:mitchellh/zig-overlay";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, zig, zls }:
    utils.lib.eachDefaultSystem(system:
      let
        zlspkgs = zls.packages.${system};
        overlays = [ zig.overlays.default ];
        pkgs = import nixpkgs { inherit system; overlays = overlays; }; 
      in {
        devShells.default = with pkgs; mkShell {
          packages = [ zigpkgs.master zlspkgs.zls ];
        }; 
      });
}
