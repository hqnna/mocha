{
  inputs.zls.url = "github:zigtools/zls";
  inputs.zig.url = "github:mitchellh/zig-overlay";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, utils, zig, zls }:
    utils.lib.eachDefaultSystem(system:
      let
        zlspkg = zls.packages.${system}.default;
        pkgs = import nixpkgs { inherit system; overlays = [ zig.overlays.default ]; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ zigpkgs.master zlspkg ];
        }; 
      });
}
