# The dendritic pattern in three repositories

### A bird's-eye view of `mightyiam/dendritic`, `mightyiam/infra` and `voidarc/nixos`

*Report 1 of 2 · prepared 2026-09-29 for `daniellaing/nixos` (branch `dendritic`, commit `0e29b82`).
Report 2, [`02-migration-guide.md`](02-migration-guide.md), turns this into concrete steps for your repository. A companion note, [`03-config-notes.md`](03-config-notes.md), covers things I found in your repository that are unrelated to the pattern.*

## What was read

| Short name | What it is | Version read |
|---|---|---|
| **README** | [mightyiam/dendritic](https://github.com/mightyiam/dendritic), the written description of the pattern | `master` @ `6c76240` (2026-09-04) |
| **infra** | [mightyiam/infra](https://github.com/mightyiam/infra), the author's own configuration, where the pattern was discovered | `master` @ `cb42ec1`, plus his 2025-03 [adoption commit `b45e9e1`](https://github.com/mightyiam/infra/commit/b45e9e1) and its parent |
| **voidarc** | [voidarc/nixos](https://git.voidarc.co.uk/voidarc/nixos) | `main` @ `b708a82` (2026-09-26) |

So that the mechanics described below are right and not merely plausible, I also read the sources of flake-parts, import-tree, home-manager and nixpkgs' module system. Where a statement rests on one of those, it says so.

> **A note on verification.** I could not run Nix in the environment I worked in, so nothing here was *built*. Every Nix snippet was syntax-checked and compared against the upstream sources, and every excerpt from the example repositories is quoted programmatically from a local copy (whitespace normalised), or marked "abridged" / "excerpt". Treat snippets as *reviewed, not built*. Report 2, Step 0 sets up the safety net that will catch anything I missed.

## Contents

0. [The whole thing on one page](#0-the-whole-thing-on-one-page)
1. [The idea](#1-the-idea): two levels, the rules, costs and anti-patterns
2. [The machinery](#2-the-machinery): entry point, import-tree, flake-parts pieces, where modules are stored, how values travel
3. [Anatomy of a feature file](#3-anatomy-of-a-feature-file-five-excerpts)
4. [Tour: `mightyiam/infra`](#4-tour-mightyiaminfra)
5. [Tour: `voidarc/nixos`](#5-tour-voidarcnixos)
6. [Side by side](#6-side-by-side)
7. [Glossary](#7-glossary)
8. [Your repository on the map](#8-your-repository-on-the-map)
9. [Reading list](#9-reading-list)

---

## 0. The whole thing on one page

1. **It is a rule about files, not a library.** Every Nix file except the entry points (`flake.nix`, `default.nix`) is a *module of one top-level module-system evaluation*. In practice that top level is flake-parts.
2. **A file is a feature, not a "type".** The path names the feature (`audio/pipewire.nix`, `mightyiam/git/basics.nix`). The file holds everything that feature needs, *in every class it touches*: a NixOS part, a home-manager part, a package, a keybinding, an option.
3. **NixOS and home-manager modules become values.** Instead of files you `import` by path, they are stored in top-level options (of type `deferredModule`), for example `flake.modules.nixos.audio`. Any number of files can contribute to the same one, and a host can select them by name.
4. **Everything is imported automatically** (import-tree). Adding a feature means adding a file; there are no import lists to keep in sync.
5. **Values travel through the top-level config and ordinary Nix scoping, not through `specialArgs`.** `inputs`, `self`, the top-level `config` and any typed options you declare are visible to every file.
6. **Hosts are assembled from named pieces.** A host file lists which stored modules make up the machine and calls `nixosSystem` (voidarc), or registers itself with a small assembler (infra).
7. **The two example repositories are two dialects of the same idea.** voidarc stores modules in flake-parts' built-in `flake.nixosModules` and composes them with import lists. infra stores them in options it declares itself and composes by *merging* into "role" modules (`base`, `pc`), with typed slots per user.
8. **Your repository already has the raw material.** `cooked/` is a set of cross-class features with presets. What remains is mostly *where things live*. See [§8](#8-your-repository-on-the-map).

---

## 1. The idea

### 1.1 Two levels of configuration

NixOS, home-manager and nix-darwin each evaluate a *module system* configuration. Normally you feed them a list of files, and the hard questions become: which file gets imported where, how does a value get from one file to another, and how do I share a module between a NixOS configuration and a home-manager one?

The dendritic answer is to run **one more module-system evaluation on top**, the *top-level configuration*, and to make every file a module of *that*. NixOS and home-manager modules stop being files that get imported by path. They become **values** stored in options of the top-level configuration. Configurations such as `nixosConfigurations.<host>` are then assembled from stored modules.

```text
  flake.nix
    outputs = inputs: mkFlake { inherit inputs; } (import-tree ./modules)
        |
        v
  +==================== TOP-LEVEL configuration (flake-parts) ====================+
  |                                                                              |
  |  every file under modules/ is a module of THIS evaluation                    |
  |                                                                              |
  |    audio/pipewire.nix   ssh.nix   computers/laptop.nix   pkgs/foo.nix   ...  |
  |           |               |              |                   |               |
  |           +---------------+------+-------+-------------------+               |
  |                                  v                                           |
  |    one merged top-level `config` - a typed "database" of your setup:         |
  |                                                                              |
  |      nixos.modules.base          = <a NixOS module>          \  stored       |
  |      nixos.modules.pc            = <a NixOS module>           > lower-level  |
  |      homeManager.modules.gui     = <a home-manager module>   /  modules      |
  |      perSystem.packages.foo      = <a derivation>                            |
  |      nixos.configurations.laptop = { module = ...; }                         |
  |                                                                              |
  +----------------------------------+-------------------------------------------+
                                     | assemble (once per host)
                                     v
        +----------- LOWER-LEVEL configuration: NixOS "laptop" -----------+
        |  nixosSystem { modules = [ base pc <host-specific bits> ]; }    |
        |     '-- nested: one home-manager evaluation per user            |
        +-----------------------------------------------------------------+
```

Two terms appear constantly, so it pays to pin them down:

| Term | What it is | Arguments its function receives |
|---|---|---|
| **top-level module** | A file under `modules/`. Evaluated by flake-parts, once. | `{ config, inputs, self, lib, withSystem, ... }` of the *flake-parts* evaluation |
| **lower-level module** | A NixOS / home-manager / ... module *value* sitting inside a top-level module's config. Evaluated later, once per configuration that includes it. | `{ config, pkgs, lib, ... }` of *that* NixOS or home-manager evaluation |

The consequence you will meet on day one: a lower-level module is written *inside* a top-level function, so **two different `config`s can be in scope at once**. The outer one is the flake-parts config; the inner one is NixOS's or home-manager's. `infra` avoids the clash by naming the inner arguments `nixosArgs` / `hmArgs`. See [§2.5](#25-how-values-travel-replaces-specialargs).

### 1.2 The rules

These come straight from the [README](https://github.com/mightyiam/dendritic#the-pattern)'s "The pattern" section; the right-hand column is what they mean in practice.

| # | README says | In practice |
|---|---|---|
| 1 | "every Nix file except for entry points such as `default.nix` and `flake.nix` is a module of the top-level configuration" | No "this file is a NixOS module, that one is home-manager, that one is a function you `import`". All files speak one language. Deliberate exceptions exist (files starting with `_`, `*.pkg.nix`). |
| 2 | every top-level module "implements a single feature" | The unit of a file is a *feature* ("pipewire", "git basics", "hyprland keybindings"), not a class (`nixos/`, `home-manager/`) and not a host. |
| 3 | "...across all configurations that that feature applies to" | One file can hold the `nixos` part *and* the `homeManager` part of the same feature. |
| 4 | "is at a path that serves to name that feature" | The path is documentation for humans. The code never looks at it, so files can be renamed, moved and split freely. |
| 5 | "Lower-level modules and configurations ... are stored as option values in the top-level configuration" | e.g. `nixos.modules.pc = { ... }`, merged from any number of files by the `deferredModule` type. |

### 1.3 What it buys, and what it costs

**Buys** (the first three are the README's own list):

- **The type of every file is known.** Nothing is a mystery `callPackage` file or a bare attrset. Every file is a module of the top-level class.
- **Automatic importing.** Paths carry meaning only for you, so a one-line expression (or import-tree) can import them all.
- **File-path independence.** A feature's path is a name, not an address. Move it, split it when it grows.
- *Cohesion*: everything about "audio" is in one place instead of three (`nixos/`, `home-manager/`, `scripts/`).
- *Sharing*: values (functions, constants, packages, options) are shared through the top-level config instead of being threaded through `specialArgs`.

**Costs** (mostly from experience reports, marked where quoted):

- **Two levels to hold in your head**, including the two `config`s above. drupol calls it a "steeper learning curve" ([his post](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/)).
- **Effects at a distance.** Because nothing is imported by hand, a file under `modules/` can change a host without any visible import. Good names and deliberate "roles" (see §4) are what keep this readable.
- **Everything under `modules/` is live.** import-tree imports every `.nix` file. Dead code becomes live code, and files that aren't modules (data files, `callPackage` files) must be hidden with a `_` prefix or a suffix filter.
- **Some tool friction.** `flake.modules` is not a standard flake output, so `nix flake show`/`check` may mention an "unknown flake output". Harmless, but worth knowing about.
- **Migration is slow.** drupol: "Migrating the existing host-centric setup ... has been a slow and occasionally painful process."

### 1.4 The README's anti-patterns, and how the examples treat them

| Anti-pattern (README) | The concern | infra | voidarc |
|---|---|---|---|
| **Not declaring options** | Using *only* existing options (like `flake.modules`) "prevents us from translating our mental model of the system into code". | Declares `nixos.modules.{base,pc}`, `homeManager.modules.{base,gui}`, `users.<name>`, `nixos.configurations`, `git.ignore`, ... | Uses only the built-in `flake.nixosModules`. Fine for a NixOS-only setup; the README would call it the minimal version. |
| **`specialArgs` pass-thru** | Threading values into lower-level evaluations by hand. | None. `inputs` and `self` are closed over from the top-level function arguments. | None. Same. |
| **Lower-level module name proliferation** | One name per tiny module means long `imports` lists that must be edited whenever a module is added or removed. "Consider merging multiple non-distinct lower-level modules under one distinct name." | Merges almost everything into two roles (`base`, `pc`). Only genuinely optional pieces get their own name (`efi`, `zfs`, `qmk`, `nvidia-video-driver`). | Named modules plus composite "bundles" (`attrs/`, `system/desktop`). A couple of dozen named features are selected via import lists. |
| **Fanaticism** | "Use it where it fits and make exceptions where appropriate." | `callPackage`-style files are named `*.pkg.nix` and filtered out of auto-import. | Packages are defined inline in `perSystem.packages.*` next to the module that uses them. |
| **`enable` options** | "In most cases, importing a module should enable the feature that it provides." | No `enable` options for its own features. | Same. Its one custom option (`tabletSupport`) is a real variation point, not an on/off switch. |

That last row matters for you: your `cooked.<x>.enable` options are the pattern this README names as the anti-pattern. See Report 2, Step 5.

---

## 2. The machinery

### 2.1 The entry point

An entry point has two jobs: build the top-level configuration with flake-parts, and hand it every file. All three sources agree; only the packaging differs.

**voidarc/nixos @ b708a82** — [`flake.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/flake.nix) (excerpt)

```nix nosyntax
  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
```

**mightyiam/infra @ cb42ec1** — [`outputs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/outputs.nix)

```nix
inputs: let
  lib = import "${inputs.nixpkgs}/lib";
in
  inputs.flake-parts.lib.mkFlake {inherit inputs;} {
    debug = true;
    imports = [((import inputs.import-tree).filterNot (lib.hasSuffix ".pkg.nix") ./modules)];
    _module.args.rootPath = ./.;
  }
```

infra's `flake.nix` is a thin file *generated* by `flake-file` (it just says `outputs = inputs: import ./outputs.nix inputs;`), which is why the real entry point is `outputs.nix`. Notice `_module.args.rootPath = ./.;`: it is declared there, but no module under `modules/` reads it. That is where the `rootPath` in your `flake.nix` came from, and it's harmless.

For comparison, your current entry point already has the same shape:

**your repo** — `flake.nix` (lines 77-83)

```nix nosyntax
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      _module.args.rootPath = ./.;
      imports = [(inputs.import-tree ./modules)];
      systems = ["x86_64-linux"]; # TODO: Remove
    };
}
```

### 2.2 import-tree

`import-tree ./modules` returns a module of the form `{ imports = [ <every matching file> ]; }`. By default a file matches if it ends in `.nix` and its path contains no `/_`, so **any file or directory whose name starts with an underscore is skipped** ([import-tree API](https://github.com/denful/import-tree)). `.filter`, `.filterNot` and `.match` narrow the selection further.

| Convention | Meaning | Where it appears |
|---|---|---|
| `_name.nix`, `_dir/` | Not auto-imported. For helpers that are imported *by path* from a real module: data, `callPackage` files, legacy modules. | infra `computers/_teeveera.nix`; import-tree docs |
| `name.pkg.nix` | A `callPackage`-style file, excluded by `filterNot (hasSuffix ".pkg.nix")`. The README suggests exactly this naming. | infra [`modules/mightyiam/window-manager/hyprcwd.pkg.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/window-manager/hyprcwd.pkg.nix), [`modules/mightyiam/nix/system-command.pkg.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/nix/system-command.pkg.nix) |
| non-`.nix` files (images, `.json`, `.toml`, `.sh`) | Ignored, so they can sit next to the feature that uses them. | infra `computers/*.facter.json`, `banner/image.jpg`; voidarc `features/otter-launcher/config.toml` |

### 2.3 The flake-parts pieces you will see

| Piece | What it is | Seen in |
|---|---|---|
| `flake.<anything>` | Becomes a flake output: `flake.nixosConfigurations`, `flake.overlays`, `flake.nixosModules`, `flake.templates`, ... | both |
| `perSystem = { pkgs, ... }: { ... }` | Per-system outputs (`packages`, `devShells`, `formatter`, `checks`). Its arguments include `pkgs`, `system`, `self'` and `inputs'`. `pkgs` defaults to `inputs.nixpkgs.legacyPackages.${system}` when the flake has a `nixpkgs` input (flake-parts `modules/nixpkgs.nix`). | both |
| `systems = [ ... ]` | Required as soon as anything uses `perSystem`. | voidarc [`modules/parts.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/parts.nix); infra *derives* it from its hosts ([`modules/repository/systems.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/systems.nix)) |
| `_module.args.<x>` | Adds a function argument to every top-level module. | infra `rootPath`, `evalModulesModule`, `removeStorePathPrefix` |
| `withSystem <system> (psArgs: ...)` | Reads `perSystem` values from *outside* `perSystem`, e.g. from a lower-level module. | infra [`modules/nixpkgs.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixpkgs.nix) |
| `moduleWithSystem (psArgs: lowerLevelModule)` | Sugar for the above. It finds the system from `config._module.args.pkgs.stdenv.hostPlatform.system` (flake-parts `modules/moduleWithSystem.nix`), so **the module must not be the thing that decides the platform**. | voidarc, in almost every feature |
| `self'`, `inputs'` | `self` / `inputs` with the system already selected. Only exist inside `perSystem`/`moduleWithSystem`; plain `self`/`inputs` there is deliberately an error. | voidarc |
| `flake.modules.<class>.<name>` | Optional extra module `flake-parts.flakeModules.modules`: a typed store for modules of *any* class (`nixos`, `homeManager`, `darwin`, `generic`, ...). | infra at adoption; drupol; not used by voidarc |

### 2.4 Where the lower-level modules are stored (the main dialect difference)

Everything in the pattern hinges on *some option of the top-level config being of type `deferredModule`*. That type accepts a module (attrset, function or path) and, when several files define the same option, **merges them into a single module whose `imports` are all the definitions** (nixpkgs `lib/types.nix`, `deferredModuleWith`). That is what lets *any number of files* each add a piece to `nixos.modules.pc`.

There are three ways to get such an option, and the examples cover all three:

```nix nosyntax
# A. voidarc: the option flake-parts already has (NixOS only)
flake.nixosModules.audio = { pkgs, ... }: { /* ... */ };
#   use:  nixosSystem { modules = with self.nixosModules; [ audio ]; }

# B. flake.modules: one setup line, any class
#    (imports = [ inputs.flake-parts.flakeModules.modules ])
flake.modules.nixos.audio       = { pkgs, ... }: { /* ... */ };
flake.modules.homeManager.audio = { pkgs, ... }: { /* ... */ };
#   use:  imports = with config.flake.modules.nixos; [ audio ];

# C. infra today: options you declare yourself
options.nixos.modules.audio = lib.mkOption { type = lib.types.deferredModule; };
config.nixos.modules.audio  = { pkgs, ... }: { /* ... */ };
#   use:  imports = with config.nixos.modules; [ audio ];
```

| | A. `flake.nixosModules` | B. `flake.modules.<class>` | C. your own options |
|---|---|---|---|
| Setup | none | import one flake-parts module | declare each option (a few lines, once) |
| Classes | NixOS only (there is no built-in `homeModules`) | any | any, and you can shape them (`users.<n>.nixos.pc`) |
| Merging by name | yes | yes | yes |
| Extras you can add | none | none | `apply` (e.g. give the module a `key`, see below), `readOnly`, `default`, custom types |
| Is it a flake output? | yes (`nixosModules`) | `modules`, which is non-standard | no |
| Used by | voidarc | infra at adoption (2025-03), drupol | infra today, and what the README's examples show |

> **Why `key` matters.** The module system removes duplicate imports *by `key`*. A module imported by **path** is keyed by the path, so importing it twice is harmless. An anonymous module (a function or attrset) gets a position-dependent fallback key, so the *same value* reachable through two import paths is evaluated **twice** (nixpkgs `lib/modules.nix`, `collectStructuredModules`). infra's roles are declared with an `apply` that adds a `key`, so they can safely be imported from several places:
>
> **mightyiam/infra @ cb42ec1** — [`modules/nixos/base.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos/base.nix)
>
> ```nix
> {lib, ...}: {
>   options.nixos.modules.base = lib.mkOption {
>     type = lib.types.deferredModule;
>     apply = module: {
>       key = "base";
>       imports = [module];
>     };
>   };
> }
> ```
>
> The built-in `flake.modules` wrapper does not set a key (its source has a `TODO: set key?`). With flavours A and B, avoid importing the same role through two different parents. Report 2 shows how.

### 2.5 How values travel (replaces `specialArgs`)

The README's second anti-pattern is `specialArgs` pass-thru. In its place there are four channels:

**1. Lexical scope.** The lower-level module is written *inside* the top-level function, so it closes over that function's arguments.

```nix
# top-level module: these arguments belong to flake-parts
{ config, inputs, lib, ... }: {
  flake.modules.nixos.base =
    # lower-level module: these arguments belong to NixOS
    { pkgs, ... }: {
      users.users.${config.owner.username}.isNormalUser = true;   # `config` = the OUTER (top-level) one
      programs.hyprland.package =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;   # no specialArgs needed
    };
}
```

If the inner module also asks for `config`, it *shadows* the outer one. infra sidesteps it by naming the inner arguments (`nixosArgs @ { pkgs, ... }:`, `hmArgs: ...`).

**2. Typed top-level options.** One file declares a value; any file reads it. In infra `nix.settings` is declared and given its values once (top of [`modules/nix/settings.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nix/settings.nix)), and *both* classes consume it. First the NixOS side, then the home-manager side:

**mightyiam/infra @ cb42ec1** — [`modules/nix/settings.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nix/settings.nix) (lines 41-45)

```nix nosyntax
    nixos.modules.base = {
      nix = {
        inherit (config.nix) settings;
      };
    };
```

**mightyiam/infra @ cb42ec1** — [`modules/mightyiam/nix/settings.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/nix/settings.nix)

```nix
{config, ...}: {
  home.base = {
    nix = {
      inherit (config.nix) settings;
    };
  };
}
```

**3. `_module.args`.** For plain helpers and constants (`rootPath`, `evalModulesModule`).

**4. From the lower level back up.** Because the top level can *read the evaluated configurations*, cross-host facts become easy. infra's `ssh.nix` builds `programs.ssh.knownHosts` for every host from each host's own `services.openssh.publicKey`, and `systems` is derived from the hosts' hardware reports. Neither would be pleasant with `specialArgs`.

---

## 3. Anatomy of a feature file: five excerpts

### 3.1 The smallest case: one class, merged into a role

**mightyiam/infra @ cb42ec1** — [`modules/audio/pipewire.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/audio/pipewire.nix)

```nix
{
  nixos.modules.pc = {pkgs, ...}: {
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    security.rtkit.enable = true;

    environment.systemPackages = with pkgs; [
      pwvucontrol
      qpwgraph
    ];
  };
}
```

Read it as: "**the feature "pipewire" contributes this to the `pc` role** (a desktop machine)". There is no `enable` option, no import line anywhere, and no host mentions it. Because it exists under `modules/`, every machine that includes the `pc` role has pipewire.

### 3.2 One file, module *and* package

**voidarc/nixos @ b708a82** — [`modules/features/nvim/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/nvim/default.nix)

```nix
{moduleWithSystem, ...}: {
  flake.nixosModules.nvim = moduleWithSystem ({self', ...}: {
    programs.neovim = {
      enable = true;
      package = self'.packages.nvim;
    };
  });
  perSystem = {inputs', ...}: {
    packages.nvim = inputs'.nvim.packages.default;
  };
}
```

A voidarc feature defines a NixOS module (`flake.nixosModules.nvim`) and, in the same file, the package it uses (`perSystem.packages.nvim`). `moduleWithSystem` is the bridge: it hands the NixOS module the `perSystem` arguments (`self'`), so the module can say `self'.packages.nvim`. voidarc keeps a scaffold for new features in [`modules/empty.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/empty.nix), which is exactly this shape.

### 3.3 One feature, two classes (the "flip" you are about to do)

In March 2025, infra's author adopted the pattern in a single commit ([`b45e9e1`](https://github.com/mightyiam/infra/commit/b45e9e1)). Before it, `modules/` was organised *by class*, much like your `cooked/nixos/` and `cooked/home-manager/`:

```text
before (ab98a98)                                   after (b45e9e1)
modules/                                           modules/
├── nixos-modules/          (35 files)             ├── audio.nix          ← both halves, one file
│   └── pipewire.nix   ──────────────┐             ├── bluetooth.nix
├── home-manager-modules/   (78 files)│            ├── fonts.nix
│   └── audio.nix      ──────────────┴───────►     ├── git.nix
├── nixos-configurations/   (28 files)             ├── ganoderma/  ← host facets, each a top-level module
│   └── ganoderma/default.nix                      │   ├── imports.nix, host-id.nix, state-version.nix, facter.nix
└── (a few flake-parts files)                      └── …about 65 feature files and dirs at the top level
```

The merged result, with both classes side by side:

**mightyiam/infra @ b45e9e1** — [`modules/audio.nix`](https://github.com/mightyiam/infra/blob/b45e9e1/modules/audio.nix)

```nix
{
  lib,
  inputs,
  ...
}:
{
  flake.modules = {
    nixos.desktop = {
      security.rtkit.enable = true;

      services = {
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          pulse.enable = true;
        };
      };
    };

    homeManager.home =
      {
        pkgs,
        config,
        ...
      }:
      let
        step = 5;
        sink-rotate = inputs.sink-rotate.packages.${pkgs.system}.default;
        pactl = lib.getExe' pkgs.pulseaudio "pactl";
        mod = config.wayland.windowManager.sway.config.modifier;

        incVol =
          d:
          lib.concatStringsSep " " [
            "exec ${pactl}"
            "set-sink-volume @DEFAULT_SINK@ ${d}${toString step}%"
          ];

        toggleMuteSources = lib.concatStringsSep " " [
          "exec ${pkgs.zsh + /bin/zsh} -c '"
          "for source in $(${pactl} list short sources | ${pkgs.gawk + /bin/awk} \"{print \\$2}\");"
          "do ${pactl} set-source-mute \"$source\" toggle;"
          "done'"
        ];
      in
      lib.mkIf config.gui.enable {
        wayland.windowManager.sway.config.keybindings = {
          "--no-repeat ${mod}+c" = "exec ${sink-rotate}/bin/sink-rotate";
          "--no-repeat ${mod}+x" = incVol "-";
          "--no-repeat ${mod}+Shift+x" = incVol "+";
          "--no-repeat ${mod}+z" = toggleMuteSources;
        };

        home.packages =
          (with pkgs; [
            pavucontrol
            qpwgraph
          ])
          ++ [ sink-rotate ];
      };
  };
}
```

What to notice:

- The NixOS half went into a **role** (`nixos.desktop`), the home-manager half into another (`homeManager.home`). Nothing was given a private name like `nixos.pipewire`.
- `inputs` is used directly (`inputs.sink-rotate...`), because the file is a top-level module. Before the flip it had to arrive as `self.inputs` via `specialArgs`.
- The files kept their *content*. The flip was mostly moving text between files.

### 3.4 A value that crosses classes

This is the situation your `XF86` options solve today (NixOS sets commands, home-manager reads them). infra solves its equivalent with a top-level option: one file states the *choice*, another consumes it.

**mightyiam/infra @ cb42ec1** — [`modules/mightyiam/window-manager/session.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/window-manager/session.nix)

```nix
{lib, ...}: {
  users.mightyiam = {
    wayland.sessions = pkgs: [pkgs.hyprland];

    nixos.pc = {pkgs, ...}: {
      services.greetd.settings = {
        initial_session = {
          user = "mightyiam";
          command = lib.getExe' pkgs.hyprland "start-hyprland";
        };
      };
    };
  };
}
```

**mightyiam/infra @ cb42ec1** — [`modules/greeter.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/greeter.nix) (lines 1-15)

```nix nosyntax
{lib, ...}: {
  options.users = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule (userArgs: {
      options.wayland.sessions = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.package);
      };
      config.nixos.pc = {pkgs, ...}: {
        users.wayland.sessions = userArgs.config.wayland.sessions pkgs;
      };
    }));
  };
  config.nixos.modules.pc = nixosArgs @ {pkgs, ...}: {
    options.users.wayland.sessions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
    };
```

The user's file says which Wayland session package they want (`wayland.sessions = pkgs: [pkgs.hyprland]`), and the greeter (a NixOS-only concern) turns that into `session.sessions_dirs` for the display manager. The value is a *function of `pkgs`* because a top-level value cannot know which `pkgs` will evaluate it.

### 3.5 An optional module, selected by name

Not everything belongs in a role. A machine either boots from EFI or it doesn't, so infra keeps `efi` as a named module that hosts opt into:

**mightyiam/infra @ cb42ec1** — [`modules/hardware/efi.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/hardware/efi.nix) (lines 1-13)

```nix nosyntax
{lib, ...}: {
  options.nixos.modules.efi = lib.mkOption {
    type = lib.types.deferredModule;
    readOnly = true;
    default = nixosArgs @ {pkgs, ...}: {
      key = "efi";
      boot.loader = {
        efi = {
          efiSysMountPoint = nixosArgs.config.boot.partlabels |> lib.head |> lib.getAttr "path";
          canTouchEfiVariables = true;
        };
        grub.efiSupport = true;
      };
```

and a host picks its pieces:

**mightyiam/infra @ cb42ec1** — [`modules/computers/astraeus.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/computers/astraeus.nix) (lines 24-32)

```nix nosyntax
      imports = with config.nixos.modules;
        [
          efi
          zfs
          pc
        ]
        |> lib.concat [
          config.users.mightyiam.nixos.pc
        ];
```

The rule of thumb that falls out of both examples: **if every machine in a role wants it, merge it into the role; if only some do, give it a name and let those hosts import it.** That replaces your `cooked.<x>.enable` flags.

---

## 4. Tour: `mightyiam/infra`

The pattern's author's own configuration: six machines, two users, about 250 Nix files, every one a flake-parts module. It uses flavour C (self-declared options) and is the most fully developed of the three. It is also the one to read for *how the concepts are modelled*, even if you never copy its size.

### 4.1 Layout

```text
infra/
├── flake.nix            GENERATED by `flake-file`; each input is declared in the module that needs it
├── outputs.nix          the real entry point: mkFlake + import-tree (skips *.pkg.nix)
├── README.md, LICENSE, .gitignore      also generated (by the `files` flake-parts module)
└── modules/
    ├── repository/      (A) plumbing: modules that configure the REPOSITORY itself
    │     flake-parts.nix  auto-import.nix  systems.nix  formatting.nix  linting.nix  dev-shell.nix
    │     files.nix  generated-flake-file.nix  all-check-store-paths.nix  git/{hooks,ignore,remote}.nix
    ├── docs/            README assembled from fragments contributed by many modules
    │
    ├── nixos.nix        (B) vocabulary: declares `nixos.configurations` and builds flake.nixosConfigurations + checks
    ├── nixos/base.nix        declares the role   nixos.modules.base
    ├── nixos/pc.nix          declares the role   nixos.modules.pc   (includes base)
    ├── home-manager.nix      declares homeManager.modules.{base,gui}; wires home-manager into nixos base
    ├── users.nix             declares `users.<name>` with typed slots nixos.{base,pc} and home.{base,gui}
    ├── eval-modules.nix, nixpkgs.nix, lib.nix        shared plumbing
    │
    ├── audio/ hardware/ networking/ storage/ printing.nix boot.nix ssh.nix fonts.nix ...
    │                    (C) machine-level features; each contributes to nixos.modules.{base,pc}
    ├── computers/       (C) HOSTS: one small file per machine (+ hardware reports *.facter.json)
    ├── mightyiam/       (C) everything specific to user "mightyiam": shell/ git/ terminal/ window-manager/ ...
    └── bow/             (C) a second user's differences
```

### 4.2 Three kinds of file

| Layer | Purpose | Examples |
|---|---|---|
| **Plumbing** | Configure the *repository*, not the machines. Even flake-parts' own extras are imported here, as files. | [`modules/repository/flake-parts.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/flake-parts.nix), [`modules/repository/formatting.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/formatting.nix), [`modules/repository/dev-shell.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/dev-shell.nix) |
| **Vocabulary** | *Declare the options* the rest of the tree uses: the roles, the host registry, the user shape. This is the README's "declare options" advice applied. | [`modules/nixos.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos.nix), [`modules/nixos/pc.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos/pc.nix), [`modules/users.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/users.nix), [`modules/home-manager.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/home-manager.nix) |
| **Content** | Features, users, hosts. The bulk of the repository. | everything else |

### 4.3 Roles: how `base` and `pc` work

There are two NixOS roles, and `pc` *contains* `base`:

**mightyiam/infra @ cb42ec1** — [`modules/nixos/pc.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos/pc.nix)

```nix
{
  lib,
  config,
  ...
}: {
  options.nixos.modules.pc = lib.mkOption {
    type = lib.types.deferredModuleWith {
      staticModules = [config.nixos.modules.base];
    };
    apply = module: {
      key = "pc";
      imports = [module];
    };
  };
}
```

`staticModules` bakes `base` into `pc`, and because `base` carries a `key` (see [§2.4](#24-where-the-lower-level-modules-are-stored-the-main-dialect-difference)), a host that imports both roles does not evaluate it twice. Every machine-level feature then says which role it belongs to, as in `pipewire.nix` above (`nixos.modules.pc = ...`) or `ssh.nix` (`nixos.modules.base = ...`).

### 4.4 Hosts: small, and mostly a list of roles and named modules

Hosts are entries in a registry the vocabulary layer declared, `nixos.configurations.<name>`, whose `module` field is an ordinary NixOS module:

**mightyiam/infra @ cb42ec1** — [`modules/computers/molly.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/computers/molly.nix)

```nix
{config, ...}: {
  nixos.configurations.molly = {
    module = nixosArgs: {
      imports = [
        config.nixos.modules.base
        config.users.mightyiam.nixos.base
      ];

      boot = {
        initrd.availableKernelModules = [
          "virtio_scsi" # TODO ideally a facter module does this
        ];

        loader.grub.device = "/dev/sda";
      };

      fileSystems = {
        "/" = {
          device = "/dev/sda2";
          fsType = "ext4";
        };
      };

      networking = {
        hostName = "nixpkgs";
        domain = "molybdenum.software";
      };

      system.stateVersion = "25.05";
    };

    facter.reportPath = ./molly.facter.json;
  };
}
```

This one is a plain server: role `base` plus the user's `base` slot. The desktops list `pc`, the user's `pc` slot and a few opt-in modules ([astraeus](https://github.com/mightyiam/infra/blob/cb42ec1/modules/computers/astraeus.nix), quoted in §3.5). Note what else lives inside a host: **home-manager settings for one machine** (`home-manager.users.mightyiam.audio.sinkNameMap = ...`), set directly, with no extra plumbing.

The registry does more work than just building configurations. `modules/nixos.nix` also derives `flake.checks` from it, [systems.nix](https://github.com/mightyiam/infra/blob/cb42ec1/modules/repository/systems.nix) derives the flake's `systems` list from each host's hardware report, and `ssh.nix` derives `known_hosts`. The top level *can see every host*.

**mightyiam/infra @ cb42ec1** — [`modules/nixos.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/nixos.nix) (lines 27-41)

```nix nosyntax
  config = {
    flake = {
      nixosConfigurations = config.nixos.configurations |> lib.mapAttrs (name: {configuration, ...}: configuration);

      checks =
        config.nixos.configurations
        |> lib.mapAttrsToList (
          name: {configuration, ...}: {
            ${configuration.config.hardware.facter.report.system} = {
              "configurations:nixos:${name}" = configuration.config.system.build.toplevel;
            };
          }
        )
        |> lib.mkMerge;
    };
```

### 4.5 Users: typed slots, and a per-user tree

`users.<name>` is a submodule with plain values (`username`, `name`, `email`) and **four module slots**:

```text
users.<name>
├── username, name, email      plain values (git reads name/email from here)
├── nixos.base    NixOS module: the account, plus  home-manager.users.<name> = home.base
├── nixos.pc      imports nixos.base, plus         home-manager.users.<name> = home.gui
├── home.base     home-manager module (also imports the global homeManager.modules.base)
└── home.gui      imports home.base and homeManager.modules.gui
```

A host that wants the user just imports `config.users.mightyiam.nixos.pc`, and the account and the home-manager configuration arrive together. Feature files for that user write into the slots. One small file aliases the slots at the top level, so a feature file can write `home.base = ...` instead of `users.mightyiam.home.base = ...`:

**mightyiam/infra @ cb42ec1** — [`modules/mightyiam/home.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/home.nix)

```nix
{
  config,
  lib,
  ...
}: {
  options.home = {
    base = lib.mkOption {
      type = lib.types.deferredModule;
      apply = module: {
        key = "base-alias";
        imports = [module];
      };
    };
    gui = lib.mkOption {
      type = lib.types.deferredModule;
      apply = module: {
        key = "gui-alias";
        imports = [module];
      };
    };
  };
  config.users.mightyiam = {
    inherit (config) home;
  };
}
```

After that, a feature that needs both classes is a single file, with each half written into its slot:

**mightyiam/infra @ cb42ec1** — [`modules/mightyiam/ssh.nix`](https://github.com/mightyiam/infra/blob/cb42ec1/modules/mightyiam/ssh.nix)

```nix
{
  home.base = hmArgs: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = ["${hmArgs.config.home.homeDirectory}/.ssh/hosts/*"];
      settings."Host *" = {
        Compression = true;
        IdentitiesOnly = true;
        HashKnownHosts = false;
        IdentityFile = "${hmArgs.config.home.homeDirectory}/.ssh/id_ed25519";
      };
    };
  };

  nixos.modules.base = {
    users.users.mightyiam.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJVzohaJsHeG8sgtc1NiOIo3LVlEs4J1MMC0bV3CoyA"
    ];
  };
}
```

### 4.6 Things around the pattern (none required by it)

- **`flake-file`** generates `flake.nix` from `flake-file.inputs.<name>` declarations *inside the modules that use them*. Most inputs are `flake = false` and are `import`ed manually.
- **`files`** generates `README.md`, `LICENSE` and `.gitignore` from fragments that modules contribute (`text.readme.parts.*`, `git.ignore`).
- **Checks and refactoring aids**: every host is a `flake.checks` entry, and `.#all-check-store-paths` writes a TOML of check → store path "to help determine whether a Nix change results in changes to derivations" (his README). Report 2, Step 0 borrows this idea.
- **Repository hygiene**: treefmt (alejandra, prettier), statix, nixf-diagnose, git hooks, `nixConfig.abort-on-warn = true`, `allow-import-from-derivation = false`.

### 4.7 What to take from it

1. **Two axes.** *What it does* (`modules/audio/`, `modules/ssh.nix`) and *who it is for* (`modules/mightyiam/`, `modules/bow/`) are separate. Personal preferences live in a per-user tree; machine features live at the top.
2. **Host files are tiny** because roles carry the weight.
3. **Optional things get names; the rest get merged.** (`efi`, `zfs`, `qmk` vs `base`, `pc`.)
4. **Vocabulary before content.** The handful of files that declare `nixos.modules`, `users` and `nixos.configurations` make everything else short.
5. **One-off, per-machine tweaks stay in the host file**, including tweaks to home-manager.

## 5. Tour: `voidarc/nixos`

A desktop-oriented configuration with three hosts. It uses flavour A (`flake.nixosModules.*`) and composes with import lists. There is **no home-manager**: user-level configuration is baked into *wrapped packages* (via `nix-wrapper-modules`), so an application and its configuration travel together and can be run with `nix run`.

### 5.1 Layout

The repository's README defines the four directories:

```text
voidarc/nixos/
├── flake.nix            inputs + a one-line `outputs` (mkFlake + import-tree ./modules)
└── modules/
    ├── parts.nix        `systems = [ ... ]`
    ├── empty.nix        the template for a new feature
    ├── features/        "all available apps": one directory each (kitty, git, nvim, hyprland, zsh, sops, sddm, ...)
    │                    default.nix typically = flake.nixosModules.<app>  +  perSystem.packages.<app>
    ├── attrs/           "attributes composed of other modules, no new features defined" (development, gaming, music, ...)
    ├── system/          "basic system modules, no binaries" (core/, desktop/, network/, audio/, drivers/, ...)
    └── hosts/           machine presets; output names match directory names (HACKSTATION, mobile02, mobile03)
```

### 5.2 A host is a list of names

**voidarc/nixos @ b708a82** — [`modules/hosts/HACKSTATION/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/hosts/HACKSTATION/default.nix)

```nix
{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.HACKSTATION = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      desktop
      hackstationConfiguration
      amdDrivers
      youtube
      distcc
      development
      bottles
      gaming
      davinci
      sddm-autologin
      nix-ld
    ];
  };
}
```

The host is *the only place that calls `nixosSystem`*, and its `modules` is a list of names looked up in `self.nixosModules`. Host-specific settings live in one more named module, [`modules/hosts/HACKSTATION/hackstationConfiguration.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/hosts/HACKSTATION/hackstationConfiguration.nix), which sets `networking.hostName` and a few packages.

### 5.3 Composition by import lists

There are two levels of composite module. A **bundle** ("attr") adds a little and imports features; a **system** module is a role:

**voidarc/nixos @ b708a82** — [`modules/attrs/development/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/attrs/development/default.nix)

```nix
{
  self,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.development = moduleWithSystem ({pkgs, ...}: let
    modules = with self.nixosModules; [
      git
      nvim
    ];
  in {
    imports = modules;
    environment.systemPackages = with pkgs; [
      opencode
      devenv
      jellyfin-tui
    ];
  });
}
```

**voidarc/nixos @ b708a82** — [`modules/system/desktop/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/desktop/default.nix)

```nix
{
  self,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.desktop = moduleWithSystem ({pkgs, ...}: let
    modules = with self.nixosModules; [
      core
      hyprland
      sddm
      network
      omnisearch
      tailscale
      sops
    ];
  in {
    imports = modules;
    environment.systemPackages = with pkgs; [
      mpv
    ];
  });
}
```

`desktop` imports `core`, which (see [`modules/system/core/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/core/default.nix)) in turn imports `user bootloader nix hardware locale`. So `desktop` is the moral equivalent of infra's `pc` role, but **built by listing names** rather than by every feature merging itself in.

### 5.4 What to take from it, and what not to

**Take:**

1. The `features / attrs / system / hosts` split. It is an easy taxonomy to start with, and it maps well onto your `cooked` presets (see §8).
2. `modules/empty.nix`: keep a template for "how a new feature file looks" in your repository.
3. A feature's package and its NixOS module in the same file ([`modules/features/kitty/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/features/kitty/default.nix)).
4. Hosts as a one-screen list of names.

**Know the trade-off:** adding a feature is *two edits* (create the file, add its name to an import list), where infra's is one. That is the "name proliferation" cost the README warns about, kept in check here by the bundles.

**Do not copy** (both make evaluation depend on the machine it runs on): `/etc/nixos/hardware-configuration.nix` is imported from outside the repository by [`modules/system/core/default.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/core/default.nix), and `flakeLocation = builtins.getEnv "PWD"` in [`modules/system/core/nix-settings.nix`](https://git.voidarc.co.uk/voidarc/nixos/src/commit/b708a8204632127b339d61da2e153876f45a5a56/modules/system/core/nix-settings.nix) reads the caller's working directory during evaluation. The first one is why voidarc's README says every rebuild needs `--impure`; the second silently yields an empty string in pure mode.

---

## 6. Side by side

| Aspect | README (the pattern) | infra | voidarc |
|---|---|---|---|
| Entry point | only `flake.nix` / `default.nix` are not modules | generated `flake.nix` → `outputs.nix` | `flake.nix`, one line of `outputs` |
| Auto-import | "a trivial expression or a small library" | import-tree, minus `*.pkg.nix` | import-tree |
| Top level | flake-parts (or plain `evalModules`) | flake-parts | flake-parts |
| Store for lower-level modules | an option of type `deferredModule`; **declare your own**, since `flake.modules` alone is called an anti-pattern | own options: `nixos.modules.*`, `homeManager.modules.*`, `users.<n>.*` | built-in `flake.nixosModules.*` |
| Granularity | merge non-distinct modules under one name | two roles (`base`, `pc`) plus a few named opt-ins | one name per feature, plus bundles |
| How a host gets its features | (open) | import a role and some named modules; features merge *themselves* into roles | a list of names in `nixosSystem { modules = ...; }` |
| Host | a lower-level configuration built from stored modules | entry in `nixos.configurations.<name>` (a `module`, plus a hardware report) | `flake.nixosConfigurations.<HOST> = nixosSystem {...}` per host |
| home-manager | just another class, nested in NixOS | nested; per-user typed slots (`home.base`, `home.gui`) | not used; wrapped packages instead |
| Cross-class features | *the* motivating case | one file writes into several stores (`home.base` and `nixos.modules.base`) | one file writes a NixOS module and a package |
| Sharing values | via the top-level config; `specialArgs` is an anti-pattern | typed top-level options, `_module.args`, closures | closures (`self`, `inputs`) and `perSystem` args |
| Packages | `callPackage` files are an accepted exception (`*.pkg.nix`) | `*.pkg.nix` plus `perSystem.nixpkgs.overlays` | inline `perSystem.packages.<app>`, wrapped |
| `systems` | n/a | derived from the hosts | a fixed list |
| Adding a feature | add a file | add a file | add a file **and** an import-list entry |
| Repo tooling | n/a | flake-file, files, treefmt, statix, git hooks, checks | wrapper modules, `nix run` apps |
| Purity | n/a | pure: IFD off, evaluation warnings abort | impure: `/etc/nixos/...`, `getEnv "PWD"` |

## 7. Glossary

| Term | Meaning here |
|---|---|
| **top-level module / configuration** | A file under `modules/` / the flake-parts evaluation that merges them all. |
| **lower-level module / configuration** | A NixOS, home-manager, ... module / the evaluation that consumes it. |
| **class** | The kind of module system a lower-level module is for (`nixos`, `homeManager`, `darwin`, ...). flake-parts tags stored modules with `_class`, and mismatches are errors. |
| **`deferredModule`** | An option type whose value is *a module*. Several definitions merge into one module that imports them all. |
| **feature** | The unit a file implements. Often called an *aspect*, the term used by vic's separate `den` library; the README itself says "feature". |
| **role** | A stored module that many features merge into (`base`, `pc`, `desktop`). Hosts import a role instead of a hundred features. |
| **named / opt-in module** | A stored module only some hosts import (`efi`, `zfs`, `vm`). |
| **bundle** | voidarc's "attr": a stored module that mostly `imports` other stored modules. |
| **`perSystem`** | flake-parts' per-platform section: `packages`, `devShells`, `formatter`, `checks`. |
| **`withSystem` / `moduleWithSystem`** | Ways for a *lower-level* module to read `perSystem` values. |
| **`key`** | A module's identity for de-duplication. Paths are keyed by path; anonymous modules are not. |
| **`_` prefix** | Files/dirs whose name starts with `_` are skipped by import-tree. |
| **`*.pkg.nix`** | A `callPackage`-style file, excluded from auto-import by convention. |
| **`flake.modules`** | flake-parts' optional generic store: `flake.modules.<class>.<name>`. |
| **`specialArgs` pass-thru** | Threading values into lower-level evaluations by hand. The thing the pattern replaces with closures and top-level options. |

## 8. Your repository on the map

Your repository is closer to infra's *before* picture than to either finished example. `cooked/nixos/` and `cooked/home-manager/` are organised by class, hosts are directories, and the wiring lives in `flake.nix`. Your last commit, however, began in voidarc's dialect: `flake.nixosModules.<name>`, `moduleWithSystem`, and a `modules/aspects/` folder.

| In your repository | Dendritic concept | Closest example |
|---|---|---|
| `flake.nix` with `import-tree` and `rootPath` ✔ | entry point | infra `outputs.nix` (where `rootPath` came from) |
| `modules/pkgs/*` (`perSystem.packages`) ✔ | top-level `perSystem` values | voidarc `features/*` |
| `modules/devshell.nix` ✔ | plumbing module | infra `repository/dev-shell.nix` |
| `modules/aspects/nix.nix`, `development/development.nix` ✔ | feature modules, stored by name | voidarc `system/core/nix-settings.nix`, `attrs/development` |
| `cooked/nixos/*.nix` | NixOS half of features | infra features merged into `nixos.modules.{base,pc}` |
| `cooked/home-manager/*.nix` | **already cross-class features** | infra at adoption: `audio.nix` (§3.3) |
| `cooked.preload.{server,desktop}` | roles | infra `base` / `pc`; voidarc `system/core` / `system/desktop` |
| `cooked.<x>.enable` | the README's `enable`-option anti-pattern | replaced by presence (§3.5) |
| `builtins.any (…) (attrValues config.home-manager.users)` toggles | cross-class composition done by hand | one file, two halves (§3.3) |
| `hosts/dellG5`, `hosts/wsl` | hosts | infra `computers/*.nix`; voidarc `hosts/*/default.nix` |
| `users/daniel` + `daniel/**` | a user: system account + home-manager tree | infra `users.nix` + `modules/mightyiam/**` |
| `nixos/**` (older system config) | to be split by feature | — |
| `modules.old/{XF86,hyprpaper}.nix` | lower-level *option* modules | infra declares options inside `home.gui` modules (`audio.sinkNameMap`) |
| `overlays/`, `lib/mkHomeUsers`, `specialArgs = {inherit inputs;}` | replaced by closures / a nixpkgs module | infra `nixpkgs.nix`; voidarc `system/core/nix-settings.nix` |
| `.github/workflows/verify_configurations.yml` | matrix over the host registry | infra `flake.checks` per host |

Report 2 turns that table into ten steps, each with the same three parts: **the idea**, **how it looks in your repository**, and **where the examples do it**.

## 9. Reading list

- [The Dendritic Pattern](https://github.com/mightyiam/dendritic), the README; its Discussions and the Matrix room `#dendritic:matrix.org` are linked there.
- infra's adoption commit, [`b45e9e1`](https://github.com/mightyiam/infra/commit/b45e9e1): the author's own class-first → feature-first migration.
- [flake-parts](https://flake.parts/): the pages on `flake.modules`, module arguments, `perSystem`, `withSystem` and `moduleWithSystem`.
- [import-tree](https://github.com/denful/import-tree) and its docs.
- Pol Dellaiera, [*Refactoring my infrastructure as code configurations*](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/): a NixOS + home-manager migration write-up, including a per-host *feature list* helper (`loadNixosAndHmModuleForUser`) and a `_to_migrate` folder for gradual migration.
- [flake-file](https://github.com/denful/flake-file): generating `flake.nix` from inputs declared next to the features that need them. (Its README notes that `den`, the "aspect-oriented" library, is no longer considered dendritic by the pattern's own repository.)
