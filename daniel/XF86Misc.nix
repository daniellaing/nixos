{ config, pkgs, ... }:
let
  # Dependencies
  bc = "${pkgs.bc}/bin/bc";
  ncmpcpp = "${config.programs.ncmpcpp.package}/bin/ncmpcpp";
  neomutt = "${pkgs.neomutt}/bin/neomutt";
  terminal = "${config.programs.terminal}";
in
{
  imports = [ ../modules/XF86.nix ];
  XF86 = {
    mail = "${terminal} ${neomutt}";
    calculator = "${terminal} ${bc}";
    WWW = "$BROWSER";
    music = "${config.programs.terminal} ${ncmpcpp}";
    terminal = "${terminal}";
  };
}
