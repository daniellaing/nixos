{inputs, ...}: {
  stable-packages = final: prev: {
    stable = import inputs.nixpkgs-stable {
      system = prev.system;
      config.allowUnfree = true;
    };
  };

  # Adds packages packaged in this flake
  additions = final: prev:
    import ../pkgs {pkgs = final;}
    // {
      scripts = import ../pkgs/scripts {pkgs = final;};
    };

  texmath-fix = final: prev: {
    haskellPackages = prev.haskellPackages.override {
      overrides = self: super: {
        texmath_0_12_8_12 = super.texmath_0_12_8_12.override {
          typst-symbols = self.typst-symbols_0_1_7;
        };
        typst_0_6_1 = super.typst_0_6_1.override {
          typst-symbols = self.typst-symbols_0_1_7;
        };
        skylighting_0_14_5 = super.skylighting_0_14_5.override {
          skylighting-core = self.skylighting-core_0_14_5;
        };
        pandoc_3_6 = super.pandoc_3_6.override {
          commonmark-extensions = self.commonmark-extensions_0_2_5_6;
          commonmark-pandoc = self.commonmark-pandoc_0_2_2_3;
          skylighting = self.skylighting_0_14_5;
          skylighting-core = self.skylighting-core_0_14_5;
        };
      };
    };
  };
}
