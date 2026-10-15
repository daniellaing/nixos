{inputs, ...}: {
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/NixOS-WSL/main";
  };

  hosts.wsl.modules.hardware = {
    imports = [inputs.nixos-wsl.nixosModules.default];

    nixpkgs.hostPlatform = "x86_64-linux";

    wsl = {
      enable = true;
      defaultUser = "daniel";
      startMenuLaunchers = true;
      ssh-agent.enable = true; # Enables ssh passthrough to Windows
    };
  };
}
