{
  inputs,
  moduleWithSystem,
  rootPath,
  ...
}: let
  sopsDir = "/var/lib/sops";
  scriptName = "init-sops";
  defaultSopsFormat = "json";
  # ------------
  sopsFilename = "secrets.${defaultSopsFormat}";
  defaultSopsFile = "${sopsDir}/${sopsFilename}";
  keyFile = "${sopsDir}/key.txt";
in {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
  };

  modules.sops = moduleWithSystem ({self', ...}: {
    imports = [inputs.sops-nix.nixosModules.default];

    sops = {
      inherit defaultSopsFile defaultSopsFormat;
      validateSopsFiles = false;
      age = {inherit keyFile;};
    };

    users.groups.sops = {};

    environment.systemPackages = with self'.packages; [init-sops];
  });

  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    debug = f: lib.trace f f;
  in {
    packages."${scriptName}" = pkgs.writeShellApplication {
      name = scriptName;
      runtimeInputs = with pkgs; [
        coreutils # chown chmod cat cp
        sops
      ];
      text = debug ''
        usage() { printf "Usage:\n\t%s [secrets-directory] [public-key-path] [private-key-path]\n" "$0" 1>&2; exit 1; }

        set-perms() {
          chown -R root:sops ${sopsDir}
          chmod -R 660 ${sopsDir}
          chmod 770 ${sopsDir}
        }

        # Test valid arguments were given
        if [ -z "$1" ] || ! { [ -d "$1" ] ; }; then
          usage
        fi
        if [ -z "$2" ] || ! { [ -f "$2" ] ; }; then
          usage
        fi
        if [ -z "$3" ] || ! { [ -f "$3" ] ; }; then
          usage
        fi

        if ! { [ -d ${sopsDir} ] ; }; then
          printf "Initialising secrerts directory at ${sopsDir}\n"
          mkdir -p ${sopsDir}
        fi


        printf "Writing new sops file at %s\n" "${defaultSopsFile}"
        nix eval --raw --file ${debug (lib.path.append rootPath "module/aspects/sops/_mk-sops.nix")} --apply "f: f {
          lib = import <nixpkgs/lib>;
          root = ./$1;
        }" | sops encrypt --age "$(cat "$2")" --filename-override "${sopsFilename}" --output "${defaultSopsFile}"
        cp -v "$3" ${keyFile}

        set-perms
      '';
    };
  };
}
