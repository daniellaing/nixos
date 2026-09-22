# Migrating `daniellaing/nixos` to the dendritic pattern

A step-by-step guide: what the pattern is, how to get there from *this* repo, and —
at the end of every step — a concrete example taken from your own configuration.

Reference material used throughout:

- The pattern itself: <https://github.com/mightyiam/dendritic>
- The author's own config (the reference implementation): <https://github.com/mightyiam/infra>
- Community book: <https://dendrix.denful.dev/Dendritic.html>
- Auto-importing: <https://github.com/denful/import-tree> (formerly `vic/import-tree`)
- `flake.modules`: <https://flake.parts/options/flake-parts-modules.html>

The migration is written as a **strangler fig**: the old path-based modules keep
working, wrapped behind throwaway aspects, and each step ends with a system that
still builds. Only step 9 deletes the scaffolding.

---

## 0. The pattern, and where it lands you

### 0.1 The rules

1. **One entry point.** `flake.nix` declares inputs and calls
   `flake-parts.lib.mkFlake`. It contains no configuration logic.
2. **Every other `.nix` file is a module of the *top-level* (flake-parts)
   configuration** — not a NixOS module, not a home-manager module. Its *type* is
   always known, so you never again have to ask "what's in this file?".
3. **One file = one feature ("aspect"), across all classes it applies to.**
   A single file may contribute to `flake.modules.nixos.<aspect>`,
   `flake.modules.homeManager.<aspect>`, `perSystem`, `flake.overlays`, … at once.
4. **Paths are free.** No literal path imports, no `imports = [./foo.nix]`
   bookkeeping, no directory convention that anything depends on. Files may be
   renamed, split, or re-nested at will.
5. **Lower-level configurations are option values**
   (`flake.modules.<class>.<name>`), *instantiated* exactly once, in a dedicated
   "wiring" module (e.g. `lib.nixosSystem` → `flake.nixosConfigurations`).
6. **No `specialArgs`/`extraSpecialArgs` pass-through.** Every file can read the
   top-level `config`, and every value a file defines can be read by any other
   file. Values are shared with `let` bindings or with options you declare
   yourself.

### 0.2 Vocabulary

| Term | Meaning |
| --- | --- |
| top-level module | a flake-parts module — i.e. almost every file in `modules/` |
| class | `nixos`, `homeManager`, `darwin`, `generic`, … It states which kind of evaluation a value is valid in. `generic` = valid anywhere. |
| aspect | a feature, named by an option under `flake.modules.<class>.<aspect>` |
| wiring / instantiation | the top-level module that turns aspect values into real configurations: `flake.nixosConfigurations.<host> = nixpkgs.lib.nixosSystem { … };` |
| `deferredModule` | the option type used to store modules. Multiple definitions of one aspect name merge as `imports`, so several files can contribute to the same aspect. |

### 0.3 What this fixes in *your* repo

| Today | After |
| --- | --- |
| `flake.nix` holds host instantiation, `mkHost`, overlays, templates, `perSystem`. | `flake.nix` is pure inputs + `mkFlake`. |
| `imports = [./dev.nix ./fonts.nix …]` in `cooked/nixos/default.nix`, `cooked/home-manager/default.nix`, `nixos/configuration.nix`, `daniel/default.nix`, … | Every file is picked up automatically; the `imports` lists disappear. |
| `modules/XF86.nix` (class-free option declarations) sits beside `modules/hyprpaper.nix` (a home-manager module), and `cooked/nixos/services/sound.nix` imports one of them. | `modules/xf86.nix` holds the cross-class feature; `modules/desktop/hyprpaper.nix` holds the HM one. Classes are explicit and checked. |
| NixOS→HM intent guessing: `builtins.any (cfg: cfg.programs.zsh.enable) (attrValues config.home-manager.users)` in `cooked/home-manager/{git,zsh}.nix`. | One aspect defines both the NixOS and the HM side; importing it *is* the intent. |
| `cooked.preload.desktop` and `cooked.<feature>.enable` flags with a cascade of `mkDefault true`. | The host aspect's `imports` list *is* the truth: `imports = [ …modules.nixos.desktop ];`. |
| `osConfig.XF86.audioLowerVolume` plumbing HM → NixOS. | The XF86 command table lives in one place and is used by both classes directly. |
| `lib.mkHomeUsers`, `users/<user>/default.nix`, `specialArgs = { inherit inputs; }`, `extraSpecialArgs = specialArgs`. | `flake.modules.homeManager.daniel` (an ordinary aspect) plus `home-manager.users.daniel.imports = [ … ];`. All three helpers get deleted. |
| `./hosts/${hostName}` interpolated into a module list. | `flake.nixosConfigurations = lib.mapAttrs (host: …) hosts;` — a table of machines. |

### 0.4 Target tree

```
flake.nix                       # inputs + mkFlake + import-tree ./modules
modules/
  flake-parts.nix               # systems, the flake.modules extra
  nixos-configurations.nix      # aspects -> flake.nixosConfigurations      (wiring)
  home-configurations.nix       # (optional) standalone HM configs          (wiring)
  flake-outputs.nix             # overlays / templates / lib                (flake-level)
  packages.nix                  # perSystem.packages   (imports ../pkgs)
  devshell.nix                  # perSystem.devShells  (imports ../shell.nix)

  system/{version,nixpkgs,nix,network,gnupg,fonts,dev,sops,scripts,home-manager}.nix
  system/{locate,dbus,printing,sound,display-manager}.nix
  system/{users,sudo,syncthing}.nix
  desktop/{desktop,hyprland,waybar,wofi,dunst,rofi,sxhkd,sxiv,picom,zathura,yazi,
           music,syncthing,browsers,hyprpaper}.nix
  terminal/{zsh,tmux,git,nix-index,R}.nix
  mail/{neomutt,accounts,pass}.nix
  user/daniel.nix               # account (nixos) + home (homeManager), one file
  hosts/{dellG5,wsl,server}.nix
  hosts/dellG5/_hardware.nix    # generated, ignored by import-tree
  xf86.nix                      # cross-class feature
  xf86/_options.nix             # ~180 option declarations, generic class

pkgs/ …                         # stays outside ./modules (callPackage files)
templates/ …
shell.nix                       # devshell definition, imported by modules/devshell.nix
secrets.yaml
```

An `_` anywhere in a path segment tells import-tree to skip that file (it also
skips everything that is not `*.nix`). That is the escape hatch for files that are
*not* top-level modules — see Appendix A.

### 0.5 Aspect map (current file → aspect)

