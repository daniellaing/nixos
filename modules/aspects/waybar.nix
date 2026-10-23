{inputs, ...}: {
  flake-file.inputs.waybar = {
    url = "github:alexays/waybar";
  };

  modules.waybar = {pkgs, ...}: {
    home-manager.sharedModules = [
      {
        programs.waybar = {
          enable = true;
          package = pkgs.waybar.overrideAttrs (old: {
            src = inputs.waybar;
            buildInputs =
              old.buildInputs
              ++ (with pkgs; [
                modemmanager
                libcava
              ]);
          });
          systemd.enable = true;
        };
      }
    ];
  };
}
