{
  config,
  pkgs,
  ...
}: let
  # Dependencies
  bc = "${pkgs.bc}/bin/bc";
  ncmpcpp = "${config.programs.ncmpcpp.package}/bin/ncmpcpp";
  neomutt = "${pkgs.neomutt}/bin/neomutt";
  terminal = "${config.programs.terminal}";
in {
  imports = [../modules/XF86.nix];
  XF86 = {
    calculator = "${terminal} ${bc}";
    mail = "${terminal} ${neomutt}";
    music = "${terminal} ${ncmpcpp}";
    terminal = "${terminal}";
  };
}