| Current file | New aspect(s) | Class |
| --- | --- | --- |
| `flake.nix` → `mkHost` + `nixosConfigurations` | `modules/nixos-configurations.nix` (wiring) | — |
| `flake.nix` → name/revision/nixpkgs/overlays | `modules/system/{nixpkgs,version}.nix` + host aspects | nixos |
| `cooked/nixos/default.nix` ("common" + `preload`) | `modules/system/base.nix`, `modules/desktop/desktop.nix` | nixos |
| `cooked/nixos/{dev,fonts,gnupg,network,nix,sops,vm,scripts}.nix` | `flake.modules.nixos.<same name>` | nixos |
| `cooked/nixos/services/{dbus,locate,printing,sound,display-manager}.nix` | `flake.modules.nixos.<same name>` | nixos |
| `modules/XF86.nix` | `flake.modules.generic.xf86-options` | generic |
| `cooked/nixos/services/sound.nix` → `XF86 = {…}` + `daniel/XF86Misc.nix` | `flake.modules.homeManager.xf86` (`modules/xf86.nix`) | homeManager |
| `modules/hyprpaper.nix` | `flake.modules.homeManager.hyprpaper` | homeManager |
| `cooked/home-manager/git.nix` | `flake.modules.homeManager.git` | homeManager |
| `cooked/home-manager/tmux.nix` | `flake.modules.nixos.tmux` + `…homeManager.tmux` | both |
| `cooked/home-manager/zsh.nix` | `flake.modules.nixos.zsh` + `…homeManager.zsh` | both |
| `cooked/home-manager/nix-index.nix` | `flake.modules.nixos.nix-index` + `…homeManager.nix-index` | both |
| `cooked/home-manager/R.nix` | `flake.modules.nixos.R` + `…homeManager.R` | both |
| `cooked/home-manager/hyprland.nix` + `daniel/programs/wayland/hyprland.nix` | `flake.modules.nixos.hyprland` + `…homeManager.hyprland` | both |
| `nixos/configuration.nix` | `modules/system/{users,sudo,packages,syncthing}.nix`, split by feature | nixos |
| `nixos/email/*` | `flake.modules.nixos.mail` (+ HM neomutt aspect) | both |
| `hosts/<host>/default.nix` | `flake.modules.nixos.<host>` | nixos |
| `hosts/<host>/hardware.nix` | `modules/hosts/<host>/_hardware.nix`, imported by the host aspect | — |
| `hosts/wsl/home.nix` | `flake.modules.homeManager.git-svn` (in `modules/hosts/wsl.nix`) | homeManager |
| `users/<user>/**` + `daniel/**` | `flake.modules.{nixos,homeManager}.<user>` | both |
| `overlays/`, `pkgs/`, `lib/`, `templates/`, `shell.nix` | `modules/{flake-outputs,packages,devshell}.nix` | flake-parts |

> Names are yours to choose — they only ever matter to *you*. What matters is that
> each name maps to a feature, and that the same name is reused in every class
> that needs to be extended by that feature.

---

## Step 1 — Freeze a green baseline

**General.** A migration that changes the *structure* of a working system must
never silently change what it *builds*. Before touching anything: get on a branch,
make sure everything evaluates, and record the build result of each host so you can
prove equivalence later.

**Your config.**

```bash
git switch -c dendritic

# 1. does everything evaluate today?
nix flake check --keep-going

# 2. what does each host build to?
for h in dellG5 wsl server; do
  echo -n "$h "
  nix build ".#nixosConfigurations.$h.config.system.build.toplevel" \
    --no-link --print-out-paths
done | tee /tmp/before.txt
```

**Verify.** All three hosts build; `/tmp/before.txt` holds three store paths.

**Pitfall.** `nix flake check` builds `nixosConfigurations.*` as well, so it is the
cheapest full-tree smoke test you have. It stays valid all the way through the
migration — run it after every step.

---

## Step 2 — Turn `flake.nix` into an entry point

**General.** In the dendritic pattern the entry point is a *manifest*: inputs plus
one call to `mkFlake` that imports every top-level module. Nothing else. Everything
that used to live in the `outputs` function moves into modules, which are
auto-imported from a single directory by `import-tree`. Three consequences to
internalise immediately:

- **Every `.nix` file under that directory must be a top-level (flake-parts)
  module.** Files that are not — `callPackage` files, template flakes, plain
  helper functions — live outside the tree or are `_`-prefixed (Appendix A).
- **Relative paths change meaning as files move.** Because the pattern explicitly
  *wants* you to move files around, use a single root path instead: set
  `_module.args.rootPath = ./.;` in the entry module and write
  `rootPath + "/cooked"`. This is the convention mightyiam's own config uses.
- **The import root is a directory you choose.** Here it is `./modules` — which
  today already contains two files that are *not* top-level modules.

**Your config.**

First, get the two existing files in `modules/` out of the way of the auto-importer
(keep them importable by path, they are still needed by the old code):

```bash
git mv modules/XF86.nix      modules/_XF86.nix
git mv modules/hyprpaper.nix modules/_hyprpaper.nix

# and fix the only four importers (the files are reworked for good in step 7):
#   cooked/nixos/services/sound.nix:      imports = [../../../modules/_XF86.nix];
#   daniel/XF86Misc.nix:                  imports = [../modules/_XF86.nix];
#   daniel/programs/music.nix:            imports = [../../modules/_XF86.nix];
#   daniel/programs/wayland/hyprland.nix: imports = [../../../modules/_hyprpaper.nix];
```

`flake.nix` becomes:

```nix
{
  description = "Daniel's configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree"; # was github:vic/import-tree
    hyprland.url = "github:hyprwm/Hyprland";
    nix-colors.url = "github:misterio77/nix-colors";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:numtide/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    my_neovim = {
      url = "github:daniellaing/neovim";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      # Readable from every top-level module, so files can refer to repo-root
      # paths without depending on where the file itself lives.
      _module.args.rootPath = ./.;

      # Every .nix file under ./modules becomes a module of *this* configuration.
      imports = [(inputs.import-tree ./modules)];
    };
}
```

…and the old `outputs` body moves into modules, *verbatim* at first. The only
changes are identifier references (`self`/`pkgs` → `config`/`inputs`) and paths
(→ `rootPath`):

