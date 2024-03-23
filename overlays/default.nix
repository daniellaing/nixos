{inputs, ...}: {
  # FIXME: Remove when #297158 merges to unstable
  waybar-fix = final: prev: {
    waybar = prev.waybar.override {
      wireplumber = prev.wireplumber.overrideAttrs rec {
        version = "0.4.17";
        src = prev.fetchFromGitHub {
          owner = "pipewire";
          repo = "wireplumber";
          rev = version;
          sha256 = "sha256-vhpQT67+849WV1SFthQdUeFnYe/okudTQJoL3y+wXwI=";
        };
      };
    };
  };

  stable-packages = final: prev: {
    stable = import inputs.nixpkgs-stable {
      system = prev.system;
      config.allowUnfree = true;
    };
  };
}
