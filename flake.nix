{
  description = "Home Manager for Nix";

  outputs = { self, nixpkgs }:
    let
      # List of systems supported by home-manager binary
      supportedSystems = nixpkgs.lib.platforms.unix;

      # Function to generate a set based on supported systems
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in rec {
      nixosModules.home-manager = import ./nixos;
      nixosModule = self.nixosModules.home-manager;

      darwinModules.home-manager = import ./nix-darwin;
      darwinModule = self.darwinModules.home-manager;

      packages = forAllSystems (system: {
        home-manager = nixpkgsFor.${system}.callPackage ./home-manager { };
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.home-manager);

      lib = {
        hm = import ./modules/lib { lib = nixpkgs.lib; };
        homeManagerConfiguration = { configuration, system, homeDirectory
          , username, extraSpecialArgs ? { }
          , pkgs ? builtins.getAttr system nixpkgs.outputs.legacyPackages
          , check ? true }@args:
          import ./modules {
            inherit pkgs check extraSpecialArgs;
            configuration = { ... }: {
              imports = [ configuration ];
              home = { inherit homeDirectory username; };
            };
          };
      };
    };
}