```nix
# modules/nixos-configurations.nix  (transitional — same behaviour as today)
{
  config,
  inputs,
  lib,
  rootPath,
  ...
}: let
  hosts = {
    dellG5.system = "x86_64-linux";
    wsl.system = "x86_64-linux";
    server.system = "x86_64-linux";
  };

  mkHost = hostName: {system}: let
    revision = inputs.self.shortRev or "dirty";
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      # `specialArgs = { inherit inputs; };` is temporary; step 6 removes it.
      specialArgs = {inherit inputs;};

      modules = [
        {
          networking.hostName = hostName;
          system = {
            configurationRevision = revision;
            nixos.label = revision;
          };
          nixpkgs = {
            overlays = [config.flake.overlays.default inputs.nur.overlays.default];
            config.allowUnfree = true;
          };
          home-manager = {
            useGlobalPkgs = true;
            extraSpecialArgs = {inherit inputs;};
            users = lib.optionalAttrs (builtins.elem hostName ["dellG5" "wsl"]) {
              daniel = import (rootPath + "/daniel");
            };
          };
        }

        # Still path-based. These keep working untouched and are strangled
        # one feature at a time in steps 4-7.
        (rootPath + "/cooked")
        (rootPath + "/hosts/${hostName}")
        (rootPath + "/nixos/configuration.nix")

        inputs.home-manager.nixosModules.home-manager
      ];
    };
in {
  flake.nixosConfigurations = lib.mapAttrs mkHost hosts;
}
```

```nix
# modules/flake-parts.nix
{inputs, ...}: {
  # flake-parts' extra that provides the class-checked `flake.modules.<class>.<aspect>`
  # options. Without this import, two files defining flake.modules produce
  # "The option `flake.modules' is defined multiple times".
  imports = [inputs.flake-parts.flakeModules.modules];

  # Only the systems you actually build for. (`nixpkgs.lib.systems.flakeExposed`
  # evaluates perSystem outputs for dozens of systems you never build.)
  systems = ["x86_64-linux"];
}
```

```nix
# modules/flake-outputs.nix  (the rest of the old `flake` attribute)
{
  inputs,
  rootPath,
  ...
}: {
  flake = {
    templates = import (rootPath + "/templates") inputs;
    overlays = import (rootPath + "/overlays") inputs;
    lib = import (rootPath + "/lib") inputs;
  };
}
```

```nix
# modules/packages.nix  (was the `perSystem` block in flake.nix)
{config, inputs, ...}: {
  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [config.flake.overlays.default];
    };

    packages = import ../pkgs pkgs;
  };
}
```

```nix
# modules/devshell.nix
{inputs, ...}: {
  imports = [inputs.devshell.flakeModule];

  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
    devshells = import ../shell.nix {inherit pkgs;};
  };
}
```

**Verify.**

```bash
nix flake check --keep-going
for h in dellG5 wsl server; do
  nix build ".#nixosConfigurations.$h.config.system.build.toplevel" --no-link --print-out-paths
done > /tmp/after-2.txt
nix store diff-closures $(cut -d' ' -f2 /tmp/before.txt) $(cut -d' ' -f2 /tmp/after-2.txt)
```

`diff-closures` should only report `configurationRevision`/label-induced changes.

**Pitfalls.**

- Paths: `./cooked` inside `modules/nixos-configurations.nix` would mean
  `modules/cooked`. Hence `rootPath + "/cooked"`. Same trap for
  `./hosts/${hostName}` and for `../../secrets.yaml` in
  `cooked/nixos/sops.nix` — the latter still works, because that file has not
  moved yet.
- Anything under `modules/` that is not a top-level module breaks evaluation at
  this step. `_XF86.nix` / `_hyprpaper.nix` above are that fix; keep the pattern
  in mind for every future helper file.

---

## Step 3 — Enable `flake.modules`, and separate wiring from content

**General.** Storage of lower-level modules is an *option*:
`flake.modules.<class>.<aspect>`, of type `lazyAttrsOf (lazyAttrsOf
deferredModule)`. Three things follow from that:

- **Classes are checked.** flake-parts tags every value with its class
  (`nixos`, `homeManager`, …). Loading a home-manager module into a NixOS
  configuration becomes a type error instead of a wall of "option does not
  exist". home-manager evaluates its modules with `class = "homeManager"`, which
  is why that bucket is spelled lower-camel-case.
- **Values merge.** Several files may define `flake.modules.nixos.base`; the
  definitions are merged as `imports`, i.e. as modules imported side by side.
  That is what makes incremental features possible later.
- **Instantiation is separate.** Aspects are only *values*; nothing becomes a
  configuration until your wiring module calls `lib.nixosSystem`. Instantiate
  once per host, and describe hosts with data rather than code.

**Your config.** While migrating, wrap the old path-based trees in throwaway
aspects so hosts can already be expressed as compositions. This file lives *inside*
the import root on purpose (it must be found by import-tree) and is deleted in
step 9:

```nix
# modules/hosts-transitional.nix  — DELETE IN STEP 9
{
  config,
  inputs,
  rootPath,
  ...
}: let
  flakeModules = config.flake.modules;
in {
  # The old trees, wrapped so hosts can be composed by name.
  flake.modules.nixos.cooked = { ... }: {
    imports = [(rootPath + "/cooked")];
  };

  flake.modules.nixos.daniel-old = { ... }: {
    imports = [(rootPath + "/nixos/configuration.nix")];
  };

  # This was the `home-manager = { … };` block inside mkHost: machines with a
  # human user. Gone in step 6, where the user aspect takes over.
  flake.modules.nixos.human = { ... }: {
    home-manager = {
      useGlobalPkgs = true;
      extraSpecialArgs = {inherit inputs;};
      users.daniel = import (rootPath + "/daniel");
    };
  };

  flake.modules.nixos.dellG5 = {
    imports = [
      flakeModules.nixos.cooked
      flakeModules.nixos.daniel-old
      flakeModules.nixos.human
      (rootPath + "/hosts/dellG5")
    ];
  };

  flake.modules.nixos.wsl = {
    imports = [
      flakeModules.nixos.cooked
      flakeModules.nixos.daniel-old
      flakeModules.nixos.human
      (rootPath + "/hosts/wsl")
    ];
  };

  flake.modules.nixos.server = { ... }: {
    imports = [
      flakeModules.nixos.cooked
      (rootPath + "/hosts/server")
    ];
  };
}
```

…and the wiring collapses to a table plus three lines:

```nix
# modules/nixos-configurations.nix
{
  config,
  inputs,
  lib,
  ...
}: let
  hosts = {
    dellG5.system = "x86_64-linux";
    wsl.system = "x86_64-linux";
    server.system = "x86_64-linux";
  };
