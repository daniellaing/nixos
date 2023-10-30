{ config, pkgs, ... }:

let
  nixLocateAuto = builtins.fetchTarball {
    url = "https://gist.github.com/InternetUnexplorer/58e979642102d66f57188764bbf11701/archive/3046ee564fed5b60cee5e5ef39b1837c04cc3aa2.zip";
    sha256 = "0hz4rpd0g1096sj1bl69kywv1gg14qaq1pk03jifvq9yhcq2i8pc";
  };
in
{
  programs.command-not-found.enable = false;
  imports = [
    "${nixLocateAuto}/default.nix"
  ];
}
