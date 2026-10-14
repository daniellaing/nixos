{
  flake-file.formatter = pkgs: pkgs.alejandra;
  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