in {
  flake.nixosConfigurations = lib.mapAttrs (
    hostName: {system}:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;

        # Still needed while path-based modules remain: they read `inputs` from
        # their arguments. This line is deleted in step 9, when nothing is
        # imported by path any more.
        specialArgs = {inherit inputs;};

        # The host aspect is the single source of truth for that machine:
        # it imports everything the machine is made of.
        modules = [config.flake.modules.nixos.${hostName}];
      }
  ) hosts;
}
```

**Verify.** `nix flake check` again — this time it exercises the new
`flake.modules` path — plus:

```bash
nix eval .#nixosConfigurations.server.config.networking.hostName
nix eval .#nixosConfigurations.dellG5.config.services.locate.enable
```

**Pitfalls.**

- Top-level `imports` **cannot** read `config`: `imports = [config.flake.modules…]`
  in a flake-parts module is the classic infinite recursion ("if you get an
  infinite recursion here, you probably reference `config` in `imports`"). Compose
  inside the *aspect value*, as above, or inside the inner module's `imports`.
- Never let an aspect import itself (`flake.modules.nixos.x` importing
  `flakeModules.nixos.x`) — same infinite recursion.
- `_class` mismatch: a `flake.modules.homeManager.*` value can only be consumed
  inside a home-manager evaluation. `flake.modules.generic.*` is the class-free
  bucket for modules that are valid anywhere.

---

## Step 4 — Convert leaf features into aspects, one commit each

**General.** This is the bulk of the work and it is mechanical:

1. create `modules/<topic>/<feature>.nix` with `flake.modules.<class>.<feature> = …`;
2. add it to the composition, and delete the old file **and** the
   `imports = [./that-file.nix]` line that pulled it in;
3. delete its `enable` option, plus the `mkDefault true` that preloaded it —
   *importing the aspect is the enable switch*;
4. rebuild.

Dropping `mkEnableOption` is the point of the pattern, not a side effect: an
`enable` flag exists only because a module is imported whether you want it or not.
Aspects are imported on purpose.

**Your config.** The simplest one first — `cooked/nixos/services/locate.nix`
becomes:

```nix
# modules/system/locate.nix
{
  # No `enable`, no `mkIf`, no option declaration: one feature, one file.
  flake.modules.nixos.locate = {
    services.locate = {
      enable = true;
      interval = "hourly";
      pruneBindMounts = true;
    };
  };
}
```

and `cooked/nixos/nix.nix` becomes:

```nix
# modules/system/nix.nix
{
  flake.modules.nixos.nix = {
    nix = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
        use-xdg-base-directories = true;
        trusted-users = ["root" "@wheel"];
      };
      optimise = {
        automatic = true;
        dates = ["13:00" "20:00"];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
    };
  };
}
```

The one that needs `inputs` and a repo-root path — `cooked/nixos/sops.nix` —
becomes:

```nix
# modules/system/sops.nix
{
  inputs,
  rootPath,
  ...
}: {
  flake.modules.nixos.sops = {config, ...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      defaultSopsFile = rootPath + "/secrets.yaml";
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/daniel/.config/sops/age/keys.txt";
    };
  };
}
```

Note where `inputs` and `rootPath` come from: the **top-level** module's arguments,
captured in the aspect's closure. No `specialArgs` involved. During the migration,
add the new aspects to the transitional wrapper and delete the old file in the same
commit:

```nix
  flake.modules.nixos.cooked = { ... }: {
    imports = [
      config.flake.modules.nixos.locate
      config.flake.modules.nixos.nix
      config.flake.modules.nixos.sops
      # … one line per converted feature, while the rest still comes from
      # (rootPath + "/cooked")
    ];
  };
```

**Verify.**

```bash
nix flake check --keep-going
nix eval .#nixosConfigurations.dellG5.config.services.locate.enable          # true
nix eval .#nixosConfigurations.wsl.config.nix.settings.auto-optimise-store   # true
```

**Pitfalls.**

- `inputs`/`rootPath` must be taken from the **outer** module. Do not list them in
  the inner function's arguments: a NixOS module has no `inputs` argument unless
  you pass `specialArgs`.
- Shadowing: inside `flake.modules.nixos.foo = {config, …}: …`, `config` is the
  *NixOS* config. If you need the flake-parts one, bind it outside the inner
  function: `let flakeModules = config.flake.modules; in …`.
- Every `cooked.<feature>.enable` flag that other files read must be deleted in the
  same commit as the file that declares it.

---

## Step 5 — Compose hosts out of aspects

**General.** A host is just another aspect: `flake.modules.nixos.<host>` imports the
aspects the machine is made of. Two rules keep this clean:

- **Compose, don't flag.** `cooked.preload.desktop = true` becomes
  `imports = [ …nixos.desktop ];`. The same goes for the "common" preload block:
  turn it into a `base` aspect — the pattern's README explicitly recommends merging
  several non-distinct modules under one name instead of growing the same long
  import list at every use site.
- **Generated or path-imported files are fine as exceptions**, but must not be
  auto-imported as top-level modules (their options `boot.*`, `fileSystems.*` do
  not exist in the flake-parts class). Put them next to the aspect as `_name.nix`
  — import-tree skips any path containing `/_` — and import them relatively.

**Your config.** While a host is only half-converted, its aspect carries both the
new aspect imports and `(rootPath + "/hosts/<host>")`; that path import is dropped
as soon as the old host file's contents have all been converted (the last piece,
`lib.mkHomeUsers`, goes in step 6).

```nix
# modules/system/version.nix — was the `system.nixos.label` block inside mkHost
{inputs, ...}: {
  flake.modules.nixos.version = {
    system.configurationRevision = inputs.self.shortRev or "dirty";
    system.nixos.label = inputs.self.shortRev or "dirty";
  };
}
```

```nix
# modules/system/nixpkgs.nix — was the `nixpkgs = {…}` block inside mkHost
{config, inputs, ...}: {
  flake.modules.nixos.nixpkgs = {
    nixpkgs = {
      overlays = [config.flake.overlays.default inputs.nur.overlays.default];
      config.allowUnfree = true;
    };
  };
}
```

```nix
# modules/system/base.nix — was `cooked/nixos/default.nix`, minus the enable flags
{config, ...}: let
  flakeModules = config.flake.modules;
in {
  flake.modules.nixos.base = {pkgs, ...}: {
    imports = with flakeModules.nixos; [
      version
      nixpkgs
      nix
      network
      gnupg
      fonts
      dev
      dbus
      locate
      sops
      scripts
      home-manager
    ];

    environment.systemPackages = with pkgs; [ripgrep unzip wget];

    time.timeZone = "Europe/London";
    i18n = let
      locale = "en_GB.UTF-8";
    in {
      defaultLocale = locale;
      extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale;
        LC_MEASUREMENT = locale;
        LC_MONETARY = locale;
        LC_NAME = locale;
        LC_NUMERIC = locale;
        LC_PAPER = locale;
        LC_TELEPHONE = locale;
        LC_TIME = locale;
      };
    };
    console.keyMap = "uk";
  };
}
```

```nix
# modules/desktop/desktop.nix — was `cooked.preload.desktop`
{config, ...}: let
  flakeModules = config.flake.modules;
