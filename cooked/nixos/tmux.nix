{
  lib,
  config,
  ...
}: let
  cfg = config.cooked.tmux;
in {
  options.cooked.tmux = {
    enable = lib.mkEnableOption "tmux";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      escapeTime = lib.mkDefault 10;
      keyMode = lib.mkDefault "vi";
      clock24 = lib.mkDefault true;
    };
  };
}
