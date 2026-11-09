{inputs, ...}: let
  sopsDir = "/var/lib/sops";
  defaultSopsFile = "${sopsDir}/secrets.yaml";
  keyFile = "${sopsDir}/key.txt";
in {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
  };

  modules.sops = {
    imports = [inputs.sops-nix.nixosModules.default];

    sops = {
      inherit defaultSopsFile;
      validateSopsFiles = false;
      defaultSopsFormat = "yaml";
      age = {inherit keyFile;};
    };

    users.groups.sops = {};
  };

  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    name = "init-sops";
  in {
    packages."${name}" = pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = with pkgs; [
        coreutils # echo
      ];
      text = ''
        usage() { printf "Usage:\n\t%s [-s <secrets-file-path>] [-k <key-file-path>]\n" "$0" 1>&2; exit 1; }

        set-perms() {
          chown -R root:sops ${sopsDir}
          chmod -R 660 ${sopsDir}
          chmod 770 ${sopsDir}
        }

        while getopts ":s:k:" opt; do
          case "''${opt}" in
            s)
              secrets="''${OPTARG}"
              ;;
            k)
              keyfile="''${OPTARG}"
              ;;
            *)
              usage
              ;;
          esac
        done
        shift $((OPTIND-1))

        # Test arguments were given
        if [ -z "''${secrets}" ] || [ -z "''${keyfile}" ]; then
          usage
        fi

        # Test files are valid
        if ! { [ -f "''${secrets}" ] && [ -f "''${keyfile}" ] ; }; then
          usage
        fi

        if ! { [ -d ${sopsDir} ] ; }; then
          printf "Initialising secrerts directory at ${sopsDir}\n"
          mkdir -p ${sopsDir}
        fi

        cp -v "$secrets" ${defaultSopsFile}
        cp -v "$keyfile" ${keyFile}

        set-perms
      '';
    };
  };
}