in {
  flake.modules.nixos.desktop = {
    imports = with flakeModules.nixos; [
      display-manager
      printing
      sound
      vm
      hyprland
    ];
  };
}
```

```nix
# modules/hosts/dellG5.nix
{config, ...}: let
  flakeModules = config.flake.modules;
in {
  flake.modules.nixos.dellG5 = {pkgs, ...}: {
    imports = [
      ./dellG5/_hardware.nix # nixos-generate-config output; skipped by import-tree
      flakeModules.nixos.base
      flakeModules.nixos.daniel # ← defined in step 6
      flakeModules.nixos.desktop
    ];

    networking.hostName = "dellG5";
    system.stateVersion = "23.05"; # Do not change.

    boot.loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        extraEntries = ''
          menuentry "Reboot" {
            reboot
          }

          menuentry "Shut Down" {
            halt
          }
        '';
        theme = pkgs.stdenv.mkDerivation rec {
          pname = "distro-grub-themes";
          version = "3.1";
          src = pkgs.fetchFromGitHub {
            owner = "AdisonCavani";
            repo = "distro-grub-themes";
            rev = "v${version}";
            hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
          };
          installPhase = "cp -r customize/nixos $out";
        };
      };
    };
  };
}
```

**Verify.** `nix flake check`, then rebuild the machine you are on:

```bash
nixos-rebuild switch --flake .#dellG5     # or: nh os switch .#dellG5
nixos-rebuild build --flake .#wsl
nixos-rebuild build --flake .#server
```

**Pitfalls.**

- `system.stateVersion` is per host — keep it in the host aspect, never in `base`.
- If two aspects define the same option, that is a *conflict*, not a merge. Use
  `lib.mkDefault` in the general aspect and a plain definition in the specific one.
- `_hardware.nix` must stay `_`-prefixed forever: rename it to `hardware.nix` and
  import-tree will try to evaluate it as a top-level module, and the flake stops
  evaluating.

---

## Step 6 — Home-manager: users are aspects too

**General.** home-manager evaluates its modules with `class = "homeManager"`, so
`flake.modules.homeManager.<aspect>` is the correct bucket — and it is checked.
Nesting inside NixOS is just importing an HM aspect from a NixOS aspect:

```nix
home-manager.users.daniel.imports = [ config.flake.modules.homeManager.daniel ];
```

That single line replaces `lib.mkHomeUsers`, `extraSpecialArgs`, the
`users/<user>` directory convention, and `home-manager.sharedModules`. Three
consequences:

- Values shared between the system and the user side no longer need
  `osConfig`/`specialArgs` — the aspect owning both sides simply uses both.
- `home-manager.sharedModules` stops being how a *host* tweaks a user. The host
  aspect adds an HM aspect to that user's `imports` instead.
- Per-user opt-in stops being a flag (`cooked.zsh.enable = true`). The user aspect
  imports what the user wants.

**Your config.** The `builtins.any (cfg: …) (attrValues config.home-manager.users)`
hack in `cooked/home-manager/zsh.nix` disappears: the two sides of "the user wants
zsh" are now one file.

```nix
# modules/terminal/zsh.nix
{config, ...}: let
  flakeModules = config.flake.modules;
