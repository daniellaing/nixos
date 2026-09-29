# Migrating `daniellaing/nixos` to the dendritic pattern

### A step-by-step guide

*Report 2 of 2 · prepared 2026-09-29 · starting point: branch `dendritic`, commit `0e29b82`.
Report 1, [`01-birds-eye-view.md`](01-birds-eye-view.md), explains the pattern and the example repositories. This guide assumes you have read its §0 to §2. A companion note, [`03-config-notes.md`](03-config-notes.md), covers findings about your repository that are unrelated to the pattern.*

## How to use this guide

Every step has the same three parts:

- **The idea**: the general thinking and the principle from the README, so you can make the same decision in a case I did not cover.
- **In your repository**: what to do, with your own file names and code.
- **In the examples**: where `mightyiam/infra` ("infra") and `voidarc/nixos` ("voidarc") do the same thing, with links.

Each step ends with your flake in a working state, so you can commit at every step. From Step 4 onward the hosts build again, and Step 0 gives you a way to prove that a step changed nothing you didn't intend.

**Two words used throughout.** *Legacy* means a file that has not been migrated yet. *Wrapping* means registering a legacy file as a stored module by path, without editing it (the `deferredModule` type accepts paths). Wrapping is what lets you migrate one feature at a time while the system keeps building.

> **A note on verification.** I could not run Nix where I worked, so nothing here was built. Snippets were syntax-checked and compared against the sources of flake-parts, import-tree, home-manager and nixpkgs' module system; excerpts from your repository and the examples are quoted programmatically. Treat every snippet as *reviewed, not built*. Step 0 exists to catch what I missed.

## Contents

