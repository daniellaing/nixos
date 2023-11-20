{ config, pkgs, ... }:

{
  services.sxhkd = {
    enable = true;
    keybindings = {
      # "super + c" = pkgs.writeShellScript "script" "$TERMINAL -c calcurse";
      "super + e" = "$TERMINAL -c neomutt";
    };
  };
}