in {
  # ── machine side ────────────────────────────────────────────────────────
  flake.modules.nixos.zsh = {pkgs, ...}: {
    programs.zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      promptInit = "source ''${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
    environment = {
      systemPackages = builtins.attrValues {inherit (pkgs) zsh-powerlevel10k;};
      shells = [pkgs.zsh];
      pathsToLink = ["/share/zsh"];
    };
  };

  # ── user side ───────────────────────────────────────────────────────────
  flake.modules.homeManager.zsh = {config, ...}: let
    dotDir = "${config.xdg.configHome}/zsh";
  in {
    programs.zsh = {
      inherit dotDir;
      enable = true;
      autosuggestion.enable = true;
      defaultKeymap = "viins";
      enableVteIntegration = true;
      history.path = "${config.xdg.stateHome}/zsh/zsh_history";
      envExtra = ''
        # ---   Colour man pages   ---
        export LESS_TERMCAP_mb=$'\e[1;32m'
        export LESS_TERMCAP_md=$'\e[1;32m'
        export LESS_TERMCAP_me=$'\e[0m'
      '';
      initContent = ''
        # Set prompt
        [[ ! -f ${dotDir}/.p10k.zsh ]] || source ${dotDir}/.p10k.zsh

        setopt autocd
        setopt autopushd

        compinit -d ${config.xdg.cacheHome}/zsh/zcompdump-"$ZSH_VERSION"
      '';
    };
  };
}
```

The user aspect itself — one file owning *both* the account and the home, replacing
`users/daniel/{default,programs}.nix` **and** `daniel/**`:

```nix
# modules/user/daniel.nix
{config, inputs, ...}: let
  flakeModules = config.flake.modules;
  user = "daniel";

  tmuxConf = ''
    # Vim keys for pane navigation
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Enable passthrough
    set -g allow-passthrough on
  '';
in {
  # ── machine side ────────────────────────────────────────────────────────
  flake.modules.nixos.${user} = {pkgs, ...}: {
    # The system-side features this user's setup requires:
    imports = with flakeModules.nixos; [
      zsh
      hyprland
      nix-index
      R
    ];

    users.users.${user} = {
      isNormalUser = true;
      description = "Daniel Laing";
      shell = pkgs.zsh;
      extraGroups = [
        "video"
        "networkmanager"
        "wheel"
        "adbusers"
        "libvirtd"
        "syncthing"
      ];
    };

    # The whole bridge between the two classes:
    home-manager.users.${user}.imports = [flakeModules.homeManager.${user}];
  };

  # ── user side ───────────────────────────────────────────────────────────
  flake.modules.homeManager.${user} = {config, pkgs, ...}: {
    imports =
      [inputs.nix-colors.homeManagerModules.default]
      ++ (with flakeModules.homeManager; [
        zsh
        git
        tmux
        R
        nix-index
        hyprland
        waybar
        wofi
        dunst
        zathura
        yazi
        syncthing
        browsers
        hyprpaper
      ]);

    colorScheme = inputs.nix-colors.colorSchemes.gruvbox-material-dark-medium;

    home = {
      username = user;
      homeDirectory = "/home/${user}";
      stateVersion = "23.05";
      packages = builtins.attrValues {
        inherit
          (pkgs)
          btop
          yt-dlp
          keepassxc
          pipes
          vimix-icon-theme
          ffmpeg-full
          imv
          vimv
          steam
          alegreya
          alegreya-sans
          ;
      };
      pointerCursor = {
        enable = true;
        gtk.enable = true;
        package = pkgs.vimix-cursors;
        name = "Vimix-white-cursors";
      };
    };

    programs.home-manager.enable = true;

    # Personal tmux config; modules/terminal/tmux.nix only sets the defaults.
    xdg.configFile."tmux/tmux.conf".text = tmuxConf;

    programs.git = {
      settings = {
        user.email = "daniel@daniellaing.com";
        user.name = "Daniel Laing";
      };
      signing = {
        key = "08218B96DC7385E5BB7CA535D2643BD213BC0FA8";
        signByDefault = true;
      };
    };

    xdg = {
      enable = true;
      userDirs = {
        enable = true;
        createDirectories = true;
        documents = "${config.home.homeDirectory}/archive";
        download = "${config.home.homeDirectory}/downloads";
        # …
      };
    };
  };
}
```

…and the per-host user tweak that used to be `hosts/wsl/home.nix` +
`home-manager.sharedModules` is now a three-line HM aspect inside the host file:

```nix
# modules/hosts/wsl.nix
{
  config,
  inputs,
  ...
}: let
  flakeModules = config.flake.modules;
in {
  flake.modules.nixos.wsl = {config, lib, pkgs, ...}: {
    imports = [
      inputs.nixos-wsl.nixosModules.default
      flakeModules.nixos.base
      flakeModules.nixos.daniel
    ];

    networking.hostName = "wsl";
    system.stateVersion = "23.05"; # Do not change.

    wsl = {
      enable = true;
      defaultUser = "daniel";
      startMenuLaunchers = true;
    };

    networking.nftables.enable = lib.mkForce false;

    sops.secrets.svn-passwd = {
      owner = config.users.users.daniel.name;
      group = config.users.users.daniel.group;
    };

    # WSL-only home-manager tweak: git with SVN support.
    home-manager.users.daniel.imports = [flakeModules.homeManager.git-svn];
  };

  flake.modules.homeManager.git-svn = {pkgs, ...}: {
    programs.git.package = pkgs.stable.gitSVN;
  };
}
```

**Verify.**

```bash
nix eval .#nixosConfigurations.dellG5.config.home-manager.users.daniel.home.username
nix eval .#nixosConfigurations.dellG5.config.home-manager.users.daniel.programs.zsh.enable
nixos-rebuild switch --flake .#wsl
```

**Pitfalls.**

- A `flake.modules.homeManager.*` value imported somewhere other than inside
  `home-manager.users.<name>` is a class mismatch — a type error by design. Use
  `generic` for modules that must be valid in both classes.
- HM-only values (`config.programs.terminal`, `config.colorScheme`) exist only
  inside the inner HM function; the NixOS side of the same file cannot read them.
  Conversely, the NixOS side of a file that also defines an HM aspect cannot use
  the inner HM `config`.

---

## Step 7 — Cross-cutting features: the XF86 example

**General.** The pattern's answer to "values that span classes" is *not*
`specialArgs`. It is:

1. a `let` binding in the file that owns the feature (`let`-bound values can
   themselves be functions of the *class-local* arguments — that is how one value
   can be used with each class's own `pkgs`), or
2. an option **you declare** at the top level — `options.<something> =
   lib.mkOption { … };` — and read from other files. The pattern's README calls
   using only pre-existing options (like `flake.modules`) for storage an
   anti-pattern: declaring your own options is how your mental model becomes code.

Option (2) also works for *modules as values*, which is how you hand a piece of
configuration on by name:

```nix
# modules/nixos/base.nix
{lib, ...}: {
  options.nixos.base = lib.mkOption {type = lib.types.deferredModule;};
}

# modules/nixos/pc.nix
{config, lib, ...}: {
  options.nixos.pc = lib.mkOption {type = lib.types.deferredModule;};
  config.nixos.pc = config.nixos.base;   # "pc is a base, plus whatever else"
}
```

**Your config.** Today: `modules/XF86.nix` declares ~180 options;
`cooked/nixos/services/sound.nix` defines the audio ones *in NixOS*;
`daniel/{XF86Misc,programs/music}.nix` define the rest *in HM*; and the HM
consumers have to reach across with `osConfig.XF86.audioLowerVolume`
(`daniel/programs/wayland/hyprland.nix`) and `osConfig.XF86.audioMute`
(`daniel/programs/wayland/waybar.nix`). In dendritic form that is one file:

```nix
# modules/xf86.nix
{config, ...}: let
  flakeModules = config.flake.modules;

  # The genuinely shared part: a function of the *class-local* arguments, so
  # whichever class instantiates it gets its own `pkgs` and `config`.
  # (Today only home-manager does: the keys are consumed by HM keybindings, and
  # some entries read `programs.terminal`, which is an HM option.)
  commands = {
    config,
    pkgs,
    ...
  }: {
    terminal = "${config.programs.terminal}";
    calculator = "${config.programs.terminal} ${pkgs.bc}/bin/bc";
    explorer = "${config.programs.terminal} ${pkgs.yazi}/bin/yazi";
    mail = "${config.programs.terminal} ${pkgs.neomutt}/bin/neomutt";
    music = "${config.programs.terminal} ${pkgs.ncmpcpp}/bin/ncmpcpp";
    WWW = "$BROWSER";

    audioLowerVolume = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
    audioMute = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    audioRaiseVolume = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
    audioPlay = "${pkgs.playerctl}/bin/playerctl play-pause";
    audioNext = "${pkgs.playerctl}/bin/playerctl next";
    audioPrev = "${pkgs.playerctl}/bin/playerctl previous";
  };
in {
  # Class-free: the ~180 option declarations work in any class.
  flake.modules.generic.xf86-options = ./xf86/_options.nix;

  # Class-specific: the commands are consumed by home-manager keybindings
  # (hyprland, sxhkd, waybar), so this is where they belong.
  flake.modules.homeManager.xf86 = { ... } @ args: {
    imports = [flakeModules.generic.xf86-options];
    XF86 = commands args;
  };
}
```

Consumers then read their *own* class's values, and the `osConfig` hop is gone:

```nix
# modules/desktop/hyprland.nix — home-manager side
{
  flake.modules.homeManager.hyprland = {config, ...}: {
    wayland.windowManager.hyprland.extraConfig = ''
      bind = $MOD, Return, exec, ${config.XF86.terminal}
      bind = $MOD, M, exec, ${config.XF86.music}
      bind =, XF86AudioLowerVolume, exec, ${config.XF86.audioLowerVolume}
      bind =, XF86AudioMute, exec, ${config.XF86.audioMute}
      bind =, XF86AudioRaiseVolume, exec, ${config.XF86.audioRaiseVolume}
    '';
  };
}
```

`cooked/nixos/services/sound.nix` keeps only the pipewire/wireplumber configuration
and drops its `XF86 = {…}` block and its `imports = [../../../modules/_XF86.nix]`.
`daniel/XF86Misc.nix`, `daniel/programs/music.nix` and `modules/_XF86.nix` all
disappear into `modules/xf86.nix` + `modules/xf86/_options.nix`, and the two
`osConfig.XF86.…` references become plain `config.XF86.…`.

**Verify.** Rebuild dellG5, then press the volume keys — or:

```bash
nix eval --raw .#nixosConfigurations.dellG5.config.home-manager.users.daniel.XF86.audioMute
nix eval .#nixosConfigurations.dellG5.config.home-manager.users.daniel.XF86 | head
```

**Pitfalls.**

- `let`-bound values are evaluated once, when the module is *constructed*. That is
  fine for constants and for thunks reading top-level options, but never
  self-referential.
- A `generic` aspect is untagged, so the same module can be imported in both
  classes. If you want a `nixos`-tagged module inside HM, the value is probably
  generic and belongs somewhere else.

---

## Step 8 — Packages, overlays, lib, devshells, templates

**General.** Not everything is a class module, and the pattern says so explicitly
("fanaticism" is listed as an anti-pattern): `callPackage` files, template flakes
and shell definitions stay ordinary Nix files, pulled in by top-level modules that
publish them as flake outputs (`flake.overlays`, `perSystem.packages`,
`perSystem.devShells`, `flake.templates`).

The only thing to get right is *where those files live*:

- **outside** the auto-imported directory (`pkgs/`, `templates/`, `shell.nix` —
  as today), or
- **inside it with an `_` in the path** (`modules/mail/_sync-email.nix`), or
- inside it with a suffix excluded by the filter —
  `(inputs.import-tree ./modules).filterNot (lib.hasSuffix ".pkg.nix")`, the
  naming scheme the pattern's README suggests for packages.

**Your config.** `overlays/default.nix` becomes one top-level module — replace the
`overlays = import (rootPath + "/overlays") inputs;` line from step 2 with this
file, and let `modules/flake-outputs.nix` keep doing `templates`. Identifiers change
from "arg names" to `inputs.*`; nothing else does:

```nix
# modules/overlays.nix   (replaces overlays/default.nix)
{inputs, rootPath, ...}: {
  flake.overlays.default = inputs.nixpkgs.lib.composeManyExtensions [
    # Stable packages
    (final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
        overlays = [];
      };
    })

    # Packages packaged in this flake
    (final: prev: import (rootPath + "/pkgs") {pkgs = final;})

    # my_neovim
    (final: prev: {
      my_neovim = inputs.my_neovim.packages.${prev.stdenv.hostPlatform.system}.default;
    })

    # ffmpeg with unfree libs
    (final: prev: {
      ffmpeg-full =
        (prev.ffmpeg-full.override {withUnfree = true;}).overrideAttrs (_: {
          doCheck = false;
        });
    })
  ];
}
```

> Compose overlays in **one** module: flake-parts documents that overlays are not
> mergeable, because their order matters. If you want per-feature overlays, expose
> them as `flake.overlays.<name>` and compose them explicitly where you set
> `nixpkgs.overlays`.

`pkgs/`, `shell.nix` and `templates/` stay exactly where they are; only the
*references* move into modules (see step 2 for `packages.nix` and `devshell.nix`):

```nix
# modules/templates.nix
{inputs, rootPath, ...}: {
  flake.templates = import (rootPath + "/templates") inputs;
}
```

The leftovers of `lib/`: its only content is `mkHomeUsers`, which the pattern makes
unnecessary — delete `lib/` and the `flake.lib` output. If you ever want extra lib
functions, `flake.lib.default = inputs.nixpkgs.lib.composeManyExtensions [ … ];`
still works and is picked up in the wiring module with
`lib = inputs.nixpkgs.lib.extend config.flake.lib.default;`.

**Verify.**

```bash
nix build .#configure .#power-menu .#stag     # the pkgs/ outputs
nix flake show
nix develop
```

**Pitfalls.**

- Do **not** put `templates/rust/flake.nix` or `pkgs/*/default.nix` inside
  `modules/` without a filter: they would be parsed as top-level modules.
- `nixos/email/{sync-email,get-mailboxes,neomutt-account-switcher}.nix` are
  `writeShellScriptBin` files, not modules. Rename them
  `modules/mail/_{sync-email,get-mailboxes,neomutt-account-switcher}.nix` and call
  them from the mail aspect: `(import ./mail/_sync-email.nix {inherit pkgs;})`.
- Same for `daniel/shell/aliases.nix` (`{lib, pkgs}: {…}`) and
  `daniel/programs/browsers/bookmarks.nix` (`inputs: {…}`), which become
  `modules/terminal/_aliases.nix` and `modules/desktop/browsers/_bookmarks.nix`.

---

## Step 9 — Delete the scaffolding

**General.** A migration is finished when the temporary bridges are gone; leaving
them is how "a dendritic repo with a `cooked/` directory" becomes permanent
confusion.

**Your config.** Delete:

```
cooked/                      # all aspects now live under modules/
users/                       # -> modules/user/daniel.nix
nixos/                       # -> modules/system/*, modules/user/daniel.nix, modules/mail/*
hosts/                       # -> modules/hosts/* (+ modules/hosts/<host>/_hardware.nix)
daniel/                      # -> modules/user/daniel.nix, modules/{desktop,terminal,mail}/*
modules/_XF86.nix            # -> modules/xf86.nix + modules/xf86/_options.nix
modules/_hyprpaper.nix       # -> modules/desktop/hyprpaper.nix
modules/hosts-transitional.nix
lib/                         # mkHomeUsers is gone
overlays/default.nix         # now modules/overlays.nix
```

…and remove from the wiring module everything the aspects now own: `specialArgs`,
`extraSpecialArgs`, `lib.mkHomeUsers`, the `users = lib.optionalAttrs …` block, and
the `networking.hostName` / `system.*` / `nixpkgs.*` blocks. What is left is step
3's `flake.nixosConfigurations` and nothing else.

Update `.github/workflows/verify_configurations.yml` only if host names changed
(it derives its matrix from `nix flake show --json`, which still works). Two
optional tidy-ups while you are there:

```yaml
      - name: Check flake
        run: nix flake check --keep-going     # already present; it now exercises every aspect