- [Where you are now](#where-you-are-now)
- [The choices this guide makes for you](#the-choices-this-guide-makes-for-you)
- [Step 0 — Freeze a baseline and set up the safety net](#step-0--freeze-a-baseline-and-set-up-the-safety-net)
- [Step 1 — Decide your vocabulary (storage, roles, opt-ins)](#step-1--decide-your-vocabulary-storage-roles-opt-ins)
- [Step 2 — Make the entry point boring; turn the plumbing into modules](#step-2--make-the-entry-point-boring-turn-the-plumbing-into-modules)
- [Step 3 — Packages, overlays and nixpkgs settings](#step-3--packages-overlays-and-nixpkgs-settings)
- [Step 4 — Hosts first: get `nixosConfigurations` back by wrapping legacy code](#step-4--hosts-first-get-nixosconfigurations-back-by-wrapping-legacy-code)
- [Step 5 — Migrate the NixOS-only features (`cooked/nixos/*`, `nixos/*`)](#step-5--migrate-the-nixos-only-features-cookednixos-nixos)
- [Step 6 — Migrate the cross-class features (`cooked/home-manager/*`)](#step-6--migrate-the-cross-class-features-cookedhome-manager)
- [Step 7 — The user: account, home-manager wiring, personal settings](#step-7--the-user-account-home-manager-wiring-personal-settings)
- [Step 8 — Peel the personal home-manager tree (`daniel/**`) into features](#step-8--peel-the-personal-home-manager-tree-daniel-into-features)
- [Step 9 — Remove the scaffolding; update CI and the README](#step-9--remove-the-scaffolding-update-ci-and-the-readme)
- [Step 10 (optional) — Going further](#step-10-optional--going-further)
- [Appendix A — File-by-file migration map](#appendix-a--file-by-file-migration-map)
- [Appendix B — Recipes](#appendix-b--recipes)
- [Appendix C — Troubleshooting](#appendix-c--troubleshooting)
- [Appendix D — Sources, and what was and was not verified](#appendix-d--sources-and-what-was-and-was-not-verified)

---

## Where you are now

Your last commit ("dendritic: Migrate development config") did real work: `flake.nix` uses flake-parts and import-tree, packages became `perSystem.packages`, the dev shell became a module, and `nix` and `development` became `flake.nixosModules`. It also moved `pkgs/`, `overlays/`, `lib/`, `shell.nix` and the host wiring out of `flake.nix`, and the host wiring has not been re-created yet. That leaves the following, in the order you are likely to meet them:

| # | Observation | Consequence | Handled in |
|---|---|---|---|
| 1 | `modules/aspects/nix.nix` sets `nixpkgs.hostPlatform = system` inside `moduleWithSystem`. | **Circular.** `moduleWithSystem` finds its `system` from `config._module.args.pkgs.stdenv.hostPlatform.system` (flake-parts `modules/moduleWithSystem.nix`), and NixOS builds `pkgs` from `nixpkgs.hostPlatform` (nixpkgs `nixos/modules/misc/nixpkgs.nix`). Expect `infinite recursion encountered` the first time a host imports the module. NixOS itself defines no `_module.args.system` that could short-circuit it. | Step 1 |
| 2 | The flake no longer defines `nixosConfigurations`, `overlays`, `lib`, `templates` or `formatter`. | Nothing to build. `nix fmt` fails. `.github/workflows/verify_configurations.yml` runs `jq '.nixosConfigurations \| keys'`, which fails on `null`. `pkgs.stable`, `pkgs.my_neovim`, `pkgs.nur`, the unfree `ffmpeg-full` and your packages no longer exist as `pkgs.*`. | Steps 2, 3, 4 |
| 3 | Four legacy files import `modules/XF86.nix` / `modules/hyprpaper.nix`, which now live in `modules.old/`: `cooked/nixos/services/sound.nix:9`, `daniel/XF86Misc.nix:13`, `daniel/programs/music.nix:8`, `daniel/programs/wayland/hyprland.nix:11`. | Legacy code cannot evaluate once wired back in. | Step 4 |
| 4 | `cooked/nixos/scripts.nix:19` uses `pkgs.power-menu`; the package is now `packages.powermenu`. | Latent (`menus` is off by default). | Step 3 |
| 5 | No `flake-parts.flakeModules.modules` import. | `flake.modules.<class>.<name>` does not exist yet. Needed for the storage choice in Step 1. | Step 2 |
| 6 | `systems = ["x86_64-linux"]; # TODO: Remove` | It cannot be removed while anything uses `perSystem` (packages, dev shell). It can be *moved* and, if you like, *derived*. | Step 2 |
| 7 | Dead legacy files: `daniel/programs/X11/{rofi,sxhkd,sxiv}.nix` and `nixos/programs.nix` are imported by nothing. | Under import-tree, **anything you move under `modules/` becomes live**. Delete or `_`-prefix them. | Step 8 |

Three things I noticed that are unrelated to the pattern, so you can decide separately. The companion note [`03-config-notes.md`](03-config-notes.md) gives the evidence, the options and a check for each (as N1 to N4), and lists eight more:

- **Hyprland's `nixpkgs` follows yours** (`flake.nix:35`, new in your last commit). Hyprland's wiki says: "Do **not** override Hyprland's `nixpkgs` input unless you know what you are doing. Doing so will render the cache useless" ([Cachix page](https://wiki.hypr.land/Nix/Cachix/)). You already add `hyprland.cachix.org` as a substituter in `cooked/home-manager/hyprland.nix`, and the `mesa` workaround there (`inputs.hyprland.inputs.nixpkgs...mesa`) becomes a no-op when the two nixpkgs are the same (N1). The same commit added `follows` to `my_neovim`, which changes its derivation (N2).
- **`nixos/configuration.nix` hard-codes a store path**: `programs.ssh.askPassword = "/nix/store/pg42...-ksshaskpass-5.27.7/bin/ksshaskpass"`. A string literal is not a dependency, so nothing keeps that path alive, and your pinned nixpkgs no longer has Plasma 5 to rebuild it. The option is also probably not in effect on your hosts, because it needs `programs.ssh.enableAskPassword`, which defaults to `services.xserver.enable` (N3 has the check and the fix).
- **`nixpkgs-stable` tracks `nixos-25.05`**, which reached end of life at the end of 2025 (25.11 has ended since, and 26.05 is current; voidarc already tracks it). You only use it for `pkgs.stable.gitSVN` on WSL (N4).

## The choices this guide makes for you

None of these is forced by the pattern; each row names the alternative. Steps 1 to 4 explain the reasoning.

| # | Choice | Alternative |
|---|---|---|
| D1 | Store lower-level modules in **`flake.modules.nixos.<name>`** and **`flake.modules.homeManager.<name>`** (flavour B). | Keep `flake.nixosModules` (A, NixOS only), or declare your own typed options (C, what infra does now). |
| D2 | **Roles**: `nixos.base`, `nixos.desktop`, `homeManager.base`, `homeManager.gui`. Feature files merge into them. Only genuinely optional things get their own name (`daniel`, `vm`, `menus`). | voidarc-style: one name per feature and import lists. |
| D3 | **Hosts** are stored modules named `nixosConfigurations/<host>`, turned into `flake.nixosConfigurations` by a 20-line assembler. | One `nixosSystem` call per host file (voidarc), or a typed host registry (infra). |
| D4 | **Shared values** live in one typed option, `owner` (username, name, email). | `flake.meta`, or `users.<name>` submodules (infra). |
| D5 | **Layout**: `modules/{repository,nixpkgs,pkgs,hosts,users,aspects}` plus `roles.nix` and `home-manager.nix`. You keep your `aspects/` and `pkgs/`. | Anything; paths carry no meaning. |
| D6 | **Migration style**: wrap legacy code by path, then peel features off one at a time ("strangler fig"). | Big bang: migrate everything, then build. |
| D7 | **`systems`** stays an explicit list, in a module. | Derive it from the hosts (needs each host's platform to be a static value, as infra's hardware reports are). |
| D8 | **home-manager** stays a NixOS module, as now. | Standalone home-manager. |

### Where it ends up

```text
flake.nix                              inputs + one line of `outputs`
modules/
├── repository/                        Step 2: plumbing
│   ├── parts.nix   formatter.nix   templates.nix   owner.nix   devshell.nix
├── nixpkgs/overlays.nix               Step 3
├── pkgs/…                             (done)
├── roles.nix                          Step 1
├── home-manager.nix                   Step 4
├── hosts/                             Step 4
│   ├── nixos-configurations.nix       the assembler
│   ├── dellG5/{default.nix,_hardware.nix}
│   └── wsl/default.nix
├── users/daniel.nix                   Steps 4 and 7
└── aspects/                           Steps 5 to 8: one feature per file, both classes
    ├── nix.nix  development.nix  locale.nix  fonts.nix  gnupg.nix  network.nix  sops.nix  vm.nix …
    ├── desktop/   sound.nix  printing.nix  display-manager.nix  hyprland/  waybar.nix  wofi.nix …
    ├── shell/     zsh.nix  git.nix  tmux.nix  nix-index.nix  editor.nix  terminal.nix  yazi.nix …
    ├── email/     media/   browsers/   dev/ …
    └── (assets sit next to the feature that uses them: wallpapers, neomutt rc files, …)
```

### The ten steps in one table

| Step | Principle | You do | Old → new |
|---|---|---|---|
| 0 | Prove, don't hope | Build a baseline from `master`; diff closures after each step | — |
| 1 | Model before moving | Choose storage (B), roles, opt-ins; fix `nix.nix` | `flake.nixosModules.nix` → `flake.modules.nixos.base` |
| 2 | Only entry points are not modules | One-line `outputs`; tiny plumbing modules; the underscore rule | `flake.nix` body → `modules/repository/*.nix` |
| 3 | Things declare themselves where they belong | Overlays as `flake.overlays.*`; one place applies them | `overlays/` → `modules/nixpkgs/overlays.nix` |
| 4 | Hosts select; get to green early | Assembler + host modules that wrap legacy code | `mkHost` in `flake.nix` → `modules/hosts/*` |
| 5 | Presence replaces `enable`; a feature owns its side effects | `cooked/nixos/*` into roles and named modules | `options.cooked.x.enable` → merged into `nixos.base` / `desktop` |
| 6 | One feature, all its classes, one file | `cooked/home-manager/*` into two stored modules each | `builtins.any … users` + `sharedModules` → `nixos.*` + `homeManager.*` |
| 7 | A user is a cross-class feature | One user module; `owner` replaces scattered names | `mkHomeUsers`, `users/daniel` → `modules/users/daniel.nix` |
| 8 | Split by feature; keep assets and overlays beside it; delete dead code | Peel `daniel/**` into `modules/aspects/**` | `daniel/programs/*` etc. → features |
| 9 | Finish: remove the scaffolding | Delete `specialArgs`, legacy paths, legacy dirs | temporary lines gone |

### Milestones

| Milestone | Steps | State when reached |
|---|---|---|
| **M1: green again** | 0 to 4 | New entry point; both hosts build from the new layout; almost all code is still legacy, wrapped by path. |
| **M2: system side migrated** | 5, 6 | `cooked/` is gone. NixOS features (and the NixOS halves of cross-class ones) live in `modules/aspects/`. |
| **M3: user side migrated** | 7, 8 | `daniel/`, `users/`, `nixos/`, `hosts/` are gone. |
| **M4: scaffolding removed** | 9 | No `specialArgs`, no legacy paths; README and CI updated. |

---

## Step 0 — Freeze a baseline and set up the safety net

### The idea

A refactor is only safe if you can *prove* that behaviour did not change. A NixOS system closure is a value, so "before" and "after" can be compared mechanically. Set the comparison up once, at the start, and run it after every step. Two questions need two tools:

- *"Did this step change anything at all?"* Compare derivation paths: identical means an identical system (with a caveat about list order, below).
- *"What changed?"* `nix store diff-closures` (package level), `nvd` (nicer output) or `nix-diff` (why a derivation's hash differs).

This matters more for dendritic than for most refactors, because the pattern turns *moving text between files* into the main activity, and "did I lose a line?" is exactly what closures answer.

### In your repository

**1. Build a baseline from `master`, pinned to the same inputs as your branch**, so that differences show *your* changes and not newer nixpkgs:

```sh
git worktree add ../nixos-baseline master
cp flake.lock ../nixos-baseline/flake.lock    # Nix may rewrite it there; that's fine, nothing is committed
for h in dellG5 wsl; do
  nix build ../nixos-baseline#nixosConfigurations.$h.config.system.build.toplevel \
    --out-link result-baseline-$h            # `result*` is already in your .gitignore
done
```

**2. After each step** (from Step 4, when hosts exist again):

```sh
for h in dellG5 wsl; do
  nix build .#nixosConfigurations.$h.config.system.build.toplevel --out-link result-new-$h
  nix store diff-closures ./result-baseline-$h ./result-new-$h
done
```

Empty output means the same packages at the same versions.

**3. Know which differences are yours.** Your last commit already changed a few things that will show up, so they are not migration bugs: `nix.gc.dates` (weekly to daily), the `follows` you added to `hyprland` and `my_neovim` (different derivations, and a Hyprland rebuild), and the reworked `configure` script. Anything else deserves an explanation before you move on. The companion note explains the first two and asks whether you meant them (N11, N1, N2 in [`03-config-notes.md`](03-config-notes.md)); reverting the Hyprland `follows` (N1) *before* you build the baseline removes one of these differences.

**4. Optional: a stricter check for steps that only move text.** This package writes each host's `toplevel` derivation path to a file. Build it before and after a step (on the same uncommitted tree, where the revision label is the constant `"dirty"`) and `diff` the two. **Identical files are proof** that the system did not change. **Different files are not necessarily a bug**: moving text between files can reorder merged lists such as `environment.systemPackages`, which changes a derivation hash without changing what is installed. When that happens, `nix store diff-closures` (empty output) or `nix-diff` (it shows the change is only list order) settle the question. Add it once hosts exist (Step 4):

```nix
# modules/repository/drv-paths.nix   (adapted from infra@b45e9e1: modules/meta/drv-paths.nix)
{
  config,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.drv-paths = pkgs.writeText "drv-paths" (
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: host: "${name} ${builtins.unsafeDiscardStringContext host.config.system.build.toplevel.drvPath}"
        )
        config.flake.nixosConfigurations
      )
    );
  };
}
```

```sh
nix build .#drv-paths --out-link result-drv-before      # …edit, move files…
nix build .#drv-paths --out-link result-drv-after
diff result-drv-before result-drv-after && echo "identical systems"
```

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| Detect unintended change | README section "Refactoring": `.#all-check-store-paths` ([`modules/repository/all-check-store-paths.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/all-check-store-paths.nix)) maps every check to its store path. At adoption: [`modules/meta/drv-paths.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/meta/drv-paths.nix). Every host is also a `flake.checks` entry ([`modules/nixos.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos.nix)). | none |
| Diff tools | `nix-diff` and `nvd` are installed for the user in [`modules/mightyiam/nix/utils.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/nix/utils.nix) | none |

---

## Step 1 — Decide your vocabulary (storage, roles, opt-ins)

### The idea

The pattern's real work is *modelling*. The README says using only existing options "prevents us from translating our mental model of the system into code", so decide what your nouns are before you move a single file. Four decisions make the rest mechanical:

1. **How are stored modules kept?** (Report 1, §2.4: flavours A, B, C.)
2. **Which roles exist?** A role is a stored module that many features merge into, so a host imports one name instead of a hundred. Your `cooked.preload.*` presets are roles waiting to be named.
3. **What is a named opt-in?** If *every* machine in a role wants a feature, merge it into the role. If only some do, give it its own name and let those hosts import it. This replaces `cooked.<x>.enable`. (The README: "In most cases, importing a module should enable the feature that it provides.")
4. **What plain values are shared?** Your name, email and username appear in several places. Declare them once (Step 2).

### In your repository

**Storage.** Use flavour B. You have two classes, and flavour A (`flake.nixosModules`) has no home-manager counterpart. B costs one import line (Step 2) and is the shape infra had when its author adopted the pattern. If you later want the typed options of C, only the attribute paths change, not the bodies of your feature files.

**Roles.** Your existing presets and always-on blocks map straight across:

| Today | Becomes |
|---|---|
| The "Common config" block in `cooked/nixos/default.nix` (and every `cooked.<x>.enable = mkDefault true` in it) | `nixos.base` |
| `cooked.preload.desktop` (display manager, printing, sound) | `nixos.desktop`, which includes `base` |
| `cooked.preload.server` (empty today) | nothing yet. Add `nixos.server` when it has content. |
| `cooked/home-manager/default.nix` and the always-on parts of `daniel/` | `homeManager.base` |
| Graphical-session HM config (Hyprland, waybar, wofi, dunst, browsers, …) | `homeManager.gui`, which includes `base` |

**Named opt-ins** you will meet: `daniel` (the user account, which a host chooses to have), `vm` (libvirt; enabled on no host today), `menus` (the power menu).

**Convert your two existing aspects.** They are always-on, so they merge into `base`. Note that `hostPlatform` leaves the shared module. That fixes audit item 1: a *host* says which platform it is (Step 4), not a module that needs the platform to be known in order to load.

```nix
# modules/aspects/nix.nix
{
  flake.modules.nixos.base = {
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = ["nix-command" "flakes"];
        trusted-users = ["root" "@wheel"];
        use-xdg-base-directories = true;
      };
      optimise = {
        automatic = true;
        dates = ["13:00" "20:00"];
      };
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 14d";
      };
    };
    nixpkgs.config.allowUnfree = true;
  };
}
```

```nix
# modules/aspects/development.nix   (was modules/aspects/development/development.nix)
{
  flake.modules.nixos.base = {pkgs, ...}: {
    programs.direnv = {
      enable = true;
      silent = true;
    };
    environment.systemPackages = [pkgs.gnumake];
  };
}
```

Two files, one stored module: that is `deferredModule` merging at work. And the roles themselves:

```nix
# modules/roles.nix
{config, ...}: {
  # Declare the roles. An empty definition is a valid module, and it makes the role
  # exist before any feature has added to it (otherwise `homeManager.base` would be
  # "attribute missing" until your first home-manager feature lands in Step 6).
  flake.modules.nixos.base = {};
  flake.modules.homeManager.base = {};

  # `desktop` / `gui` are everything in `base` plus whatever desktop features add.
  flake.modules.nixos.desktop.imports = [config.flake.modules.nixos.base];
  flake.modules.homeManager.gui.imports = [config.flake.modules.homeManager.base];
}
```

> **Import a role through exactly one path.** The `flake.modules` wrapper adds no `key` (Report 1, §2.4), so if a host imports both `desktop` and `base`, `base` is evaluated twice. That is harmless for plain `config` but produces duplicated `lines`/list entries, and an `option ... is already declared` error if the role declares options. The rule is easy to keep: hosts import `desktop`, never `desktop` and `base`. If you outgrow the rule, flavour C's `apply` (infra) is the fix.

Where `moduleWithSystem` *is* fine: whenever the system comes from somewhere else (a host's `hostPlatform`). voidarc uses it in nearly every feature, and its hosts get the platform from the imported `hardware-configuration.nix`.

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| Storage | C: [`modules/nixos/base.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos/base.nix), [`modules/nixos/pc.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos/pc.nix), [`modules/home-manager.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/home-manager.nix) declare the roles as `deferredModule` options. At adoption (2025-03) it was B: `flake.modules.nixos.desktop`, `flake.modules.homeManager.home`. | A: `flake.nixosModules.<name>` everywhere |
| Roles | `base` (every machine) and `pc` (includes `base`); HM: `base`, `gui` | [`modules/system/core/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/core/default.nix) and [`modules/system/desktop/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/desktop/default.nix), built by import lists |
| Named opt-ins | [`modules/hardware/efi.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/hardware/efi.nix), [`modules/storage/zfs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/storage/zfs.nix), [`modules/hardware/nvidia-gpu.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/hardware/nvidia-gpu.nix) | features by name in host lists (`steam`, `distcc`, …) |
| Shared plain values | `users.<name>.{username,name,email}` ([`modules/users.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/users.nix)); at adoption `flake.meta.owner` ([`modules/owner.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/owner.nix)) | none: `user01` is written into each feature |

---

## Step 2 — Make the entry point boring; turn the plumbing into modules

### The idea

README rule 1: only entry points are not modules. The corollary people miss is that the things that configure *the repository itself* are also just top-level modules: which systems to build for, which flake-parts extras to load, which formatter, what your name is. Give each its own tiny file. Every concern then has exactly one home, and `flake.nix` keeps only what nothing else can hold: the inputs and the line that starts everything.

The second idea is a **rule about what may live under `modules/`**. import-tree imports *every* `.nix` file beneath it, so only top-level modules may live there, unless the path is hidden by an underscore. That has consequences for files that are not modules (see the table in 2e).

### In your repository

**2a. Shrink `flake.nix`.** Inputs stay exactly as they are. The `outputs` becomes one line, the same as voidarc's:

```nix
{
  description = "Daniel's configuration flake";

  inputs = {
    # … all your inputs, unchanged …
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
```

`rootPath` and `systems` move into a module (next).

**2b. `modules/repository/parts.nix`** holds the flake-parts wiring:

```nix
# modules/repository/parts.nix
{inputs, ...}: {
  imports = [
    inputs.flake-parts.flakeModules.modules # gives you `flake.modules.<class>.<name>`
  ];

  systems = ["x86_64-linux"];

  # Root of the repository, for the few files that live outside modules/
  # (secrets.yaml, and legacy code while you migrate). Relative to THIS file.
  _module.args.rootPath = ../..;
}
```

Your `modules/devshell.nix` already looks like this (it imports `inputs.devshell.flakeModule`); you can leave it, or move it to `modules/repository/devshell.nix` for tidiness.

**2c. About `systems ... # TODO: Remove`.** flake-parts requires `systems` as soon as anything uses `perSystem` (your packages and dev shell do), so it can be *placed* but not removed. Your old flake used `nixpkgs.lib.systems.flakeExposed` (every platform Nix knows); the new one names `x86_64-linux`. Both are fine:

- *Explicit list* (above): `nix flake check`/`show` only cover Linux x86-64. Right for two x86-64 hosts.
- *`inputs.nixpkgs.lib.systems.flakeExposed`*: the old behaviour. Everything is still evaluated lazily, but checks over every platform can trip on packages that don't exist there (`hyprland`, `waylock`).
- *Derived from the hosts*: what infra does. It needs each host's platform to be a **static value**. Reading `nixpkgs.hostPlatform` out of an evaluated host would create a cycle (hosts may call `withSystem`, which needs `systems`), so infra reads `system` from each host's hardware-report JSON instead ([`modules/repository/systems.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/systems.nix)). Not worth it for two hosts.

**2d. Three more one-file modules** that give the old wiring a home:

```nix
# modules/repository/formatter.nix   (restores `nix fmt`; was `formatter = pkgs.alejandra` in the old flake)
{
  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
```

```nix
# modules/repository/templates.nix   (replaces templates/default.nix; the templates themselves stay put)
{
  flake.templates = {
    rust = {
      path = ../../templates/rust;
      description = "Template for a Rust project";
    };
    java = {
      path = ../../templates/java;
      description = "Template for a Java project with Maven";
    };
  };
}
```

```nix
# modules/repository/owner.nix   (decision D4: one typed source of truth for who this is all for)
{lib, ...}: {
  options.owner = {
    username = lib.mkOption {type = lib.types.singleLineStr;};
    name = lib.mkOption {type = lib.types.singleLineStr;};
    email = lib.mkOption {type = lib.types.singleLineStr;};
  };

  config.owner = {
    username = "daniel";
    name = "Daniel Laing";
    email = "daniel@daniellaing.com";
  };
}
```

You already have this "database", scattered: `users.users.daniel`, `user.email` in `users/daniel/programs.nix`, `age.keyFile = "/home/daniel/..."` in `cooked/nixos/sops.nix`, `wsl.defaultUser = "daniel"`, `home.username`. Declaring it once is the README's "declare options" advice in its smallest form. Any file can now read `config.owner.username` (Report 1, §2.5).

**2e. What may live under `modules/`:**

| Kind of file | Example in your repository | What to do |
|---|---|---|
| A top-level module | everything you write new | anywhere under `modules/` |
| A **legacy NixOS/home-manager module** (a function of `{pkgs, ...}` returning config) | `cooked/nixos/vm.nix`, `hosts/dellG5/hardware.nix` | keep it outside `modules/`, or give it a `_` prefix, and **wrap it by path**: `flake.modules.nixos.vm = ./_vm.nix;` |
| A **data or helper function** that another file `import`s | `daniel/shell/aliases.nix`, `daniel/programs/browsers/bookmarks.nix`, `nixos/email/{sync-email,get-mailboxes,neomutt-account-switcher}.nix` | `_` prefix (`_aliases.nix`); keep importing it by path |
| A directory containing a `flake.nix` | `templates/rust`, `templates/java` | keep it **outside** `modules/`, or import-tree will try to load it as a module |
| Non-Nix assets | wallpapers, `daniel/email/neomutt/*` | put them next to the feature that uses them; import-tree ignores them |
| **Dead code** | `daniel/programs/X11/*.nix`, `nixos/programs.nix` | delete it, or `_`-prefix it. Never move it in as-is. |

> **Dead code becomes live code.** Nothing imports `daniel/programs/X11/{rofi,sxhkd,sxiv}.nix` today, so nothing happens. Move them under `modules/` and import-tree will import them as top-level modules: an error at best, an unexpected `services.sxhkd` at worst. The same applies to a file with a *wrong* shape, such as `aliases.nix`, which is a bare attrset of aliases: as a "module" it would be read as config for options like `sudo` and `ls` that do not exist.

**Checkpoint.** `nix flake show` lists `packages`, `devShells`, `formatter`, `templates`, and no errors. There are no hosts yet.

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| Entry point | [`outputs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/outputs.nix), and a *generated* `flake.nix` | [`flake.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/flake.nix): one line of `outputs` |
| flake-parts extras loaded from a file | at adoption: [`modules/meta/flake-parts.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/meta/flake-parts.nix) (`imports = [inputs.flake-parts.flakeModules.modules]`), [`modules/meta/devshell.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/meta/devshell.nix); today [`modules/repository/dev-shell.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/dev-shell.nix), [`modules/repository/formatting.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/formatting.nix) | none needed (uses only built-in options) |
| `systems` | derived from hosts: [`modules/repository/systems.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/systems.nix) | fixed list in [`modules/parts.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/parts.nix) |
| Underscore files | `modules/computers/_teeveera.nix` (a disabled host); import-tree docs | none |
| `.pkg.nix` | [`modules/mightyiam/nix/system-command.pkg.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/nix/system-command.pkg.nix) | none |
| Shared plain values | [`modules/owner.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/owner.nix) (`flake.meta.owner`), later `users.<name>` | none |

---

## Step 3 — Packages, overlays and nixpkgs settings

### The idea

In the old layout `flake.nix` pushed a fixed set of overlays into every host, so any module could write `pkgs.my_neovim` without saying where it came from. In the dendritic layout, **things declare themselves where they belong**: a package is a top-level `perSystem` value; an overlay is a top-level value in `flake.overlays`; a lower-level module applies the overlays it needs.

A NixOS module can use a flake-built package in two ways:

- **Through `pkgs`**: an overlay bridges `perSystem.packages` into `pkgs`. Your existing modules already say `pkgs.configure`, so this is the least change. Start here.
- **Explicitly**: `self'.packages.configure` inside `moduleWithSystem` (voidarc's habit). More dendritic, because the dependency is visible at the point of use. Move there feature by feature if you like.

### In your repository

Your old overlay did four jobs:

**your repo @ master** — `overlays/default.nix`

```nix
{
  nixpkgs,
  nixpkgs-stable,
  my_neovim,
  ...
}: {
  default = nixpkgs.lib.composeManyExtensions [
    # Stable packages
    (final: prev: {
      stable = import nixpkgs-stable {
        system = prev.stdenv.hostPlatform.system;
        config = {allowUnfree = true;};
        overlays = [];
      };
    })

    # Adds packages packaged in this flake
    (final: prev:
      import ../pkgs {pkgs = final;}
      // {
        # scripts = import ../pkgs/scripts {pkgs = final;};
      })

    (
      final: prev: {
        my_neovim = my_neovim.packages.${prev.stdenv.hostPlatform.system}.default;
      }
    )

    # ffmpeg with unfree libs
    (final: prev: {
      ffmpeg-full =
        (prev.ffmpeg-full.override {
          withUnfree = true;
        }).overrideAttrs (_: {
          doCheck = false;
        });
    })
  ];
}
```

The packages part is already done (`modules/pkgs/*`, unchanged in intent). The rest becomes four named overlays plus one place that applies them:

```nix
# modules/nixpkgs/overlays.nix
{
  config,
  inputs,
  withSystem,
  ...
}: {
  flake.overlays = {
    # `pkgs.stable`: the stable channel (only WSL uses it today)
    stable = final: prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    };

    # Bridge: perSystem.packages.* -> pkgs.*   (replaces `import ../pkgs {pkgs = final;}`)
    packages = final: prev:
      withSystem prev.stdenv.hostPlatform.system (psArgs: {
        inherit (psArgs.config.packages) configure update-system powermenu stag;
      });

    my-neovim = final: prev: {
      my_neovim = inputs.my_neovim.packages.${prev.stdenv.hostPlatform.system}.default;
    };

    # ffmpeg with unfree libs
    ffmpeg-unfree = final: prev: {
      ffmpeg-full =
        (prev.ffmpeg-full.override {withUnfree = true;}).overrideAttrs (_: {
          doCheck = false;
        });
    };
  };

  # Everything in `base` gets the overlays (this is the old inline module of `mkHost`).
  flake.modules.nixos.base = {
    nixpkgs.overlays = [
      config.flake.overlays.stable
      config.flake.overlays.packages
      config.flake.overlays.my-neovim
      config.flake.overlays.ffmpeg-unfree
      inputs.nur.overlays.default
    ];
  };
}
```

Points worth understanding:

- **`withSystem`** is a top-level argument that runs a function against one system's `perSystem` config. Inside the overlay, the system comes from `prev`, so the overlay works for whichever platform evaluates it. The argument is named `psArgs` (not `config`) so it doesn't shadow the outer `config`.
- **The list is explicit** because overlay order can matter and you want to choose it (`builtins.attrValues` would sort by name). flake-parts' docs for `flake.overlays` make the related point that composition order is significant and the module system does not guarantee a deterministic order across modules.
- **`perSystem`'s own `pkgs`** is plain `inputs.nixpkgs.legacyPackages.${system}`: no overlays, no unfree. Your four packages need neither. If one ever needs an unfree dependency, set `perSystem._module.args.pkgs` (infra builds one shared `pkgs`; see below).
- **Naming**: the attribute is `powermenu` now (it was `power-menu`). Step 5 updates the one reference in `scripts.nix`. The *executable* is still `powermenu`, so your Hyprland keybinding is unaffected.
- **`stable` is optional.** It exists for one package (`pkgs.stable.gitSVN`, WSL only), its input tracks the end-of-life `nixos-25.05`, and `pkgs.gitSVN` exists in your main nixpkgs. If that builds for you, leave this overlay out and delete the `nixpkgs-stable` input (note [N4](03-config-notes.md#n4--nixpkgs-stable-is-an-end-of-life-release)). Decide before you write it.
- **`allowUnfree`** already lives in `nix.nix` (Step 1), and **`hostPlatform`** moves to the hosts (Step 4).
- **Locality.** Each overlay really belongs next to its consumer: `my-neovim` next to the editor feature, `ffmpeg-unfree` next to the media feature, `stable` next to WSL. Step 8 moves `my-neovim` as a demonstration. They are collected here first because the legacy code needs them all on day one.

**Checkpoint.** `nix flake show` additionally lists `overlays`. Overlays are only evaluated when a host uses them (Step 4).

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| Overlays | overlays live next to what needs them: [`modules/mightyiam/nix/utils.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/nix/utils.nix) adds `system-command` via `perSystem.nixpkgs.overlays` | [`modules/system/core/nix-settings.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/core/nix-settings.nix): `nixpkgs.config.packageOverrides` for `unstable`, plus `unfreePkgs`/`unstablePkgs` as `perSystem` arguments |
| One `pkgs` for everything | [`modules/nixpkgs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixpkgs.nix): `perSystem` imports nixpkgs' own `nixpkgs.nix` module and NixOS gets `nixpkgs.pkgs = withSystem ... (getAttr "pkgs")` | no: each feature asks `moduleWithSystem` for `pkgs` |
| Unfree | `nixpkgs.config.allowUnfreePackages = [ ... ]` declared per feature (e.g. [`modules/hardware/nvidia-gpu.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/hardware/nvidia-gpu.nix)); at adoption a top-level option, [`modules/allow-unfree-packages.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/allow-unfree-packages.nix) | `allowUnfree = true` globally |
| Packages | `*.pkg.nix` `callPackage` files plus an overlay | `perSystem.packages.<app>` inside the feature file ([`modules/features/kitty/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/kitty/default.nix)) |
| Reading `perSystem` from a NixOS module | `withSystem` (in [`modules/nixpkgs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixpkgs.nix)) | `moduleWithSystem` in almost every feature |

---

## Step 4 — Hosts first: get `nixosConfigurations` back by wrapping legacy code

### The idea

**A host is where features get selected.** In the pattern's terms it is a *lower-level configuration built from stored modules*, so it has two halves:

1. the host's own bits, as an ordinary stored module (`flake.modules.nixos."nixosConfigurations/dellG5"`), and
2. one small top-level *assembler* that turns every stored module with that name prefix into a `flake.nixosConfigurations.<host>`.

**Why hosts before features.** Step 0's safety net needs something to build. So restore the hosts *now*, while nearly everything is still legacy, and let the host module `import` the legacy directories by path. This is the "strangler fig" approach (decision D6): the new structure grows around the old, and every later step deletes one legacy import. If you would rather migrate everything and build once at the end, skip the legacy imports below; you just lose the ability to check your work along the way.

**A host is also just a stored module.** That means *any* file can contribute to it, exactly like a role. infra's author did this at adoption: `modules/ganoderma/{imports,host-id,state-version,facter}.nix` are four top-level modules that each add one facet to the one host module. You will use this later to split `hardware.nix` into reusable pieces.

### In your repository

**4a. What the old `mkHost` did.** It was doing eleven jobs; each needs a new home:

**your repo @ master** — `flake.nix` (lines 68-109)

```nix nosyntax
        nixosConfigurations = let
          lib = nixpkgs.lib.extend self.lib.default;
          mkHost = {
            hostName,
            system,
          }:
            nixpkgs.lib.nixosSystem rec {
              inherit system lib;
              specialArgs = {inherit inputs;};

              modules = [
                {
                  networking = {inherit hostName;};
                  system = let
                    shortHash = self.shortRev or "dirty";
                  in {
                    configurationRevision = shortHash;
                    nixos.label = shortHash;
                  };
                  nixpkgs = {
                    overlays = [self.overlays.default inputs.nur.overlays.default];
                    config.allowUnfree = true;
                    hostPlatform = nixpkgs.lib.mkDefault system;
                  };
                }

                ./cooked

                ./hosts/${hostName}
                ./nixos/configuration.nix

                {
                  home-manager = {
                    useGlobalPkgs = true;
                    extraSpecialArgs = specialArgs;
                    users.daniel = import ./daniel;
                  };
                }

                home-manager.nixosModules.home-manager
              ];
            };
```

| # | Old job in `mkHost` | New home |
|---|---|---|
| 1 | `networking.hostName = hostName` | the assembler (4b) |
| 2 | `system.configurationRevision` / `nixos.label` from `self.shortRev` | `modules/aspects/system-revision.nix` (4g) |
| 3 | `nixpkgs.overlays = [self.overlays.default inputs.nur...]` | `modules/nixpkgs/overlays.nix` (Step 3) |
| 4 | `nixpkgs.config.allowUnfree = true` | `modules/aspects/nix.nix` (Step 1) |
| 5 | `nixpkgs.hostPlatform = mkDefault system` | **each host** (4d, 4e). `nixosSystem` in the nixpkgs flake sets `system = null`, so a module must say the platform. |
| 6 | `./cooked` | legacy import for now (4d); dissolves in Steps 5 and 6 |
| 7 | `./hosts/${hostName}` | `modules/hosts/<host>/` (4d, 4e) |
| 8 | `./nixos/configuration.nix` | legacy import for now; dissolves in Step 5 |
| 9 | `home-manager.{useGlobalPkgs,extraSpecialArgs,users.daniel}` and the HM NixOS module | `modules/home-manager.nix` (4c) and `modules/users/daniel.nix` (4f) |
| 10 | `specialArgs = {inherit inputs;}` | temporary line in the assembler; removed in Step 9. New code uses `inputs` from the enclosing function. |
| 11 | `lib = nixpkgs.lib.extend self.lib.default` (for `mkHomeUsers`) | not needed: `mkHomeUsers` is replaced by a plain `home-manager.users.daniel = ...` (4f) |

**4b. The assembler.** Written once, and it never needs editing again:

```nix
# modules/hosts/nixos-configurations.nix
{
  config,
  inputs,
  lib,
  ...
}: let
  prefix = "nixosConfigurations/";
in {
  flake.nixosConfigurations = lib.pipe (config.flake.modules.nixos or {}) [
    (lib.filterAttrs (name: _: lib.hasPrefix prefix name))
    (lib.mapAttrs' (name: module: let
      hostName = lib.removePrefix prefix name;
    in {
      name = hostName;
      value = inputs.nixpkgs.lib.nixosSystem {
        # TEMPORARY (removed in Step 9): legacy modules still take `inputs` as an argument
        specialArgs = {inherit inputs;};
        modules = [module {networking = {inherit hostName;};}];
      };
    }))
  ];
}
```

This is the shape infra had at adoption (see below) and the one drupol's write-up uses. `config.flake.modules.nixos` only has its *attribute names* inspected by the filter, so nothing is evaluated until a host is actually built.

**4c. home-manager, once, for every host:**

```nix
# modules/home-manager.nix
{inputs, ...}: {
  flake.modules.nixos.base = {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      useGlobalPkgs = true;
      # TEMPORARY (removed in Step 9): legacy home-manager modules still take `inputs`
      extraSpecialArgs = {inherit inputs;};
    };
  };
}
```

(`useUserPackages` stays at its default, as in your old flake, so the closure doesn't change.)

**4d. The `dellG5` host.** Move the hardware file first: `git mv hosts/dellG5/hardware.nix modules/hosts/dellG5/_hardware.nix` (the underscore keeps import-tree away; it is a NixOS module, not a top-level one).

```nix
# modules/hosts/dellG5/default.nix
{
  config,
  rootPath,
  ...
}: {
  flake.modules.nixos."nixosConfigurations/dellG5" = {pkgs, ...}: {
    imports = [
      config.flake.modules.nixos.desktop # a role; includes `base` (Step 1)
      config.flake.modules.nixos.daniel # a named module: the user (4f)
      ./_hardware.nix
      # ── legacy: each line disappears in a later step ──────────────────
      (rootPath + "/cooked")
      (rootPath + "/nixos/configuration.nix")
    ];

    nixpkgs.hostPlatform = "x86_64-linux";
    cooked.preload.desktop = true; # legacy switch; goes away in Step 5
    system.stateVersion = "23.05"; # Do not change.

    # … the whole `boot.loader = { … }` block from hosts/dellG5/default.nix, unchanged …
  };
}
```

**4e. The `wsl` host.** Two changes beyond copying: the platform, and `hosts/wsl/home.nix` disappears into the host (a machine-specific home-manager tweak is written directly in the host module, as infra does in `astraeus.nix`). The inner module names its arguments `nixosArgs` because it needs *its own* `config`, and the outer one is the flake-parts config:

```nix
# modules/hosts/wsl/default.nix
{
  config,
  inputs,
  rootPath,
  ...
}: {
  flake.modules.nixos."nixosConfigurations/wsl" = nixosArgs @ {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      inputs.nixos-wsl.nixosModules.default
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos.daniel
      (rootPath + "/cooked")
      (rootPath + "/nixos/configuration.nix")
    ];

    nixpkgs.hostPlatform = "x86_64-linux";
    cooked.preload.desktop = true; # legacy switch; goes away in Step 5
    system.stateVersion = "23.05"; # Do not change.

    wsl = {
      enable = true;
      defaultUser = config.owner.username;
      startMenuLaunchers = true;
    };

    networking.nftables.enable = lib.mkForce false;

    sops.secrets.svn-passwd = {
      owner = nixosArgs.config.users.users.daniel.name;
      group = nixosArgs.config.users.users.daniel.group;
    };

    # was hosts/wsl/home.nix
    home-manager.users.daniel.programs.git.package = pkgs.stable.gitSVN;
  };
}
```

(The old file's `environment.systemPackages = builtins.attrValues {inherit (pkgs);}` is an empty `inherit` and does nothing, so it is dropped.)

**4f. The user, interim.** Legacy `nixos/configuration.nix` still creates the account, so for now this module only wires home-manager to the two legacy trees:

```nix
# modules/users/daniel.nix   (interim: reworked in Step 7)
{
  config,
  rootPath,
  ...
}: {
  flake.modules.nixos.daniel = {
    home-manager.users.${config.owner.username}.imports = [
      (rootPath + "/daniel")
      (rootPath + "/users/daniel")
    ];
  };
}
```

This replaces `lib.mkHomeUsers` and the `import ./daniel` in the old flake. It is a *named* module because which host has which user is a per-host decision.

**4g. The revision label**, which the old `mkHost` set inline:

```nix
# modules/aspects/system-revision.nix
{self, ...}: {
  flake.modules.nixos.base.system = {
    configurationRevision = self.shortRev or "dirty";
    nixos.label = self.shortRev or "dirty";
  };
}
```

**4h. Repair the four dangling legacy imports** (audit item 3). Point them at `modules.old/` for now (rename that folder if you like, but keep it *outside* `modules/`):

```text
cooked/nixos/services/sound.nix:9              ../../../modules.old/XF86.nix
daniel/XF86Misc.nix:13                         ../modules.old/XF86.nix
daniel/programs/music.nix:8                    ../../modules.old/XF86.nix
daniel/programs/wayland/hyprland.nix:11        ../../../modules.old/hyprpaper.nix
```

**4i. Build and compare.**

```sh
nix build .#nixosConfigurations.dellG5.config.system.build.toplevel --out-link result-new-dellG5
nix store diff-closures ./result-baseline-dellG5 ./result-new-dellG5
```

Then the same for `wsl`. Expect only the differences listed in Step 0. The errors you are most likely to meet, and what they mean, are in Appendix C; the likeliest here are a stale relative path from the moves (`path '…' does not exist`) and an `attribute 'X' missing` from a name I renamed in passing.

**Checkpoint (M1).** Both hosts build; the closure matches your baseline apart from the known differences; `verify_configurations.yml` finds `nixosConfigurations` again. Commit.

**What you can do next, because a host is a stored module.** Later steps peel legacy imports off these two files. You can also split a host into facets, one top-level module per concern:

```nix
# e.g. modules/hosts/dellG5/power.nix   (Step 5 does this for real)
{
  flake.modules.nixos."nixosConfigurations/dellG5".services.tlp.enable = true;
}
```

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| A host file | [`modules/computers/molly.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/computers/molly.nix) (a server: role `base`); [`modules/computers/astraeus.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/computers/astraeus.nix) (a desktop: `pc` plus opt-ins) | [`modules/hosts/HACKSTATION/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/hosts/HACKSTATION/default.nix) plus [`modules/hosts/HACKSTATION/hackstationConfiguration.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/hosts/HACKSTATION/hackstationConfiguration.nix) for host-specific settings |
| The assembler | today [`modules/nixos.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos.nix) + [`modules/eval-modules.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/eval-modules.nix) (a typed registry, `nixos.configurations.<name>`). **At adoption [`modules/nixos-configurations.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/nixos-configurations.nix): the prefix approach used above.** | none: each host file calls `nixosSystem` itself |
| Host as facets | at adoption [`modules/ganoderma/imports.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/ganoderma/imports.nix), `host-id.nix`, `state-version.nix`, `facter.nix` | — |
| Host-specific home-manager settings | inside [`modules/computers/astraeus.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/computers/astraeus.nix) (`home-manager.users.mightyiam.audio.sinkNameMap`) | — |
| Hardware and platform | hardware reports ([`modules/hardware/facter.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/hardware/facter.nix)); `args = {system = null;}` | `/etc/nixos/hardware-configuration.nix` imported by [`modules/system/core/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/core/default.nix) (impure) |
| Feature list per host | drupol's `loadNixosAndHmModuleForUser config ["base" "desktop" …] "pol"` resolves each name in *both* classes | HACKSTATION's `modules = with self.nixosModules; [...]` |

**A simpler alternative (voidarc style).** Skip the assembler and write, per host, `flake.nixosConfigurations.dellG5 = inputs.nixpkgs.lib.nixosSystem { modules = [ ... ]; };`. It is fewer moving parts, but there is then no registry (nothing can enumerate hosts), and no place for host facets to be contributed from other files.

---

## Step 5 — Migrate the NixOS-only features (`cooked/nixos/*`, `nixos/*`)

### The idea

Three principles do most of the work in this step.

**Presence replaces `enable`.** NixOS has `enable` options because Nixpkgs imports almost every module by default and needs a switch. Your own modules do not; the README lists `enable` options as an anti-pattern for exactly this reason: "In most cases, importing a module should enable the feature that it provides." So `options.cooked.X.enable = mkEnableOption` plus `config = mkIf cfg.enable { ... }` collapses into just the body of `config`. Whether a machine has the feature is decided by whether that machine imports the module.

**Presets become roles.** The `lib.mkDefault true` list in `cooked/nixos/default.nix` was your way of saying "these are on for everyone", and `cooked.preload.desktop` "these too, on desktops". A role says the same thing structurally, with no flags.

**A feature owns all of its side effects, wherever they land.** Today `libvirtd` is in the user's `extraGroups` in `nixos/configuration.nix`, the syncthing firewall ports are in the same file, and the features are elsewhere. In the pattern, the file for "vm" adds the group and the file for "syncthing" opens its ports. Delete the feature and everything it did goes with it.

**Do it in two phases per file, or one if the file is small.**

1. *Wrap* (mechanical, nothing can change): register the legacy file by path and drop its old import line.
2. *Refine* (a small, deliberate change): remove the `enable` option and the `mkIf`.

### In your repository

**The recipe**, per legacy file:

1. Create the new file under `modules/aspects/…` with the body of `config` as a stored module in the right role (or under its own name).
2. Delete the legacy file, its line in the parent `default.nix`'s `imports`, and its `cooked.<x>.enable = mkDefault true` line in `cooked/nixos/default.nix`.
3. Build and compare with your baseline (Step 0).

**The decision for each file:** *does every machine in this role want it?* Yes: merge into `nixos.base` (all machines) or `nixos.desktop` (desktops). Only some: give it a name and import it in those hosts.

**Worked example 1: a plain feature (`fonts`), merged into `base`.**

**your repo** — `cooked/nixos/fonts.nix`

```nix
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.cooked.fonts;
in {
  options.cooked.fonts = {
    enable = lib.mkEnableOption "added fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
    };
  };
}
```

becomes

```nix
# modules/aspects/fonts.nix
{
  flake.modules.nixos.base = {
    lib,
    pkgs,
    ...
  }: {
    fonts.packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  };
}
```

The `options` block, the `cfg`, the `mkIf` and the `enable = mkDefault true` line are gone. `gnupg`, `network`, `locate` and `dbus` are the same recipe.

**Worked example 2: an opt-in feature (`vm`), in two phases, that also owns a side effect.** Nothing enables `cooked.vm` on any host today, so it is a named module that no host imports yet.

Phase 1, *wrap*: nothing changes.

```nix
# modules/aspects/vm.nix   (phase 1)
{rootPath, ...}: {
  flake.modules.nixos.vm = rootPath + "/cooked/nixos/vm.nix";
}
```

Phase 2, *refine*: the `enable` machinery goes, and the `libvirtd` group moves in from `nixos/configuration.nix`, because it is `vm`'s side effect:

```nix
# modules/aspects/vm.nix   (phase 2)
{config, ...}: {
  flake.modules.nixos.vm = {pkgs, ...}: {
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          ovmf.enable = true;
          ovmf.packages = [pkgs.OVMFFull.fd];
        };
      };
      spiceUSBRedirection.enable = true;
    };

    services.spice-vdagentd.enable = true;
    programs.virt-manager.enable = true;
    environment.systemPackages = [pkgs.virtiofsd];
    networking.firewall.trustedInterfaces = ["virbr0"];

    users.users.${config.owner.username}.extraGroups = ["libvirtd"];
  };
}
```

A host that wants it adds `config.flake.modules.nixos.vm` to its `imports`. The `extraGroups` entry is a `listOf str`, so it merges with the groups defined elsewhere.

One thing to be aware of: a feature that touches `users.users.daniel` quietly depends on that user existing, which means a host that imports `vm` must also import `daniel`. That is true of both your hosts, and it is what infra's [`modules/printing.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/printing.nix) accepts too (it adds every user to `lpadmin`). If you ever have a machine without the user, you would not import `vm` there either.

**Worked example 3: a feature that others depend on (`sound`), in the `desktop` role.** `sound.nix` declares your `XF86` option (via the legacy `XF86.nix`) and sets three commands that Hyprland and waybar read through `osConfig`. Keep that mechanism for now (it is a perfectly good *lower-level* option, and Step 8 discusses the alternative). Move the option-declaring file out of `modules.old/` to a `_`-prefixed name where the feature files can share it:

```sh
git mv modules.old/XF86.nix modules/aspects/desktop/_xf86-options.nix
```

The two legacy home-manager files that still import it (they change in Step 8) need their path updated: `daniel/XF86Misc.nix:13` becomes `../modules/aspects/desktop/_xf86-options.nix` and `daniel/programs/music.nix:8` becomes `../../modules/aspects/desktop/_xf86-options.nix`.

```nix
# modules/aspects/desktop/sound.nix
{
  flake.modules.nixos.desktop = {pkgs, ...}: {
    imports = [./_xf86-options.nix];

    XF86 = {
      audioLowerVolume = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      audioMute = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      audioRaiseVolume = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
    };

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      audio.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = builtins.attrValues {inherit (pkgs) pulsemixer pavucontrol;};
  };
}
```

Anything that sets `XF86.*` imports the options file by **path** (as your legacy files did), so it is de-duplicated by path even when several files import it. `printing.nix` and `display-manager.nix` go the same way into `nixos.desktop`.

**Worked example 4: helper packages (`scripts`), plus the `powermenu` fix from the audit.**

```nix
# modules/aspects/scripts.nix
{
  flake.modules.nixos.base = {pkgs, ...}: {
    # was `cooked.scripts.nix-helpers` (default on)
    environment.systemPackages = [pkgs.configure pkgs.update-system];
  };

  # was `cooked.scripts.menus` (default off): nobody imports this yet
  flake.modules.nixos.menus = {pkgs, ...}: {
    environment.systemPackages = [pkgs.powermenu]; # attribute renamed from `power-menu`
  };
}
```

**Worked example 5: a file with an outside dependency (`sops`).** The relative path to `secrets.yaml` changes because the file moved; `secrets.yaml` and `.sops.yaml` stay at the repository root:

```nix
# modules/aspects/sops.nix
{
  config,
  inputs,
  ...
}: {
  flake.modules.nixos.base = {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      defaultSopsFile = ../../secrets.yaml; # two levels up from modules/aspects/
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/${config.owner.username}/.config/sops/age/keys.txt";
    };
  };
}
```

Note that `inputs` is used directly: the file is a top-level module (see Report 1, §2.5). The legacy version needed it as a `specialArgs` argument.

**What else comes out of the two legacy directories.** The rest of `cooked/nixos/default.nix` and `nixos/configuration.nix` splits by feature, not by where it sat. The full file-by-file map is Appendix A; the shape of it is:

| Legacy content | New file | Role |
|---|---|---|
| `ripgrep unzip wget` | `aspects/base-packages.nix` | `nixos.base` |
| time zone, locale, console keymap | `aspects/locale.nix` | `nixos.base` |
| `security.polkit`, `sudo.extraRules`, `ssh.askPassword` | `aspects/security.nix` | `nixos.base` |
| `environment.etc."current-system-packages"` | `aspects/system-package-list.nix` | `nixos.base` |
| syncthing firewall ports and group | `aspects/syncthing.nix` (finished in Step 8: it is cross-class) | `nixos.base` |
| `users.users.daniel` | Step 7 | named `nixos.daniel` |
| `nixos/email/*` | Step 8 (cross-class) | `nixos.base` |

Keep `ssh.askPassword` as the literal it is today while you migrate, and move the `sudo.extraRules` unchanged. Fixing the first (probably by deleting it) and deciding about the second are separate, deliberate changes; notes [N3](03-config-notes.md#n3--a-hard-coded-ksshaskpass-store-path) and [N9](03-config-notes.md#n9--the-sudo-rules-are-passwordless-root) say what to look at, and each should be its own commit after this step.

**Split a host's hardware file into reusable pieces (optional, uses the "host as facets" idea).** `hosts/dellG5/hardware.nix` mixes *facts about one laptop* (disk UUIDs, PCI bus IDs, kernel modules) with *reusable features* (TLP battery settings, `thermald`, bluetooth, NVIDIA PRIME). The facts stay in `_hardware.nix`. The reusable features can become named modules (`nixos.laptop-power`, `nixos.nvidia-prime`) that the host imports and that a second laptop could reuse. Do it when you have a second laptop, not before.

**Checkpoint.** After the last file: `cooked/nixos/` is empty (delete it), `cooked.preload.desktop = true;` is gone from both hosts, and both hosts still build and match the baseline. `cooked/home-manager/` remains until Step 6.

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| Machine features merged into a role | [`modules/audio/pipewire.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/audio/pipewire.nix), [`modules/networking/manager.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/networking/manager.nix), [`modules/printing.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/printing.nix), [`modules/boot.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/boot.nix) | [`modules/system/core/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/core/default.nix) imports `user bootloader nix hardware locale` (files `boot.nix`, `hardware.nix`, `locale.nix`, `nix-settings.nix`, `user.nix`) |
| Named opt-in modules | [`modules/hardware/efi.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/hardware/efi.nix), [`modules/storage/zfs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/storage/zfs.nix), [`modules/hardware/nvidia-gpu.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/hardware/nvidia-gpu.nix) | driver modules named in the host list (`amdDrivers`, `intelDrivers`, `nix-ld`) |
| A feature that owns its side effect on other things | [`modules/printing.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/printing.nix) adds every user to `users.groups.lpadmin` | — |
| Secrets | none (uses a password manager) | [`modules/features/sops/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/sops/default.nix): `sops-nix`, `age.keyFile`, and `defaultSopsFile = ./secrets.yaml` beside the module |
| `enable`-free style | no `enable` options for its own features | same |

---

## Step 6 — Migrate the cross-class features (`cooked/home-manager/*`)

### The idea

This is where the pattern pays off most for you, because **`cooked/home-manager/*.nix` are already cross-class features**. They are just wired together by hand. Look at what it currently takes to say "daniel uses zsh":

1. `cooked/home-manager/zsh.nix`, a *NixOS* module that inspects the evaluated home-manager users (`builtins.any (cfg: cfg.programs.zsh.enable) (builtins.attrValues config.home-manager.users)`) to decide whether to switch on its own system half;
2. the same file, which also injects a *home-manager* module with an `enable` option into every user through `home-manager.sharedModules`;
3. `cooked.zsh.enable = true;` in `users/daniel/default.nix`.

Three places, plus a scan of the lower level from the lower level, to express one fact. In the pattern this is **one file with two stored modules** (README rule 3: the feature is implemented "across all configurations that that feature applies to"). Nothing needs to inspect anything, because *composition* answers the question: the system half is in the role that the host imports, the user half is in the role that the user imports, and both were written by the same person in the same file.

Two smaller ideas come with it:

- **`inputs` needs no `specialArgs`.** The stored module is written inside the top-level function, so it closes over `inputs` (Report 1, §2.5).
- **Presence replaces the toggle on both sides.** The `options.cooked.zsh.enable` in home-manager disappears just like the NixOS one did in Step 5.

### In your repository

**6a. Let the user import the home-manager roles.** As soon as the first home-manager half exists, something must import the role. Update the interim user module from Step 4:

```nix
# modules/users/daniel.nix   (interim: still reworked in Step 7)
{
  config,
  rootPath,
  ...
}: {
  flake.modules.nixos.daniel = {
    home-manager.users.${config.owner.username}.imports = [
      config.flake.modules.homeManager.gui # a role; includes `base` (Step 1)
      (rootPath + "/daniel")
      (rootPath + "/users/daniel")
    ];
  };
}
```

**6b. Migrate one feature at a time, simplest first:** `nix-index`, `git`, `tmux`, `R`, `zsh`, then `hyprland`. For each: create the new file, delete the legacy file and its line in `cooked/home-manager/default.nix`, delete the matching `cooked.<x>.enable` (or `cooked.tmux.conf`) from `users/daniel/default.nix`, build, compare.

**Example A, the simplest (`nix-index`).** Before:

**your repo** — `cooked/home-manager/nix-index.nix`

```nix
{
  inputs,
  config,
  lib,
  ...
}: let
  nix-index_enabled = builtins.any (cfg: cfg.programs.nix-index.enable) (builtins.attrValues config.home-manager.users);
in {
  imports = with inputs.nix-index-database; [
    nixosModules.nix-index
  ];

  config = lib.mkMerge [
    (lib.mkIf nix-index_enabled {
      programs = {
        nix-index.enable = true;
        nix-index-database.comma.enable = true;
      };
    })
    {
      home-manager.sharedModules = [
        ({config, ...}: let
          cfg = config.cooked.nix-index;
        in {
          options.cooked.nix-index = {
            enable = lib.mkEnableOption "nix-index configuration.";
          };

          imports = [
            inputs.nix-index-database.homeModules.nix-index
          ];

          config = lib.mkIf cfg.enable {
            programs.nix-index-database.comma.enable = true;
          };
        })
      ];
    }
  ];
}
```

After. One file, two halves, no scan, no `enable`, and `inputs` used directly:

```nix
# modules/aspects/shell/nix-index.nix
{inputs, ...}: {
  flake.modules.nixos.base = {
    imports = [inputs.nix-index-database.nixosModules.nix-index];
    programs = {
      nix-index.enable = true;
      nix-index-database.comma.enable = true;
    };
  };

  flake.modules.homeManager.base = {
    imports = [inputs.nix-index-database.homeModules.nix-index];
    programs.nix-index-database.comma.enable = true;
  };
}
```

**Example B, `zsh`.** The system half goes to `nixos.base`, the user half to `homeManager.base`. Bodies are moved, not rewritten: cut what was inside each `lib.mkIf … { … }` and paste it as the module body.

```nix
# modules/aspects/shell/zsh.nix
{
  flake.modules.nixos.base = {pkgs, ...}: {
    environment = {
      systemPackages = builtins.attrValues {inherit (pkgs) zsh-powerlevel10k;};
      shells = [pkgs.zsh];

      # ZSH completion
      # Added to allow completion of system packages
      pathsToLink = ["/share/zsh"];
    };

    programs.zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      promptInit = "source ''${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };

  flake.modules.homeManager.base = {config, ...}: {
    programs.zsh = let
      dotDir = "${config.xdg.configHome}/zsh";
    in {
      inherit dotDir;
      enable = true;
      autosuggestion.enable = true;
      defaultKeymap = "viins";
      enableVteIntegration = true;
      history.path = "${config.xdg.stateHome}/zsh/zsh_history";
      envExtra = ''
        # … your existing envExtra, unchanged …
      '';
      initContent = ''
        # … your existing initContent, unchanged …
      '';
    };
  };
}
```

**Example C, `hyprland`.** The largest of the `cooked` features. Three legacy sources say things about Hyprland: the system half and the shared user half (both in `cooked/home-manager/hyprland.nix`), and your personal configuration (`daniel/programs/wayland/hyprland.nix`, Step 8). Only the first two move now. Hyprland is graphical, so both halves go to the *desktop* roles:

```nix
# modules/aspects/desktop/hyprland/default.nix
{inputs, ...}: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    # Hyprland cache
    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    hardware.graphics = let
      ps = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in {
      package = ps.mesa;
      enable32Bit = true;
      package32 = ps.pkgsi686Linux.mesa;
    };

    environment.systemPackages = [pkgs.wl-clipboard];
  };

  flake.modules.homeManager.gui = {
    config,
    pkgs,
    ...
  }: {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;

      systemd = {
        variables = ["--all"];
      };
    };

    systemd.user.services.hyprpolkitagent = {
      Unit = {
        Description = "Hyprland polkit authentication agent";
        PartOf = [config.wayland.systemd.target];
        After = [config.wayland.systemd.target];
      };
      Install.WantedBy = [config.wayland.systemd.target];
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
```

(This is your legacy code with the toggles removed. Whether Hyprland should follow your `nixpkgs`, and what that does to the cache and the `mesa` workaround, is the audit note in "Where you are now".)

**Example D, `git`, `tmux`, `R`.** Same recipe. Identity (`user.name`, `user.email`, signing key) stays in `users/daniel/programs.nix` until Step 7.

```nix
# modules/aspects/shell/git.nix
{
  flake.modules.nixos.base.programs.git.enable = true;

  flake.modules.homeManager.base = {pkgs, ...}: {
    programs.git = {
      enable = true;
      settings = {
        alias = {
          pa = "!git remote | ${pkgs.findutils}/bin/xargs -L1 git push --all";
          cpa = "!f() { git commit \"$@\" && git pa; }; f";
          lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date-order";
        };
        init.defaultBranch = "master";
      };
    };
  };
}
```

```nix
# modules/aspects/shell/tmux.nix
{
  flake.modules.nixos.base = {lib, ...}: {
    programs.tmux = {
      enable = true;
      escapeTime = lib.mkDefault 10;
      keyMode = lib.mkDefault "vi";
      clock24 = lib.mkDefault true;
    };
  };

  flake.modules.homeManager.base = {
    # was `cooked.tmux.conf`, set in users/daniel/default.nix
    xdg.configFile."tmux/tmux.conf".text = ''
      # Vim keys for pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # … the rest of your tmux.conf, unchanged …
    '';
  };
}
```

```nix
# modules/aspects/dev/R.nix
{
  flake.modules.nixos.base = {pkgs, ...}: let
    R_pkgs = builtins.attrValues {
      inherit
        (pkgs.rPackages)
        tidyverse
        writexl
        # Development
        devtools
        roxygen2
        covr
        ;
    };
  in {
    environment.systemPackages = [(pkgs.rWrapper.override {packages = R_pkgs;})];
  };

  flake.modules.homeManager.base = {config, ...}: {
    home = {
      file.".Renviron".text = ''R_LIBS_USER = "${config.xdg.dataHome}/R/x86_64-pc-linux-gnu-library"'';
      sessionVariables = {
        R_HOME_USER = "${config.xdg.configHome}/R";
        R_PROFILE_USER = "${config.xdg.configHome}/R/profile";
        R_PROFILE = "${config.xdg.configHome}/R/profile";
        R_HISTFILE = "${config.xdg.configHome}/R/history";
      };
    };
    xdg.configFile."R/profile".text = ''
      if (interactive()) {
        suppressMessages(require(devtools))
      }
    '';
  };
}
```

**What just happened to the "system half if any user wants it" logic.** It is gone, and that is a (deliberate) behaviour change in principle: the system half is now present on every machine that imports the role, whether or not a user there uses the feature. With one user on two desktops that both want everything, nothing differs. If you later add a machine that should *not* have zsh, that machine would import a smaller role (or none of these), which is the pattern's answer to the question the `builtins.any` scan was answering.

**Checkpoint (M2).** `cooked/` is completely gone (`cooked/default.nix` with `options.cooked.preload.*`, `cooked/nixos/`, `cooked/home-manager/`), and both `(rootPath + "/cooked")` lines are removed from the hosts. Build and compare. Commit.

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| One file, both classes | [`modules/mightyiam/ssh.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/ssh.nix) (`home.base` and `nixos.modules.base`), [`modules/stylix.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/stylix.nix) (`nixos.modules.pc` and `homeManager.modules.base`); at adoption [`modules/nix.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/nix.nix) writes NixOS, home-manager and nix-on-droid modules in a single file | none: voidarc has no home-manager |
| A home-manager-only feature shaped like your `nix-index` | [`modules/shell/nix-index.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/shell/nix-index.nix) (`homeManager.modules.base` with the module import, `programs.nix-index`, and `comma`) | — |
| A value shared by both classes | [`modules/nix/settings.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nix/settings.nix) and [`modules/mightyiam/nix/settings.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/nix/settings.nix) | — |
| `inputs` used directly, not via `specialArgs` | [`modules/stylix.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/stylix.nix) (`inputs.stylix`) | [`modules/features/sops/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/sops/default.nix) (`inputs.sops-nix`), [`modules/features/kitty/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/kitty/default.nix) (`inputs.wrappers`) |
| A program with a NixOS module *and* a package built for it | — | [`modules/features/hyprland/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/hyprland/default.nix) (`programs.hyprland` plus `perSystem.packages.hyprland`) |

---

## Step 7 — The user: account, home-manager wiring, personal settings

### The idea

A user is itself a cross-class feature: a **system account** plus a **home-manager configuration**. The pattern gives it one file, and hosts opt in by name. Two things you built to work around the lower-level scoping then have no reason to exist: `lib.mkHomeUsers` (a helper that imported a file with the host's arguments so that it could be used as a home-manager module) and `extraSpecialArgs` (threading `inputs` into home-manager).

This step also settles the two axes from Report 1, §4.7: *what a feature does* versus *who it is for*. Right now `cooked/` (generic) and `daniel/` (personal) encode that split by directory, and `users/daniel` mixes both. With **one** user, everything is simply a feature and the split is artificial; the path-independence benefit means you can introduce a per-user tree later (as infra's `modules/mightyiam/` and `modules/bow/`) by moving files, not by rewriting them.

### In your repository

**7a. The user module, final form.** Before, the pieces were spread across `nixos/configuration.nix` (the account), `users/daniel/default.nix` (home settings), `users/daniel/programs.nix`, `hosts/*/default.nix` (`mkHomeUsers`) and the old `flake.nix`:

```nix
# modules/users/daniel.nix
{
  config,
  rootPath,
  ...
}: let
  inherit (config) owner;
in {
  # ── system side: the account, plus its home-manager configuration ──────────
  flake.modules.nixos.daniel = {pkgs, ...}: {
    users.users.${owner.username} = {
      shell = pkgs.zsh;
      isNormalUser = true;
      description = owner.name;
      extraGroups = [
        "video"
        "networkmanager"
        "wheel"
        "adbusers"
        # "libvirtd" now lives in aspects/vm.nix, "syncthing" in aspects/syncthing.nix
      ];
    };

    home-manager.users.${owner.username}.imports = [config.flake.modules.homeManager.daniel];
  };

  # ── home-manager side: what is specific to this user ───────────────────────
  flake.modules.homeManager.daniel = {pkgs, ...}: {
    imports = [
      config.flake.modules.homeManager.gui # a role; includes `base`
      (rootPath + "/daniel") # LEGACY: empties out in Step 8, then delete this line
    ];

    home = {
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
  };
}
```

Notes:

- `home.username` and `home.homeDirectory` are gone from this list on purpose: home-manager's NixOS module already sets them from `users.users.<name>` (its `nixos/common.nix`), so your explicit copies were redundant. Two equal definitions were harmless, one is tidier.
- The package list is a *placeholder for now*. Each package that belongs to a feature moves with that feature in Step 8 (`yt-dlp`, `ffmpeg-full` to media; `alegreya*` to fonts; `keepassxc` next to the browser). What remains is genuinely "Daniel's odds and ends" and can stay here.
- This module replaces the interim one from Steps 4 and 6. Of the two legacy trees it used to import, `users/daniel` is fully absorbed by 7b and disappears in this step; `daniel/` stays wrapped (the `rootPath + "/daniel"` line) until Step 8 empties it.
- Your commented-out `home.packages` entries (`ferdium`, `musescore`, `nitch`, …) are omitted here for brevity; keep them if you want them.
- `"adbusers"` is carried over unchanged. That group no longer exists in your nixpkgs (`programs.adb` was removed), so the entry does nothing; note [N10](03-config-notes.md#n10--the-adbusers-group-no-longer-exists) says what to do with it.

**7b. Where the rest of `users/daniel/*` goes.**

| Legacy | New home | Role |
|---|---|---|
| `programs.home-manager.enable = true` | `modules/home-manager.nix`: `flake.modules.homeManager.base.programs.home-manager.enable = true;` (infra does exactly this) | `homeManager.base` |
| `programs.git.settings.user.{email,name}`, `signing.{key,signByDefault}` | into `aspects/shell/git.nix` (below) | `homeManager.base` |
| `programs.mpv` (with sponsorblock), its desktop entry and `mimeApps` | `aspects/media/mpv.nix` | `homeManager.gui` |
| `xdg.enable`, `xdg.userDirs`, cache/config/data/state homes, `mimeApps` | `aspects/xdg.nix` | `homeManager.base` |
| `cooked = { … }` block | already gone (Step 6) | — |
| `home.packages`, `home.pointerCursor` | the module above, or with their feature | `homeManager.daniel` |

The identity lines join the git feature from Step 6. Note `config` in the *outer* function (the flake-parts config) versus `pkgs` in the inner one, and that `lib.mkDefault` keeps them overridable per host, as they were:

```nix
# modules/aspects/shell/git.nix   (Step 6's file, extended)
{
  config,
  lib,
  ...
}: {
  flake.modules.nixos.base.programs.git.enable = true;

  flake.modules.homeManager.base = {pkgs, ...}: {
    programs.git = {
      enable = true;
      settings = {
        alias = {
          # … as in Step 6 …
        };
        init.defaultBranch = "master";
        user = {
          name = config.owner.name;
          email = lib.mkDefault config.owner.email;
        };
      };
      signing = {
        key = lib.mkDefault "08218B96DC7385E5BB7CA535D2643BD213BC0FA8";
        signByDefault = true;
      };
    };
  };
}
```

**7c. Delete `users/`.** Remove `(rootPath + "/users/daniel")` from the module, delete the directory, and remove the `mkHomeUsers` call (already gone from the hosts since Step 4). `nixos/configuration.nix` has now lost its account; the rest of it goes in Step 5's table and Step 8.

**Checkpoint.** `users/` is gone; the hosts still `imports = [ … config.flake.modules.nixos.daniel ]`; both build and match the baseline. Commit.

**If a second user ever arrives.** Name their module `flake.modules.nixos.<user>` and give each host the users it wants. If the number of users grows, this is the point at which infra's typed `users.<name>` submodule (four slots, Report 1, §4.5) starts to pay for itself.

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| A user as one cross-class unit | [`modules/users.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/users.nix): typed `users.<name>` with `nixos.base`/`nixos.pc` and `home.base`/`home.gui`; wired per user in [`modules/mightyiam/nixos.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/nixos.nix) and [`modules/mightyiam/home.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/home.nix) | [`modules/system/core/user.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/core/user.nix): the `user01` account and its shell, one file |
| home-manager wired into NixOS | [`modules/home-manager.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/home-manager.nix) (roles, `sharedModules` with `osConfig`); at adoption [`modules/home-manager.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/home-manager.nix) (`useGlobalPkgs`, `users.${owner}.imports = [ homeManager.home ]`) | none: no home-manager |
| Shared identity | `users.<name>.{name,email}` set in [`modules/mightyiam/name.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/name.nix) and read by [`modules/mightyiam/git/basics.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/git/basics.nix); at adoption [`modules/owner.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/owner.nix) | hard-coded in the git feature |
| `stateVersion` | one line, `home.stateVersion = osConfig.system.stateVersion`, for all users ([`modules/home-manager.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/home-manager.nix)) | — |
| A second user's differences | [`modules/bow/browsers.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/bow/browsers.nix), [`modules/bow/desktop-environment.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/bow/desktop-environment.nix) | — |
| Shared home-manager base for every user | [`modules/xdg/dirs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/xdg/dirs.nix) (`homeManager.modules.base`) | — |

---

## Step 8 — Peel the personal home-manager tree (`daniel/**`) into features

### The idea

`daniel/` is organised by *kind of thing* (`programs/`, `shell/`, `email/`, `scripts/`, …), and several files mix concerns (`music.nix` holds an MPD service, a player's key bindings, a tagger and the XF86 media keys). The pattern's unit is the **feature**, and the README's rule 4 says the path should *name* it. So this step is mostly about drawing better boundaries:

- **Split by feature, not by file type.** "Music" is one feature even though it touches `services`, `programs` and `xdg.configFile`. "Email" is one feature even though half of it is system packages and half is home-manager.
- **Split big features into facets.** A feature may be a directory of small files that each add a piece to the *same* stored module. It works because most home-manager options merge (`lines`, lists, attrsets).
- **Keep what a feature needs next to it.** Assets, helper functions and the overlay for its package live beside it.
- **Data and helper files are not modules.** They get a `_` prefix (Step 2), or they are inlined.
- **Dead code is deleted, not moved.**

Use the same per-file recipe as Step 6: create the new file, delete the legacy one and its `imports` line in its parent `default.nix`, build, compare. Suggested order, easiest first: shell, small programs, media, email, browsers, then the desktop (Hyprland, waybar, wofi, wallpapers).

### In your repository

**8a. Data files become inline (or `_`-prefixed).** `daniel/shell/default.nix` does `home.shellAliases = import ./aliases.nix {inherit lib pkgs;}`. `aliases.nix` is a bare attrset, which would be misread as config if import-tree saw it. It has exactly one consumer, so inline it:

```nix
# modules/aspects/shell/aliases.nix
{
  flake.modules.homeManager.base = {
    lib,
    pkgs,
    ...
  }: let
    p = pkgs.writeShellScript "dl-ls" ''
      ${pkgs.lsd}/bin/lsd -v --group-dirs first $* && echo "$(${pkgs.lsd}/bin/lsd $* | wc -l) items"
    '';
  in {
    home.shellAliases = {
      sudo = "sudo ";

      ls = "${lib.getBin p} ";
      la = "ls -A";
      ll = "ls -lA";

      # … the rest of your aliases, unchanged …
    };
  };
}
```

`daniel/programs/browsers/bookmarks.nix` (a function returning a list, used with `import ./bookmarks.nix inputs`) has the same problem. Rename it `_bookmarks.nix` and keep the `import`. The three `nixos/email/*.nix` script files (`{pkgs}: pkgs.writeShellScriptBin …`) likewise become `_sync-email.nix`, `_get-mailboxes.nix` and `_neomutt-account-switcher.nix`.

**8b. Options declared inside a home-manager module stay inside it.** `daniel/shell/terminal.nix` declares `options.programs.terminal` and also sets kitty and alacritty. That is fine in this pattern: infra declares `options.terminal`, `options.pinentry` and `options.audio.sinkNameMap` *inside* its `home.gui`/`home.base` modules, and other files set them. You only wrap it:

```nix
# modules/aspects/shell/terminal.nix
{
  flake.modules.homeManager.gui = {
    config,
    lib,
    pkgs,
    ...
  }: let
    col = config.colorScheme.palette;
  in {
    options.programs.terminal = lib.mkOption {
      type = lib.types.str;
      description = "Your default terminal";
      example = "''${pkgs.kitty}/bin/kitty"; # (verbatim from your file)
    };

    config = {
      programs = {
        terminal = "${pkgs.kitty}/bin/kitty";
        kitty = {
          enable = true;
          extraConfig = ''
            # … your kitty config, unchanged …
          '';
        };
        # … alacritty, unchanged …
      };

      home.sessionVariables.TERMINAL = "xterm-256color";
      home.sessionVariables.TERM = "xterm-256color";
    };
  };
}
```

(`config.colorScheme.palette` here is the *home-manager* `config`. It does not change; the feature that provides `colorScheme` is a sibling file, `aspects/desktop/colours.nix`, which imports `inputs.nix-colors.homeManagerModules.default` and sets `colorScheme` in `homeManager.base`.)

**8c. A feature owns its overlay.** `daniel/shell/editor.nix` is the only consumer of `pkgs.my_neovim`, so the overlay from Step 3 moves in with it and is applied wherever the editor is wanted. This is the pattern's locality principle in one file: an overlay, a NixOS effect and a home-manager module.

```nix
# modules/aspects/shell/editor.nix
{
  config,
  inputs,
  ...
}: {
  flake.overlays.my-neovim = final: prev: {
    my_neovim = inputs.my_neovim.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  # applied on every machine that has this feature (`base` = all of them)
  flake.modules.nixos.base.nixpkgs.overlays = [config.flake.overlays.my-neovim];

  flake.modules.homeManager.base = {pkgs, ...}: {
    home = {
      packages = [pkgs.my_neovim];
      sessionVariables = {
        EDITOR = "${pkgs.my_neovim}/bin/nvim";
        SUDO_EDITOR = "${pkgs.my_neovim}/bin/nvim";
      };
    };

    xdg = {
      desktopEntries.neovim = {
        name = "Neovim";
        genericName = "Text Editor";
        comment = "Hyperextensible Vim-based text editor";
        exec = "${pkgs.my_neovim}/bin/nvim %U";
        terminal = true;
        categories = ["Utility" "TextEditor" "ConsoleOnly"];
        mimeType = ["text/*"];
      };
      mimeApps.defaultApplications."text/*" = "neovim.desktop";
    };
  };
}
```

After this, delete the `my-neovim` entry from `modules/nixpkgs/overlays.nix` and from its list. Do the same for `ffmpeg-unfree` (next to a `media/ffmpeg.nix` feature that also takes `ffmpeg-full` from your package list and the `ffgetmd`/`ffsetmd` scripts) and `stable` (next to the WSL host).

**8d. A cross-class feature, small: `syncthing`.** Its parts were in three places: the firewall ports and the `syncthing` group in `nixos/configuration.nix`, and `services.syncthing.enable` in `daniel/programs/syncthing.nix`.

```nix
# modules/aspects/syncthing.nix
{config, ...}: {
  flake.modules.nixos.base = {
    networking.firewall = {
      allowedTCPPorts = [22000];
      allowedUDPPorts = [21027 22000];
    };
    users.users.${config.owner.username}.extraGroups = ["syncthing"];
  };

  flake.modules.homeManager.base.services.syncthing.enable = true;
}
```

**8e. A cross-class feature, large: `email`.** `nixos/email/default.nix` installs the tools and scripts system-wide; `daniel/email/{default,accounts,pass,neomutt}.nix` configure accounts and programs. One directory, both classes, assets beside it:

```text
modules/aspects/email/
├── default.nix        NixOS: packages + scripts.   home-manager: mbsync, msmtp, notmuch, thunderbird
├── accounts.nix       home-manager: accounts.email.*       (reads config.owner for the real name)
├── pass.nix           home-manager: programs.password-store
├── neomutt.nix        home-manager: programs.neomutt + desktop entry;  source = ./neomutt
├── neomutt/           the rc files, unchanged (assets: import-tree ignores non-.nix files)
└── _sync-email.nix  _get-mailboxes.nix  _neomutt-account-switcher.nix     helper functions
```

```nix
# modules/aspects/email/default.nix
{
  flake.modules.nixos.base = {pkgs, ...}: {
    # was nixos/email/default.nix
    environment.systemPackages =
      builtins.attrValues {
        inherit (pkgs) neomutt isync msmtp pass curl lynx gnupg notmuch;
      }
      ++ [
        (import ./_sync-email.nix {inherit pkgs;})
        (import ./_get-mailboxes.nix {inherit pkgs;})
        (import ./_neomutt-account-switcher.nix {inherit pkgs;})
      ];
  };

  flake.modules.homeManager.base = {
    # was daniel/email/default.nix
    programs = {
      mbsync.enable = true;
      msmtp.enable = true;
      notmuch.enable = true;
      thunderbird = {
        enable = true;
        profiles.daniel.isDefault = true;
      };
    };
  };
}
```

`accounts.nix`, `pass.nix` and `neomutt.nix` are moved with the same one-line change: wrap the body in `flake.modules.homeManager.base = { … }: …`. The `neomutt` directory moves *next to* `neomutt.nix`, so `source = ./neomutt` keeps working.

**8f. A big feature in facets: Hyprland.** The personal `daniel/programs/wayland/hyprland.nix` is one 190-line `extraConfig` string. `wayland.windowManager.hyprland.extraConfig` is a `lines` option (home-manager's `hyprland/default.nix`), and `lines` from several files are concatenated. So the block can be split into files by concern, exactly as infra splits its window manager across `core.nix`, `background.nix`, `layout.nix`, `displays.nix`, `screenlock.nix`, and so on:

```text
modules/aspects/desktop/hyprland/
├── default.nix        (Step 6) NixOS half + shared home-manager half
├── wallpaper.nix      hyprpaper + the wallpapers/ directory beside it
├── monitors.nix       `monitor = …`
├── look.nix           general { … } decoration { … } animations { … }
├── input.nix          input { … } gestures
├── keybinds.nix       the `bind = …` lines, including the XF86 ones
└── _hyprpaper.nix     your custom `programs.hyprpaper` module (was modules.old/hyprpaper.nix)
```

```nix
# modules/aspects/desktop/hyprland/wallpaper.nix
{
  flake.modules.homeManager.gui = {
    imports = [./_hyprpaper.nix];

    programs.hyprpaper = {
      enable = true;
      wallpaper = ./wallpapers; # the directory moved here with the feature (was daniel/wallpapers)
    };

    wayland.windowManager.hyprland.extraConfig = ''
      exec-once = hyprpaper
    '';
  };
}
```

> **Order.** Definitions of a `lines` option are concatenated in module order. import-tree lists files depth-first in name order (it uses `builtins.readDir`), so for a given directory that is alphabetical. Hyprland cares about order for some things: `$MOD = SUPER` must come *before* the binds that use it. Give order-sensitive pieces an explicit position with `lib.mkBefore`, `lib.mkAfter` or `lib.mkOrder <n>`:
>
> ```nix
> # modules/aspects/desktop/hyprland/variables.nix
> {
>   flake.modules.homeManager.gui = {lib, ...}: {
>     wayland.windowManager.hyprland.extraConfig = lib.mkBefore ''
>       $MOD = SUPER
>     '';
>   };
> }
> ```
>
> (infra uses `lib.mkOrder 550` for the same reason in [`modules/mightyiam/shell/completion.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/shell/completion.nix).) If splitting feels like more work than it is worth, keep `hyprland.nix` as one file: the pattern does not ask you to split, only allows it.

Your `zsh` feature can be split the same way if you want: infra's [shell/](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/shell/zsh.nix) directory is a dozen tiny files (`autocd`, `autosuggestion`, `completion`, `history`, `prompt`, `syntax-highlighting`, …), each a few lines.

**8g. XF86, the value that crosses classes.** Today NixOS sets `XF86.audio*` (in `sound.nix`), home-manager sets more (`music.nix`, `XF86Misc.nix`), and Hyprland and waybar read both, through `config.XF86` and `osConfig.XF86`. There are two good ways to carry on:

- **Keep it (recommended for now).** Both classes get the option from the one shared file (`aspects/desktop/_xf86-options.nix`, Step 5). Each feature that sets `XF86.*` imports it by path, as it did before. Nothing else changes, and the closure is identical.
- **Make it a top-level value** (a refinement, if you want it). One file declares the vocabulary, and each feature contributes; because a command needs `pkgs`, the values are functions of `pkgs`, just as infra's `wayland.sessions = pkgs: [...]` (Report 1, §3.4):

```nix
# modules/aspects/desktop/keys.nix   (optional refinement)
{lib, ...}: {
  options.keys = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.functionTo lib.types.str);
    default = {};
    description = "Shell commands for hardware keys. Each is a function of `pkgs`.";
  };

  config.keys.audioMute = pkgs: "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
}
```

  Consumers write `config.keys.audioMute pkgs` inside their NixOS/home-manager module, where `config` is the *outer* flake-parts config. This removes `osConfig` and the two option namespaces, at the price of one more concept.

**8h. Dead code.** Delete `daniel/programs/X11/{rofi,sxhkd,sxiv}.nix` and `nixos/programs.nix` (imported by nothing today). `picom.nix` is imported but has `services.picom.enable = false`: keep it if you might re-enable it, otherwise delete it, but decide *before* it lands under `modules/`.

**Checkpoint (M3).** `daniel/`, `users/`, `nixos/`, `hosts/` and `modules.old/` are empty and deleted; the `(rootPath + "/daniel")` line is gone. Build both hosts and compare with the baseline. Commit.

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| A feature as a directory of facets | `modules/mightyiam/window-manager/`: [`modules/mightyiam/window-manager/core.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/window-manager/core.nix), [`modules/mightyiam/window-manager/background.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/window-manager/background.nix), [`modules/mightyiam/window-manager/session.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/window-manager/session.nix), … all add to `home.gui` | one file per app: [`modules/features/hyprland/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/hyprland/default.nix) |
| A shell configured in tiny facets | `modules/mightyiam/shell/*.nix` (11 files) | one file: [`modules/features/zsh/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/zsh/default.nix) |
| An option declared *inside* a home-manager module | [`modules/mightyiam/audio.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/audio.nix) (`options.audio.sinkNameMap`), [`modules/mightyiam/pinentry.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/pinentry.nix), [`modules/mightyiam/terminal/default.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/terminal/default.nix) | — |
| Terminal and browser features | [`modules/mightyiam/terminal/alacritty.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/terminal/alacritty.nix), [`modules/mightyiam/web-browsers/firefox.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/web-browsers/firefox.nix) | [`modules/features/kitty/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/kitty/default.nix) (a wrapped package) |
| A helper package for a feature | [`modules/mightyiam/window-manager/hyprcwd.pkg.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/window-manager/hyprcwd.pkg.nix) | defined inline with the feature |
| A shared home-manager base | [`modules/xdg/dirs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/xdg/dirs.nix) (`homeManager.modules.base`) | — |
| A colour scheme | [`modules/mightyiam/style/color-scheme.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/style/color-scheme.nix) (per user; your `colorScheme`) | `features/hyprlock/mocha.conf`, per app |
| Assets next to a feature | `computers/*.facter.json`, `banner/image.jpg` | `features/otter-launcher/config.toml`, `features/hyprlock/{cat.png,mocha.conf}` |

---

## Step 9 — Remove the scaffolding; update CI and the README

### The idea

A migration is not finished while its temporary parts are still there, and the temporary parts are precisely the tell-tale signs of the old world: `specialArgs`, `extraSpecialArgs`, paths into legacy directories. The README's second anti-pattern, "`specialArgs` pass-thru", is only truly gone when nothing needs it. After this step the only ways a value reaches a lower-level module are the ones in Report 1, §2.5: the enclosing function's arguments, typed top-level options and `_module.args`.

### In your repository

**9a. Delete the two temporary `inputs` channels and rebuild.** Remove `specialArgs = {inherit inputs;};` from `modules/hosts/nixos-configurations.nix` and `extraSpecialArgs = {inherit inputs;};` from `modules/home-manager.nix`. If a build now fails with `attribute 'inputs' missing`, a lower-level module is still asking for `inputs` as its *own* argument. Move the argument to the enclosing top-level function (Report 1, §2.5).

**9b. Remove what is now unused.** `grep -rn rootPath modules` should show only its definition in `modules/repository/parts.nix`; if so, delete that line (infra declares it and never reads it either). Delete `cooked/`, `daniel/`, `hosts/`, `nixos/`, `users/` and `modules.old/` if any are left; `templates/default.nix` was replaced by `modules/repository/templates.nix` in Step 2.

**9c. CI.** `.github/workflows/verify_configurations.yml` needs no change *for the migration*: it builds a matrix from `nix flake show --json | jq '.nixosConfigurations | keys'`, and the assembler makes that key exist again. `formatting.yml` (`alejandra -c .`) and `update.yml` are unaffected too. None of the three is free of problems, though: note [N5](03-config-notes.md#n5--ci-workflows) lists six, including a step in `update.yml` that can never re-apply commits, an unpinned action in `verify_configurations.yml`, and a formatting check that could use the `formatter` you add in Step 2.

**9d. A template for new features.** voidarc keeps `modules/empty.nix` so a new feature starts from a known shape. Yours should start with an underscore so import-tree ignores it:

```nix
# modules/aspects/_template.nix   (copy to modules/aspects/<area>/<feature>.nix)
{
  # goes into every machine of a role: `base`, or `desktop` for desktops
  flake.modules.nixos.base = {pkgs, ...}: {
    # environment.systemPackages = [pkgs.hello];
  };

  # and/or the user's home-manager side: `base`, or `gui` for graphical sessions
  flake.modules.homeManager.base = {pkgs, ...}: {
    # programs.hello.enable = true;
  };
}
```

**9e. The README.** Replace the "Refactor" notes with the four facts a future you needs: what `modules/` contains, that every file is a flake-parts module, how to add a feature (copy the template), a host (copy `modules/hosts/wsl/default.nix`) or a user. infra generates its README from fragments contributed by modules; a hand-written page is fine.

**9f. Final comparison.** Run Step 0's comparison one last time for both hosts. The only differences should be the ones you chose (Step 0, item 3). Then you are done.

**Checkpoint (M4).** No `specialArgs`, no legacy paths, no legacy directories, hosts build, closures match the baseline apart from your deliberate changes, CI is green.

### In the examples

| Concept | infra | voidarc |
|---|---|---|
| No `specialArgs` | none anywhere; `_module.args` only for helpers | none |
| A template for a new feature | (README) | [`modules/empty.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/empty.nix) |
| README | generated: [`modules/docs/readme.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/docs/readme.nix) plus fragments such as [`modules/docs/dendritic.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/docs/dendritic.nix) | hand-written, describes the four directories |
| CI/checks | every host is a `flake.checks` entry; `all-check-store-paths` | — |

---

## Step 10 (optional) — Going further

None of this is needed for the pattern. These are the natural next moves, roughly in the order they pay off:

1. **Graduate from flavour B to C** (typed options). Declare `nixos.modules.base` / `desktop` with `apply = module: {key = "..."; imports = [module];}` so roles are safe to import through several paths, and declare a `nixos.configurations` registry. Feature files change only in the attribute path (`flake.modules.nixos.base` becomes `nixos.modules.base`). See infra's [`modules/nixos/base.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos/base.nix), [`modules/nixos.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos.nix).
2. **A host-level feature list** (drupol): a helper that takes `["base" "desktop" "vm"]` and resolves each name in *both* classes, so hosts read like a menu. See the reading list in Report 1.
3. **Checks for every host**, so `nix flake check` alone is the gate (infra's `flake.checks` in [`modules/nixos.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos.nix)). Your CI matrix already builds them, so this only duplicates work unless you want a single command.
4. **One shared `pkgs`** for `perSystem` and NixOS (infra's [`modules/nixpkgs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixpkgs.nix)), so a package built for `nix build` and the one in your system are the same derivation.
5. **`flake-file`**: inputs declared inside the modules that use them, `flake.nix` generated. It is the pattern's natural next step for *inputs*, though not part of it.
6. **treefmt, statix and git hooks** (infra's `modules/repository/{formatting,linting,git/hooks}.nix`).
7. **A per-user tree** the day a second user arrives: `modules/users/<name>/…` with that user's preferences, as infra's `modules/mightyiam/` and `modules/bow/`.

---

## Appendix A — File-by-file migration map

Every tracked `.nix` file in the repository as of commit `0e29b82`, with where its content ends up. *Class/role* uses: **N** = NixOS, **H** = home-manager, followed by the role or name (`base`, `desktop`, `gui`, or a named module). *T* = top-level only. *pkg* = `perSystem.packages`. Paths under `modules/aspects/` are abbreviated `A/`. All destinations are suggestions: the pattern gives every path a free choice (README, "File path independence").

### Root, plumbing and packages

| Current | Destination | Class/role | Step | Notes |
|---|---|---|---|---|
| `flake.nix` | stays | entry point | 2 | `outputs` becomes one line; `rootPath` and `systems` move to `modules/repository/parts.nix` |
| `modules/devshell.nix` | `modules/repository/devshell.nix` | T (perSystem) | 2 | move is optional; no content change |
| `modules/aspects/nix.nix` | `A/nix.nix` | N base | 1 | drop `moduleWithSystem` and `hostPlatform` (audit item 1) |
| `modules/aspects/development/development.nix` | `A/development.nix` | N base | 1 | |
| `modules/pkgs/configure/configure.nix` | unchanged | pkg | 3 | reached through the `packages` overlay as `pkgs.configure` |
| `modules/pkgs/power-menu/power-menu.nix` | unchanged | pkg | 3 | attribute is `powermenu` |
| `modules/pkgs/stag.nix` | unchanged | pkg | 3 | |
| `modules/pkgs/update-system/update-system.nix` | unchanged | pkg | 3 | |
| `templates/default.nix` | `modules/repository/templates.nix` | T | 2 | delete the old file |
| `templates/java/flake.nix`, `templates/rust/flake.nix` | unchanged | (outside `modules/`) | 2 | must stay out of `modules/` |
| `modules.old/XF86.nix` | `A/desktop/_xf86-options.nix` | option module for N and H | 5 | imported by path from each feature that sets `XF86.*` |
| `modules.old/hyprpaper.nix` | `A/desktop/hyprland/_hyprpaper.nix` | H option module | 8 | imported by `wallpaper.nix` |
| *(new)* | `modules/repository/{parts,formatter,templates,owner}.nix`, `modules/nixpkgs/overlays.nix`, `modules/roles.nix`, `modules/home-manager.nix`, `modules/hosts/nixos-configurations.nix`, `A/system-revision.nix` | T / N base | 1 to 4 | see the steps |

### `cooked/`

| Current | Destination | Class/role | Step | Notes |
|---|---|---|---|---|
| `cooked/default.nix` | deleted | — | 6 | `options.cooked.preload.*` replaced by roles |
| `cooked/nixos/default.nix` | split: `A/base-packages.nix`, `A/locale.nix`; the `enable` lines vanish | N base | 5 | the `preload.desktop` block is replaced by the `desktop` role |
| `cooked/nixos/fonts.nix` | `A/fonts.nix` | N base | 5 | |
| `cooked/nixos/gnupg.nix` | `A/gnupg.nix` | N base | 5 | |
| `cooked/nixos/network.nix` | `A/network.nix` | N base | 5 | |
| `cooked/nixos/scripts.nix` | `A/scripts.nix` | N base; N named `menus` | 5 | `pkgs.power-menu` becomes `pkgs.powermenu` |
| `cooked/nixos/services/default.nix` | deleted | — | 5 | was an import list |
| `cooked/nixos/services/dbus.nix` | `A/dbus.nix` | N base | 5 | |
| `cooked/nixos/services/locate.nix` | `A/locate.nix` | N base | 5 | |
| `cooked/nixos/services/display-manager.nix` | `A/desktop/display-manager.nix` | N desktop | 5 | keep the `sddm-chili` derivation in a `let` |
| `cooked/nixos/services/printing.nix` | `A/desktop/printing.nix` | N desktop | 5 | |
| `cooked/nixos/services/sound.nix` | `A/desktop/sound.nix` | N desktop | 5 | imports `./_xf86-options.nix` |
| `cooked/nixos/sops.nix` | `A/sops.nix` | N base | 5 | `defaultSopsFile = ../../secrets.yaml;` |
| `cooked/nixos/vm.nix` | `A/vm.nix` | N named `vm` | 5 | owns the `libvirtd` group |
| `cooked/home-manager/default.nix` | deleted | — | 6 | only enabled git and tmux by default |
| `cooked/home-manager/git.nix` | `A/shell/git.nix` | N base + H base | 6, 7 | identity joins in Step 7 |
| `cooked/home-manager/hyprland.nix` | `A/desktop/hyprland/default.nix` | N desktop + H gui | 6 | |
| `cooked/home-manager/nix-index.nix` | `A/shell/nix-index.nix` | N base + H base | 6 | |
| `cooked/home-manager/R.nix` | `A/dev/R.nix` | N base + H base | 6 | |
| `cooked/home-manager/tmux.nix` | `A/shell/tmux.nix` | N base + H base | 6 | `cooked.tmux.conf` text moves in |
| `cooked/home-manager/zsh.nix` | `A/shell/zsh.nix` | N base + H base | 6 | optional facets, Step 8f |

### `nixos/`, `hosts/`, `users/`

| Current | Destination | Class/role | Step | Notes |
|---|---|---|---|---|
| `nixos/configuration.nix` | split: `modules/users/daniel.nix` (account), `A/syncthing.nix` (ports), `A/security.nix` (polkit, sudo, askpass), `A/system-package-list.nix` (`current-system-packages`), `A/email/` | mixed | 5, 7, 8 | keep the `askPassword` literal until you fix it deliberately |
| `nixos/email/default.nix` | `A/email/default.nix` | N base | 8 | |
| `nixos/email/get-mailboxes.nix` | `A/email/_get-mailboxes.nix` | helper function | 8 | `_` prefix |
| `nixos/email/neomutt-account-switcher.nix` | `A/email/_neomutt-account-switcher.nix` | helper function | 8 | `_` prefix |
| `nixos/email/sync-email.nix` | `A/email/_sync-email.nix` | helper function | 8 | `_` prefix |
| `nixos/programs.nix` | deleted | — | 8 | imported by nothing |
| `hosts/dellG5/default.nix` | `modules/hosts/dellG5/default.nix` | N host module | 4 | `nixpkgs.hostPlatform` added |
| `hosts/dellG5/hardware.nix` | `modules/hosts/dellG5/_hardware.nix` | N (imported by the host) | 4 | optional facet split, Step 5 |
| `hosts/wsl/default.nix` | `modules/hosts/wsl/default.nix` | N host module | 4 | |
| `hosts/wsl/home.nix` | merged into the WSL host | N host module | 4 | `home-manager.users.daniel.programs.git.package` |
| `users/daniel/default.nix` | `modules/users/daniel.nix` | N named `daniel` + H named `daniel` | 6, 7 | `cooked.*` block already gone; tmux text to `tmux.nix` |
| `users/daniel/programs.nix` | `A/shell/git.nix`, `A/media/mpv.nix`, `A/xdg.nix`, `modules/home-manager.nix` | H base / gui | 7 | see the table in Step 7b |

### `daniel/` (personal home-manager tree)

| Current | Destination | Class/role | Step | Notes |
|---|---|---|---|---|
| `daniel/default.nix` | `A/desktop/colours.nix` | H base | 8 | imports `nix-colors` and sets `colorScheme`; the `imports` list disappears |
| `daniel/XF86Misc.nix` | `A/desktop/xf86-misc.nix` | H gui | 8 | imports `_xf86-options.nix` by path |
| `daniel/email/default.nix` | `A/email/default.nix` (home-manager half) | H base | 8 | |
| `daniel/email/accounts.nix` | `A/email/accounts.nix` | H base | 8 | can read `config.owner.name` |
| `daniel/email/neomutt.nix` | `A/email/neomutt.nix` | H base | 8 | `source = ./neomutt;` |
| `daniel/email/pass.nix` | `A/email/pass.nix` | H base | 8 | |
| `daniel/programs/default.nix` | deleted | — | 8 | was an import list |
| `daniel/programs/browsers/default.nix` | `A/browsers/default.nix` | H gui | 8 | uses `pkgs.nur` (overlay from `base`) |
| `daniel/programs/browsers/bookmarks.nix` | `A/browsers/_bookmarks.nix` | data (function returning a list) | 8 | `_` prefix; still `import ./_bookmarks.nix …` |
| `daniel/programs/dunst.nix` | `A/desktop/dunst.nix` | H gui | 8 | |
| `daniel/programs/music.nix` | `A/media/music.nix` | H gui | 8 | mpd, ncmpcpp, beets and the media `XF86` keys |
| `daniel/programs/picom.nix` | `A/desktop/picom.nix`, or delete | H gui | 8 | `services.picom.enable = false` today: decide first |
| `daniel/programs/syncthing.nix` | `A/syncthing.nix` (home-manager half) | H base | 8 | cross-class with the NixOS ports |
| `daniel/programs/wayland/hyprland.nix` | `A/desktop/hyprland/{wallpaper,monitors,look,input,keybinds}.nix` | H gui | 8 | facets; watch the order of `$MOD` |
| `daniel/programs/wayland/waybar.nix` | `A/desktop/waybar.nix` | H gui | 8 | reads `osConfig.XF86.audioMute` |
| `daniel/programs/wayland/wofi.nix` | `A/desktop/wofi.nix` | H gui | 8 | |
| `daniel/programs/X11/rofi.nix` | **delete** | — | 8 | imported by nothing |
| `daniel/programs/X11/sxhkd.nix` | **delete** | — | 8 | imported by nothing |
| `daniel/programs/X11/sxiv.nix` | **delete** | — | 8 | imported by nothing |
| `daniel/programs/yazi.nix` | `A/shell/yazi.nix` | H base | 8 | `enableZshIntegration` |
| `daniel/programs/zathura.nix` | `A/desktop/zathura.nix` | H gui | 8 | |
| `daniel/scripts/default.nix` | deleted | — | 8 | was an import list |
| `daniel/scripts/ffmd.nix` | `A/media/ffmd.nix` | H base | 8 | (or `perSystem.packages`, since they are `writeShellApplication`s) |
| `daniel/shell/default.nix` | `A/shell/env-vars.nix` | H base | 8 | `home.sessionVariables`; drop the `imports` and the `aliases` import |
| `daniel/shell/aliases.nix` | `A/shell/aliases.nix` (inlined) | H base | 8 | a bare attrset, so never as a top-level module |
| `daniel/shell/editor.nix` | `A/shell/editor.nix` | N base overlay + H base | 8 | carries the `my-neovim` overlay |
| `daniel/shell/terminal.nix` | `A/shell/terminal.nix` | H gui | 8 | declares `programs.terminal` |

### Non-Nix files that move with their feature

| Current | Destination |
|---|---|
| `daniel/email/neomutt/**` (rc files, `accounts/*`, `mailcap`, …) | `modules/aspects/email/neomutt/` |
| `daniel/wallpapers/*` | `modules/aspects/desktop/hyprland/wallpapers/` |
| `modules/pkgs/*/*.sh` | unchanged (next to their package) |
| `secrets.yaml`, `.sops.yaml` | unchanged, at the repository root |
| `.github/workflows/*`, `.github/dependabot.yml` | unchanged |

Already removed by your last commit (nothing to do): `lib/default.nix`, `overlays/default.nix`, `pkgs/**` (moved to `modules/pkgs/`), `shell.nix`, `cooked/nixos/dev.nix`, `cooked/nixos/nix.nix`.

---

## Appendix B — Recipes

The same handful of transformations account for almost every file. Each is shown in its smallest form.

**R1. A module with an `enable` option becomes a feature file** (Step 5).

```nix nosyntax
# before
config = lib.mkIf cfg.enable { services.locate = {enable = true; interval = "hourly";}; };
# after
flake.modules.nixos.base.services.locate = {enable = true; interval = "hourly";};
```

**R2. "Enable my system half if any home-manager user enables the feature", plus `sharedModules` with an `enable` option, becomes two stored modules** (Step 6).

```nix nosyntax
# before: NixOS module scanning users + injecting an HM module with an enable option
lib.mkMerge [
  (lib.mkIf (builtins.any (u: u.programs.zsh.enable) (builtins.attrValues config.home-manager.users)) { … })
  { home-manager.sharedModules = [ ({config, ...}: { options.cooked.zsh.enable = …; config = lib.mkIf … { … }; }) ]; }
]
# after
flake.modules.nixos.base = { … };          # the first `{ … }`, unconditionally
flake.modules.homeManager.base = { … };    # the second, without the option and the mkIf
```

**R3. `inputs` arriving through `specialArgs` becomes a closure** (Steps 5, 6, 9).

```nix
# before:  {inputs, pkgs, ...}: { programs.hyprland.package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland; }
# after:
{inputs, ...}: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    programs.hyprland.package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };
}
```

**R4. A legacy lower-level module file is wrapped by path, unchanged** (Steps 4, 5). A path is a valid `deferredModule` value, and a module imported by path is de-duplicated by that path.

```nix
{flake.modules.nixos.vm = ./_vm.nix;}
```

**R5. A data or helper function file gets a `_` prefix** (Steps 2, 8), and its importer keeps `import ./_x.nix …`. If it has one consumer, inline it instead (8a).

**R6. An overlay becomes a top-level value and is applied where it is needed** (Steps 3, 8).

```nix
{config, ...}: {
  flake.overlays.foo = final: prev: {foo = prev.foo.override {withBar = true;};};
  flake.modules.nixos.base.nixpkgs.overlays = [config.flake.overlays.foo];
}
```

**R7. A machine-specific tweak stays in the host module, including for home-manager** (Step 4).

```nix
{
  flake.modules.nixos."nixosConfigurations/wsl" = {pkgs, ...}: {
    home-manager.users.daniel.programs.git.package = pkgs.stable.gitSVN;
  };
}
```

**R8. Conditions on *other* options' values stay.** Only your own `enable` switches disappear. infra's bluetooth module is a good model: it does not decide *whether* bluetooth is on, it reacts to it.

**mightyiam/infra @ cb42ec1** — [`modules/hardware/bluetooth.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/hardware/bluetooth.nix)

```nix
{lib, ...}: {
  nixos.modules.base = nixosArgs @ {pkgs, ...}: {
    environment.systemPackages = lib.mkIf nixosArgs.config.hardware.bluetooth.enable [pkgs.bluetui];
  };
}
```

**R9. Two files feed one stored module; two stored modules come from one file** (Steps 1, 6). Every step in this guide is a variation on those two sentences.

```nix nosyntax
# modules/aspects/nix.nix          → flake.modules.nixos.base = { nix = …; };
# modules/aspects/development.nix  → flake.modules.nixos.base = { programs.direnv = …; };
# both merge into one module named `base`; one file may also define `nixos` AND `homeManager` halves
```

---

## Appendix C — Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `error: infinite recursion encountered` with `moduleWithSystem` in the trace | A module sets `nixpkgs.hostPlatform` (or anything that decides the platform) from `perSystem` arguments. `moduleWithSystem` reads the platform from `pkgs`, which is built from that very option. | Set `nixpkgs.hostPlatform` as a plain string in the host module. Use `moduleWithSystem`/`withSystem` only for values that do not decide the platform. |
| `The option 'flake.modules' does not exist` | `inputs.flake-parts.flakeModules.modules` is not imported. | Step 2b (`modules/repository/parts.nix`). |
| `The option 'X' in '…' is already declared in '…'` after introducing roles | A role that *declares options* is reachable through two import paths (for example a host importing both `desktop` and `base`), and the `flake.modules` wrapper has no `key`. | Import each role through exactly one path. Put option declarations in a `_file.nix` imported by path (paths are de-duplicated). Or move to flavour C and add a `key` (Step 10). |
| The same text twice in a generated file (a duplicated `zshrc` block, a repeated `exec-once`) | The same cause without an error: an unkeyed module evaluated twice, and `lines` options concatenating both copies. | Same fix. |
| `error: attribute 'inputs' missing`, or `undefined variable 'inputs'` | `inputs` requested by the *lower-level* function. It is an argument of the enclosing top-level function. | Move it out (Report 1, §2.5). While legacy files remain, keep the temporary `specialArgs` and `extraSpecialArgs` (Step 4). |
| `The option 'sudo' does not exist`, or `expected a set but found a list`, from a file under `modules/` | A data or helper file (a bare attrset, or a function returning a list or a derivation) was imported as a module. | `_` prefix it (Step 2e, 8a). |
| `attribute 'owner' missing` / `attribute 'flake' missing` inside a lower-level module | Its own `config` shadows the flake-parts `config`. | Name the inner arguments (`nixosArgs @ {…}:`, `hmArgs:`) and use the outer `config` for top-level values. |
| `warning: unknown flake output 'modules'` from `nix flake check` or `show` | `flake.modules` is not a standard flake output (flavour B). | Expected and harmless. Flavour C (Step 10) removes it. |
| `The module … (class: "homeManager") cannot be imported into a module evaluation that expects class "nixos"` | A `flake.modules.homeManager.*` module is in a NixOS `imports` list, or the reverse. | Import each class's modules in its own evaluation. A NixOS module reaches home-manager via `home-manager.users.<u>.imports`. |
| `Neither nixpkgs.hostPlatform nor the legacy option nixpkgs.system has been set` | The nixpkgs flake's `nixosSystem` passes `system = null`. | Set `nixpkgs.hostPlatform` in every host (Step 4). |
| `path '…/secrets.yaml' does not exist`, or any missing path in the flake source | The file is not tracked by git (flakes only see tracked files), or a relative path is stale after a move. | `git add` it; recheck `../..` depth from the file's new location. |
| A file you did not expect is active | import-tree imports everything under `modules/`: dead code has become live. | Delete it, or `_` prefix it (Step 2e). |
| `jq: error … null (null) has no keys` in `verify_configurations.yml` | The flake defines no `nixosConfigurations`. | Step 4. |
| Hyprland compiles from source on every update | Hyprland's `nixpkgs` input follows yours, so the Cachix cache does not match. | Note [N1](03-config-notes.md#n1--hyprland-follows-your-nixpkgs). |

---

## Appendix D — Sources, and what was and was not verified

**Read in full or in the parts cited**

- mightyiam/dendritic `master` @ `6c76240`; mightyiam/infra `master` @ `cb42ec1`, and commits `ab98a98` (before) and `b45e9e1` (adoption); voidarc/nixos `main` @ `b708a82`.
- Upstream sources, to check the mechanics rather than assume them: flake-parts (`modules/{moduleWithSystem,withSystem,perSystem,nixpkgs,nixosModules,nixosConfigurations,overlays}.nix`, `extras/{modules,easyOverlay,flakeModules}.nix`); nixpkgs (`lib/modules.nix` for `key` de-duplication and path keys, `lib/types.nix` for `deferredModuleWith` and `lines`, `nixos/modules/misc/nixpkgs.nix` and `nixos/lib/eval-config.nix` for how `pkgs` and `hostPlatform` relate, `flake.nix` for `nixosSystem`); home-manager (`nixos/common.nix` for `class = "homeManager"`, `osConfig`, `sharedModules` and the default `home.username`; `modules/services/window-managers/hyprland/default.nix` for `extraConfig` being `lines` and `configType` following `home.stateVersion`); import-tree (README, API docs, and `default.nix` for the `readDir` ordering and the `/_` filter); the Hyprland wiki (Cachix page); the `den` and `flake-file` READMEs.
- Your repository at `0e29b82`, and `master` for the pre-dendritic layout.

**Checked mechanically**

- Every Nix block in both reports that is a complete expression was parsed with tree-sitter-nix (no syntax errors). Line-range excerpts and blocks marked `nosyntax` (sketches, and quotes using infra's `|>` operator, which that parser does not know) were not.
- Every link into `mightyiam/infra` was checked to exist at the commit it points to. Every excerpt is quoted programmatically from a local copy.

**Not verified: please read this**

- **Nothing was evaluated or built.** The environment I worked in has no route to nixos.org or the binary caches, so I could not install Nix. Snippets are therefore *reviewed against the sources*, not run. The likeliest defects are small: a missing argument, a stale relative path, an attribute I renamed in passing. Step 0 is the safety net, and Appendix C lists the errors I would expect first.
- The claim that `nix.nix` will hit infinite recursion (audit item 1) is derived from reading `moduleWithSystem` and NixOS' `nixpkgs.nix`; I did not reproduce the error.
- I assumed the versions your `flake.lock` pins behave like the sources I read (current `master` of each project as of 2026-09-29). If your lock is older, an option name may differ. The companion note [`03-config-notes.md`](03-config-notes.md) is the exception: it was checked against the exact revisions your lock pins (nixpkgs `6774f7bc`, home-manager `0b2f112`), and its "Method and limits" section says how.
- Which host has which features (for example that `vm` is enabled nowhere) comes from reading your tree, not from evaluating it.
