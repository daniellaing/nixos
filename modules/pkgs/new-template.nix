{
  self,
  rootPath,
  ...
}: let
  name = "new-template";
  templates = self.outputs.templates;
in {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages."${name}" = pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = with pkgs; [
        coreutils # echo
        fzy
      ];

      text = ''
        echo "Select a template"
        selection="$(echo '${lib.concatMapAttrsStringSep "\n" (name: _: name) templates}' \
          | fzy)"
        echo "Initialising $selection flake..."
        nix flake init -t ${rootPath}\#"$selection" "$@"
      '';
    };
  };
}