```

```yaml
      - name: Format
        run: nix fmt -- --check .             # modules/devshell.nix sets formatter = alejandra
```

Finally, replace the `## Refactor` section of `README.md` (which, at the time of
writing, just links to this guide) with the rules of the pattern — "every file is
a flake-parts module", "names are features", "no literal path imports", "`_`
prefix = not a module".

**Verify.**

```bash
nix flake check --keep-going
rg -n '^\s*imports = \[' modules/ | rg -v 'flakeModules|inputs\.|_hardware|migrations'
```

Any remaining hit that is neither a relative path to a generated file nor a
class-free option module is a leftover from the old world.

---

## Step 10 — Working in the pattern from now on

**Add a feature.** Create `modules/<topic>/<name>.nix`; reference it from the
aspects that need it. No import lists anywhere.

**Add a host.** Add one entry to the `hosts` table in
`modules/nixos-configurations.nix`, and create `modules/hosts/<name>.nix` with
`flake.modules.nixos.<name>`. Two small files, no boilerplate.

**Add a capability to an existing feature.** Create
`modules/<topic>/<name>-advanced.nix` contributing to the *same* aspect name —
`deferredModule` merges it in:

```nix
# modules/desktop/hyprland-advanced.nix
{
  flake.modules.homeManager.hyprland = {
    wayland.windowManager.hyprland.settings.animations.enabled = false;
  };
}
```

