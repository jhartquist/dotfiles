{
  description = "john's darwin + home-manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ nixpkgs, nix-darwin, home-manager, nix-homebrew, ... }:
    let
      # Everything that differs between machines. rebuild.sh picks one by $USER.
      hosts = {
        personal = { user = "john";          email = "john@hartquist.com"; sign = false; };
        work     = { user = "john"; email = "john@hartquist.com";       sign = true; };
      };

      mkDarwin = host: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit host; inherit (host) user; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Pre-existing files in the way get moved aside, not a failed switch.
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = { inherit host; inherit (host) user; };
            home-manager.users.${host.user}.imports = [ ./home.nix ./home-darwin.nix ];
          }
        ];
      };
    in
    {
      darwinConfigurations = builtins.mapAttrs (_: mkDarwin) hosts;

      # Ubuntu deep-learning box: system stays vanilla apt (CUDA drivers etc.),
      # nix owns only the user environment. Applied by setup-ubuntu.sh.
      homeConfigurations."john@ubuntu" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { host = hosts.personal; inherit (hosts.personal) user; };
          modules = [ ./home.nix ./home-linux.nix ];
        };
    };
}
