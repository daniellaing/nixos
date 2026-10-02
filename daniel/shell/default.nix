{config, ...}: let
  c = config.xdg.configHome;
  d = config.xdg.dataHome;
in {
  imports = [./terminal.nix];

  home = {
    sessionVariables = {
      # TeX
      TEXMFHOME = d + "/texmf";
      TEXMFVAR = "${config.xdg.cacheHome}/texlive/texmf-var";
      TEXMFCONFIG = c + "/texlive/texmf-config";

      # Mathematica
      MATHEMATICA_USERBASE = c + "/mathematica";

      # Cargo
      CARGO_HOME = d + "/cargo";

      # CUDA
      CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    };
  };
}