Both files now extend `flake.modules.homeManager.hyprland`; any host importing that
aspect gets both, and the feature cannot accidentally be left half-enabled.

**Share a value.** A `let` binding if one file owns it; your own top-level option
if several files need it. Never `specialArgs`.

**Debug.**

```bash
nix flake show --json | jq '.nixosConfigurations | keys'
nix eval .#nixosConfigurations.dellG5.config.system.build.toplevel.drvPath
nix repl -f flake.nix    # then:  :lf .  and  config.flake.modules.nixos.dellG5
```

Add `debug = true;` at the top level to expose `debug`, `allSystems` and
`currentSystem` on the flake output for inspection in `nix repl`.

**Optional next steps in the ecosystem.**

- `denful/flake-file` — generate `flake.nix` itself, so each aspect declares the
  inputs it needs (`flake-file.inputs.nixvim.url = "…";`) and `flake.nix` is never
  hand-edited again. `mightyiam/infra` does exactly this.
- `denful/with-inputs`, `denful/dendrix` — helpers and a catalogue of community
  dendritic configs.
- `flake-aspects` — if you prefer `flake.aspects.<aspect>.<class>` nesting over
  `flake.modules.<class>.<aspect>`.

**Standing rules (the ones that actually bite).**

1. A file under the import root that is not a top-level module breaks evaluation —
   unless it is `_`-prefixed or filtered out.
2. Top-level `imports` must not read `config`; compose inside the aspect value or
   the inner module.
3. Never let an aspect import itself.
4. `homeManager` values only inside home-manager evaluations; `generic` when in
   doubt.
5. Two aspects defining the same option conflict, unless one is `mkDefault`/`mkForce`.
6. Paths: `rootPath + "/…"`, or a path relative to the *module file* — never a path
   relative to where the logic used to live.

---

## Appendix A — files that must stay outside the auto-imported tree

| File(s) | Why | Where it goes |
| --- | --- | --- |
| `pkgs/*/default.nix`, `pkgs/stag.nix` | `callPackage` files | keep `pkgs/` (imported by `modules/packages.nix`) |
| `nixos/email/{sync-email,get-mailboxes,neomutt-account-switcher}.nix` | `writeShellScriptBin` with a `pkgs` argument | `modules/mail/_*.nix`, imported by the mail aspect |
| `daniel/shell/aliases.nix` | `{lib, pkgs}: {…}` helper | `modules/terminal/_aliases.nix` |
| `daniel/programs/browsers/bookmarks.nix` | `inputs:`-taking helper | `modules/desktop/browsers/_bookmarks.nix` |
| `hosts/<host>/hardware.nix` | generated NixOS module | `modules/hosts/<host>/_hardware.nix` |
| `templates/**` (incl. `rust/flake.nix`) | template flakes | keep `templates/` |
| `shell.nix`, `overlays/default.nix`, `lib/default.nix` | plain functions | stay, or fold into `modules/flake-outputs.nix` / `modules/devshell.nix` |
| `secrets.yaml`, wallpapers, neomutt rc files | not Nix | import-tree only picks up `*.nix` |

## Appendix B — cheat sheet

```nix
# top-level module skeleton
{config, inputs, rootPath, ...}: let
  flakeModules = config.flake.modules;  # outer config, captured before inner modules shadow `config`
in {
  # class modules
  flake.modules.nixos.<feature> = <module>;        # attrset | function | path
  flake.modules.homeManager.<feature> = <module>;
  flake.modules.generic.<feature> = <module>;      # valid in any class

  # a configuration (wiring; done once per host)
  flake.nixosConfigurations.<host> =
    inputs.nixpkgs.lib.nixosSystem {modules = [config.flake.modules.nixos.<host>];};

  # extra flake-parts modules
  imports = [inputs.home-manager.nixosModules.home-manager];

  # per-system outputs
  perSystem = {pkgs, ...}: {packages.<name> = pkgs.hello;};
}
```

| You want | Write |
| --- | --- |
| this option only on host X | define it in `flake.modules.nixos.X` |
| this option on every host | define it in `flake.modules.nixos.base`, imported by each host aspect |
| override a general value on one host | `lib.mkForce` in the host aspect, `lib.mkDefault` in the general aspect |
| the same module in NixOS *and* HM | `flake.modules.generic.<name>`, imported by both aspects |
| a value from the NixOS side inside HM | put it in the aspect that owns both; `osConfig`/`specialArgs` are unnecessary |
| a helper file inside `modules/` | prefix `_`, or filter by suffix |
| several files extending one feature | give them the same aspect name; `deferredModule` merges them |

## Appendix C — reference configs to steal from

- `mightyiam/infra` — `flake.nix` + `outputs.nix` (two files!) and `modules/` for
  everything else; also demonstrates `_` exclusions, `.pkg.nix` filtering,
  `_module.args.rootPath`, and `flake-file`.
- `vic/vix`, `drupol/infra`, `GaetanLepage/nix-config` — other real dendritic
  trees, listed in the pattern's README.
- Dendrix book, "Dendritic Nix" chapter — the aspect-oriented framing.
ther real dendritic
  trees, listed in the pattern's README.
- Dendrix book, "Dendritic Nix" chapter — the aspect-oriented framing.
