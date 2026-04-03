{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      palette = import ./modules/themes/palette.nix;
      shell = name: import ./dev-shells/${name}.nix { inherit pkgs; };
    in
    {
      nixosConfigurations.luftmyszor = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit palette;
        };
        modules = [
          ./hosts/default/configuration.nix
          inputs.home-manager.nixosModules.default
          {
            home-manager.users.luftmyszor = {
              imports = [ ./hosts/default/home.nix ];
            };

            home-manager.extraSpecialArgs = { inherit palette; };
          }
        ];
      };

      devShells.${system} = {
        nix = shell "nix";
        python = shell "python";
        cpp = shell "cpp";
        csharp = shell "csharp";
      };
    };
}
