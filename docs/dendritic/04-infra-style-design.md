# An infra-style model for your configuration

### `hosts`, `users` and `modules`: à-la-carte picks with upward inheritance

*Companion to the reports · prepared 2026-09-30 · starting point: branch `dendritic`, commit `0e29b82`.
Report 1: [`01-birds-eye-view.md`](01-birds-eye-view.md) · Report 2: [`02-migration-guide.md`](02-migration-guide.md) · Report 3: [`03-config-notes.md`](03-config-notes.md).*

You want `mightyiam/infra`'s pattern — typed top-level options holding `deferredModule` values — with three changes: hosts pick modules à-la-carte instead of from `base`/`pc` classes; a host's final NixOS module list is the union of what the host picks and what its users need; and user-level configuration stays home-manager shaped, pulling in a system module only when the feature needs one.

This document turns that into code. §1 is the model, §2 the four mechanics it rests on (one of which changes your pseudocode), §3 the schema, §4 worked examples using your own features, §5 a trace of how a host resolves, §6 the comparison with infra, §7 what it changes in Report 2, §8 where your current files go, §9 the gotchas, and §10 the decisions left for you.

**Read §2.3 before you write any of this.** Your pseudocode uses `imports` and `config` as slot names inside a submodule; both are module-system keywords there, and the symptom would be confusing rather than loud.

> **A note on verification.** I have no Nix where I work, so nothing here was built. Every mechanism is quoted from the sources listed in §11, and every snippet is syntax-checked. The parts I would test first are named at the end of §11.

## 1. The model

```text
flake-parts top-level config
│
├── modules.<feature>                    NixOS modules, named         ← feature files
│
├── users.<user>                         what a user is
│     ├── username / name / email
│     ├── nixos                          account-level system settings (the one exception)
│     ├── modules.<feature>              { enable; nixos = [ … ]; home = { … }; }
│     └── configuration        (r/o)     union of that user's `home` parts
│
└── hosts.<host>                         what a machine is
      ├── hostPlatform
      ├── modules.<name>                 à-la-carte picks + host-local modules
      ├── users.<user>                   { enable; modules.<feature>.enable; nixos }
      ├── module                 (r/o)   host picks ∪ users' NixOS needs ∪ accounts
      └── configuration         (r/o)    nixosSystem of `module`
                                           ↓
                              flake.nixosConfigurations.<host>
```

Three things to notice.

**Inheritance runs upward, and the union is computed once.** A feature file contributes `modules.<feature>` (the system half). A user file contributes `users.<user>.modules.<feature>`, which names the system modules it needs and carries its own home-manager config. A host picks `modules.*` by name and lists which users it has. The host's `module` option is then *derived*: its own picks, plus every NixOS module its users asked for, plus one account module per user. Nothing is written twice.

**A user's `modules.<feature>` is where the two classes meet, and it is still one place.** `nixos` is a list of NixOS modules; `home` is a home-manager module. Both belong to one feature of one user, in one attribute.

**Hosts can adjust users, not just select them.** `hosts.<host>.users.<user>.modules.<feature>.enable = false;` removes a feature on one machine. That is what makes one user definition usable on both a laptop and a server.

## 2. Four mechanics it rests on

### 2.1 `deferredModule` merges, so a name can be filled from many files

`types.deferredModule`'s merge collects every definition into one module (types.nix, `deferredModuleWith`):

```nix nosyntax
      merge = loc: defs: {
        imports =
          staticModules
          ++ map (
            def: lib.setDefaultModuleLocation "${def.file}, via option ${showOption loc}" def.value
          ) defs;
      };
```

So `modules.locale = { time.timeZone = "Europe/London"; };` in one file and `modules.locale = { i18n.defaultLocale = "en_GB.UTF-8"; };` in another produce one module with both. infra uses this for `nixos.modules.base`, which dozens of files contribute to. It is why your `modules` namespace can be open: any file may add to any feature name.

### 2.2 `key` deduplicates, which is what makes the union safe

This is the mechanism the à-la-carte union depends on. Two import routes that reach the same module must evaluate it once, or a module that declares options will be evaluated twice and NixOS will report the option as already declared.

The module system collects `imports` into a tree keyed by `key`, and `filterModules` flattens it — its docstring says it "returns the final list of **unique-by-key** modules" (modules.nix). The `key` attribute's purpose is stated in the docstring for `importApply`: deduplication "could be achieved by wrapping the returned module and setting the `key` module attribute".

infra does exactly that, in `modules/nixos/base.nix`:

**infra @ cb42ec1** — `modules/nixos/base.nix`

```nix nosyntax
{lib, ...}: {
  options.nixos.modules.base = lib.mkOption {
    type = lib.types.deferredModule;
    apply = module: {
      key = "base";
      imports = [module];
    };
  };
}
```

Because every contribution to `nixos.modules.base` is merged into one value before `apply` runs, "base" always names the same module, and a host that reaches it through `pc` *and* directly gets one copy.

**The catch for you:** `apply` belongs to an *option*, and your `modules.<feature>` namespace is open, so the names are not known when the option is declared. §2.4 solves that.

### 2.3 `imports` and `config` are module keywords — your pseudocode needs one change

`unifyModuleSyntax` (modules.nix) defines the reserved attributes. If an attrset has a `config` or `options` key, everything that is not in this list is an error:

```nix nosyntax
      attrsToRemove = [
        "_class"
        "_file"
        "key"
        "disabledModules"
        "imports"
        "options"
        "config"
        "meta"
        "freeformType"
      ];
```

and in the shorthand form (no `config`/`options` key), `imports` is stripped out and everything else *becomes* `config`:

```nix nosyntax
          imports = m.require or [ ] ++ m.imports or [ ];
          options = { };
          config = addFreeformType (removeAttrs m shorthandAttrsToRemove);
```

A submodule's value is a module of that submodule's evaluation. Your pseudocode has a `config` key, so it takes the long-form branch above, and two things follow:

```nix
# your pseudocode — legal Nix, but not what it looks like
{
  users.daniel.modules.zsh = {
    import = [self.modules.zsh];
    config.zsh = {
      # …
    };
  };
}
```

- `import` is not in the reserved list, so it is an **unsupported attribute**, and you get `Module '<submodule>' has an unsupported attribute 'import'`. That error at least points at the right file.
- `config.zsh` becomes the submodule's config, setting an option `zsh` that you have not declared.

Had you written `imports` instead of `import`, it would be quieter and worse: `imports` is reserved, so the list would be read as imports *into the submodule*, and a declared `options.imports` would still be unreachable by that spelling — you would have to write `config.imports = [ … ]` to reach it.

**Use different names.** This document uses `nixos` (a list of NixOS modules) and `home` (a home-manager module). Your `import` spelling is fine too — `import` is not reserved — but `imports` and `config` are not available. Everything else about your pseudocode carries over:

```nix
{
  users.daniel.modules.zsh = {
    nixos = [config.modules.zsh];
    home = {
      programs.zsh.enable = true;
    };
  };
}
```

Two footnotes on the same code. The reference is `config.modules.zsh`, not `self.modules.zsh`: these are typed top-level options, and only flake *outputs* appear on `self`. And `home = {programs.zsh = …}` rather than `home = {zsh = …}`, because `programs.zsh` is the option home-manager declares.

### 2.4 `attrsOf` cannot key by name, so the type does it

Since `apply` needs a declared option, put the keying in the *type*, whose `merge` receives the option path as `loc`. For `modules.zsh`, `loc` is `[ "modules" "zsh" ]`.

```nix nosyntax
  keyedModule = types.mkOptionType {
    name = "keyedModule";
    description = "module";
    descriptionClass = "noun";
    check = types.deferredModule.check;
    merge = loc: defs: {
      key = lib.concatStringsSep ":" loc;
      imports = map (
        def: lib.setDefaultModuleLocation "${def.file}, via option ${lib.options.showOption loc}" def.value
      ) defs;
    };
    inherit (types.deferredModule) getSubOptions getSubModules;
    substSubModules = _: keyedModule;
  };
```

That is `deferredModule`'s own `merge`, plus a `key`. Every value in an option of this type is then deduplicated against itself wherever it is imported, with no cooperation needed from the file that defines it or the file that imports it.

## 3. The schema

Four files. The first three declare options; the last derives hosts.

### 3.1 `modules/repository/types.nix` — the two types

```nix
# modules/repository/types.nix
{
  lib,
  ...
}: let
  inherit (lib) types;

  # A `deferredModule` whose value carries a deduplication key derived from its
  # own option path. See §2.4.
  keyedModule = types.mkOptionType {
    name = "keyedModule";
    description = "module";
    descriptionClass = "noun";
    check = types.deferredModule.check;
    merge = loc: defs: {
      key = lib.concatStringsSep ":" loc;
      imports = map (
        def: lib.setDefaultModuleLocation "${def.file}, via option ${lib.options.showOption loc}" def.value
      ) defs;
    };
    inherit (types.deferredModule) getSubOptions getSubModules;
    substSubModules = _: keyedModule;
  };

  # One feature of one user. `imports` and `config` cannot be used as names
  # here: the module system consumes both as module syntax. See §2.3.
  userFeatureModule = {lib, ...}: {
    options = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Whether this user gets this feature.";
      };
      nixos = lib.mkOption {
        type = types.listOf types.deferredModule;
        default = [];
        description = "NixOS modules this feature needs on every host that has this user.";
      };
      home = lib.mkOption {
        type = types.deferredModule;
        default = {};
        description = "home-manager configuration for this feature.";
      };
    };
  };
in {
  _module.args = {
    inherit keyedModule userFeatureModule;
  };
}
```

### 3.2 `modules/modules.nix` — the à-la-carte namespace

```nix
# modules/modules.nix
{keyedModule, lib, ...}: {
  options.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf keyedModule;
    default = {};
    description = ''
      NixOS modules, by feature name. Hosts pick from here; so do users,
      through `users.<user>.modules.<feature>.nixos`.
    '';
  };
}
```

`lazyAttrsOf` rather than `attrsOf`, so that reading one feature does not force them all. (Both pass the element name to the element type's `merge` as `loc ++ [name]`, which is what `keyedModule` needs; and `optionalValue.value` *is* the merged value, so lazy evaluation does not skip the merge.)

One thing to check when you first evaluate: `modules`, `users`, `hosts` and `module` are plain top-level option names, and a collision with a flake-parts option would appear as a duplicate-declaration error naming both files. Rename (for example to `nixosModules`) if that happens.

### 3.3 `modules/users.nix` — what a user is

```nix
# modules/users.nix
{
  lib,
  userFeatureModule,
  ...
}: {
  options.users = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule (userArgs: {
        options = {
          username = lib.mkOption {
            type = lib.types.str;
            default = userArgs.name;
          };
          name = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          email = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          # The one place a user file writes NixOS: the account itself is a
          # system object, and `users.users.*` has no home-manager equivalent.
          nixos = lib.mkOption {
            type = lib.types.deferredModule;
            default = {};
            description = "System-level settings for this account (groups, shell, SSH keys).";
          };

          modules = lib.mkOption {
            type = lib.types.lazyAttrsOf (lib.types.submodule userFeatureModule);
            default = {};
            description = "The features this user has, on every host that has them.";
          };

          configuration = lib.mkOption {
            readOnly = true;
            type = lib.types.deferredModule;
            default = {
              key = "user-configuration:${userArgs.name}";
              imports = lib.mapAttrsToList (
                fname: feature: {
                  key = "user:${userArgs.name}:${fname}";
                  imports = [feature.home];
                }
              ) (lib.filterAttrs (_: feature: feature.enable) userArgs.config.modules);
            };
            description = "The union of this user's enabled features, as a home-manager module.";
          };
        };
      })
    );
    default = {};
  };
}
```

`configuration` is the user's own union. Hosts do not use it — §5 explains why, and what it is still good for.

### 3.4 `modules/hosts.nix` — what a machine is, and the assembler

```nix
# modules/hosts.nix
{
  config,
  inputs,
  keyedModule,
  lib,
  userFeatureModule,
  ...
}: let
  inherit (lib) types;
  inherit (lib.attrsets) mapAttrs mapAttrsToList attrValues filterAttrs;
  inherit (lib.lists) concatLists;

  # Merge a user's own features with one host's adjustments to them. Host
  # entries that name a feature the user has may disable it and add to it;
  # entries naming a new feature add one.
  mergeFeatures = globalFeatures: hostFeatures:
    (mapAttrs (
      fname: gf: let hf = hostFeatures.${fname} or {}; in {
        enable = gf.enable && (hf.enable or true);
        nixos = gf.nixos ++ (hf.nixos or []);
        home = {imports = [gf.home (hf.home or {})];};
      }
    ) globalFeatures)
    // (mapAttrs (
      fname: hf: {
        enable = hf.enable;
        nixos = hf.nixos;
        home = {imports = [hf.home];};
      }
    ) (filterAttrs (fname: _: !(builtins.hasAttr fname globalFeatures)) hostFeatures));

  userFeatures = hostName: userName:
    filterAttrs
      (_: feature: feature.enable)
      (mergeFeatures
        config.users.${userName}.modules
        config.hosts.${hostName}.users.${userName}.modules);

  # The system side a user brings to a host.
  userNixosModules = hostName: userName:
    concatLists (mapAttrsToList (_: feature: feature.nixos) (userFeatures hostName userName));

  # The account, and the home-manager wiring that hangs off it.
  userAccountModule = hostName: userName: let
    user = config.users.${userName};
  in {
    key = "user-account:${userName}";
    imports = [
      user.nixos
      config.hosts.${hostName}.users.${userName}.nixos
    ];
    config = {
      # `isNormalUser` brings `home`, `group`, `createHome` and `useDefaultShell`
      # with it, so only what is genuinely yours needs saying here.
      users.users.${user.username} = {
        isNormalUser = true;
        description = if user.name != null then user.name else user.username;
      };
      home-manager.users.${user.username}.imports = mapAttrsToList (
        fname: feature: {
          key = "user:${hostName}:${userName}:${fname}";
          imports = [feature.home];
        }
      ) (userFeatures hostName userName);
    };
  };

  homeManagerNixosModule = {
    key = "home-manager";
    imports = [inputs.home-manager.nixosModules.home-manager];
  };

  # The union: the host's picks, then everything its users asked for.
  hostModule = hostName: hostCfg: let
    enabledUsers = filterAttrs (_: u: u.enable) hostCfg.users;
  in {
    key = "host:${hostName}";
    imports =
      (lib.optional (hostCfg.hostPlatform != null) {nixpkgs.hostPlatform = hostCfg.hostPlatform;})
      ++ (attrValues hostCfg.modules)
      ++ (lib.optional (enabledUsers != {}) homeManagerNixosModule)
      ++ (concatLists (mapAttrsToList (
        userName: _:
          [(userAccountModule hostName userName)] ++ (userNixosModules hostName userName)
      ) enabledUsers));
  };
in {
  options.hosts = lib.mkOption {
    type = types.lazyAttrsOf (
      types.submodule (hostArgs: {
        options = {
          hostPlatform = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          modules = lib.mkOption {
            type = types.lazyAttrsOf keyedModule;
            default = {};
            description = "NixOS modules this host picks, by name.";
          };

          users = lib.mkOption {
            type = types.lazyAttrsOf (
              types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = types.bool;
                    default = true;
                  };
                  modules = lib.mkOption {
                    type = types.lazyAttrsOf (types.submodule userFeatureModule);
                    default = {};
                    description = "Per-host adjustments to this user's features.";
                  };
                  nixos = lib.mkOption {
                    type = types.deferredModule;
                    default = {};
                    description = "Per-host system-level account settings.";
                  };
                };
              }
            );
            default = {};
          };

          module = lib.mkOption {
            readOnly = true;
            type = types.deferredModule;
            default = hostModule hostArgs.name hostArgs.config;
          };

          configuration = lib.mkOption {
            readOnly = true;
            type = types.attrs;
            default = inputs.nixpkgs.lib.nixosSystem {modules = [hostArgs.config.module];};
          };
        };
      })
    );
    default = {};
  };

  config = {
    flake.nixosConfigurations = mapAttrs (_: host: host.configuration) config.hosts;

    flake.checks = lib.mapAttrs' (
      hostName: host:
        lib.nameValuePair "nixos-${hostName}" host.configuration.config.system.build.toplevel
    ) config.hosts;
  };
}
```

Notes on that file.

- **`module` and `configuration` are both derived.** `module` is the assembled NixOS module; `configuration` is its evaluation. `flake.nixosConfigurations` and `flake.checks` both read `configuration`, so each host is evaluated once.
- **`nixosSystem` with no `system` argument** is what you want. nixpkgs' `nixosSystem` sets `system = null` itself — "Allow system to be set modularly in nixpkgs.system. We set it to null, to remove the 'legacy' entrypoint's non-hermetic default" — so the platform comes from `nixpkgs.hostPlatform`, which `hostPlatform` sets. infra does the same by hand (`args = {system = null;}` in `modules/nixos.nix`) because its nixpkgs input is `flake = false`; yours is a flake.
- **home-manager's NixOS module is added when the host has users**, keyed, so a host that lists the same user twice still imports it once.
- **No `specialArgs`.** Every value these modules need is already in the top-level `config`.

## 4. Writing features, users and hosts

### 4.1 A feature with a system half: zsh

```nix
# modules/nixos/zsh.nix — the system half
{pkgs, ...}: {
  modules.zsh = {
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
  };
}
```

```nix
# modules/users/daniel/zsh.nix — the user half
{config, ...}: {
  users.daniel.modules.zsh = {
    nixos = [config.modules.zsh];
    home = {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        shellAliases = {
          ll = "ls -l";
          gs = "git status";
        };
      };
    };
  };
}
```

One feature, two files, no cross-reference except the `nixos` list. Splitting the user half into one file per feature is what keeps `modules/users/daniel/` from becoming a single long file; merging is by feature name, so the split is invisible.

### 4.2 A feature that only exists for one user

Most of `daniel/**` is like this — no system half at all:

```nix
# modules/users/daniel/yazi.nix
{...}: {
  users.daniel.modules.yazi.home = {
    programs.yazi.enable = true;
    programs.yazi.settings.mgr.show_hidden = true;
  };
}
```

`nixos` stays empty, and the host is unaffected.

### 4.3 Hosts

```nix
# modules/hosts/dellG5.nix
{config, ...}: {
  hosts.dellG5 = {
    hostPlatform = "x86_64-linux";
    modules = {
      inherit (config.modules) locale networking sound printing;
      hardware = ./hardware.nix;
    };
    users.daniel = {
      enable = true;
      nixos = {
        users.users.daniel.extraGroups = ["video" "networkmanager" "wheel"];
      };
    };
  };
}
```

```nix
# modules/hosts/wsl.nix — the same user, without the desktop
{config, ...}: {
  hosts.wsl = {
    hostPlatform = "x86_64-linux";
    modules = {
      inherit (config.modules) locale networking;
      wsl = config.modules.wsl;
    };
    users.daniel = {
      enable = true;
      modules.hyprland.enable = false;
    };
  };
}
```

`inherit (config.modules) …` reads exactly like the a-la-carte list you asked for, and a path is a valid `deferredModule` value, so `hardware.nix` needs no wrapper.

## 5. How a host resolves

For `dellG5`, `hosts.dellG5.module` — the module handed to `nixosSystem` — is:

| Contributed by | Entries in `imports` | Key |
|---|---|---|
| `hostPlatform` | `{nixpkgs.hostPlatform = "x86_64-linux";}` | positional (one per host) |
| `hosts.dellG5.modules` | `locale`, `networking`, `sound`, `printing`, `hardware.nix` | `hosts:dellG5:modules:<name>` |
| the assembler, because the host has users | home-manager's NixOS module | `home-manager` |
| user `daniel` | the account module (`users.users.daniel`, `home-manager.users.daniel.imports`) | `user-account:daniel` |
| user `daniel`'s features | `modules.zsh`, `modules.hyprland`, … — from each feature's `nixos` list | `modules:<feature>` |

and the home-manager side lands as `home-manager.users.daniel.imports = [ … ]`, one keyed module per enabled feature (`user:dellG5:daniel:<feature>`), each wrapping that feature's `home`.

Three consequences worth stating.

**The same module reached twice is evaluated once.** If `dellG5` also picked `modules.zsh` — reasonable, since the system half sets `users.defaultUserShell` — then `modules.zsh` arrives both from the host and from daniel's zsh feature. Both carry the key `modules:zsh`, so the second is dropped. That is §2.2 earning its keep, and it is the whole reason for the custom type: with a plain `deferredModule` this specific case would evaluate the module twice.

**A feature a user has is on every host that user is on**, unless a host disables it. That is what `hosts.wsl.users.daniel.modules.hyprland.enable = false` is for.

**Why hosts do not read `users.<user>.configuration`.** That option unions the user's own features, which is what makes it useful for inspection and for hosts that override nothing. But a host that sets `enable = false` has to be able to subtract, and you cannot subtract from a merged module — so the host recomputes the union from the merged feature set (`userFeatures` in §3.4). If you decide you will never override per host, replace the `home-manager.users.${…}.imports` block in §3.4 with `[config.users.${userName}.configuration]` and delete `mergeFeatures`.

## 6. Compared with infra

| | infra | yours |
|---|---|---|
| Host declaration | `nixos.configurations.<host>.module`, written by hand, lists its `imports` | `hosts.<host>.modules`, picked by name; `module` derived |
| Evaluation | `import "${inputs.nixpkgs}/nixos/lib/eval-config.nix"` with `args = {system = null;}`, because nixpkgs is `flake = false` | `inputs.nixpkgs.lib.nixosSystem` |
| Result | `nixos.configurations.<host>.configuration`, read-only | `hosts.<host>.configuration`, read-only |
| System modules | two fixed classes, `nixos.modules.{base,pc}` | `modules.<feature>`, open |
| User modules | four fixed slots per user (`home.{base,gui}`, `nixos.{base,pc}`) | `users.<user>.modules.<feature>`, open |
| Inheritance | static, via `deferredModuleWith { staticModules = [ … ]; }` | computed, in `mergeFeatures` |
| `key` | a literal per option (`"base"`, `"${name}-pc"`) | derived from the option path, by `keyedModule` |
| Users on hosts | hosts import `config.users.<n>.nixos.base` / `.pc` | `hosts.<host>.users.<n>` selects, and may adjust per feature |
| Kept from infra | typed options, `deferredModule` merging, `key` for dedup, read-only `configuration`, per-host checks | — |

The trade is explicit: infra's `staticModules` composition is simpler and entirely declarative, and costs you the fixed `base`/`pc` ladder you said you do not want. Your version trades a computed merge — about fifteen lines in `hosts.nix` — for an open namespace in both dimensions.

## 7. What this changes in Report 2

Report 2 assumed flavour B (`flake.modules.<class>.<name>`) and roles. This is flavour C, so:

| Report 2 | Now |
|---|---|
| D1 — store modules in `flake.modules.{nixos,homeManager}` | Superseded. Store them in `modules.*` (NixOS) and `users.<n>.modules.*.home` (home-manager). |
| D2 — roles `nixos.base`, `nixos.desktop`, `homeManager.base`, `homeManager.gui` | Gone. Hosts pick by name; there is no role layer. |
| D3 — hosts as `nixosConfigurations/<host>` plus an assembler | Same idea, different shape: `hosts.<host>` with derived `module` and `configuration`. |
| D4 — one typed option `owner` | Becomes fields on `users.<user>` (`username`, `name`, `email`), as infra has. |
| D5 — layout `modules/{repository,nixpkgs,pkgs,hosts,users,aspects}` | Becomes `modules/{repository,modules,users,hosts}` plus your `pkgs/`. `modules` replaces `aspects` as the system side; the user side lives under `users/`. |
| D6 (strangler), D7 (`systems`), D8 (HM as a NixOS module) | Unchanged. |
| Steps 0, 9, 10 | Unchanged. |
| Steps 1–4 | Need rewriting: they exist to install flavour B, roles and the old assembler. Steps 5–8 move content and survive, but their destinations change (§8). |

Step 0's baseline is still the right first move, and it matters more now: this is a larger change than the one Report 2 described. Say the word and I will rewrite Steps 1–4 against this model.

## 8. Where your current files go

| Today | Destination |
|---|---|
| `cooked/nixos/*.nix` (fonts, gnupg, network, scripts, sops, vm, services/*) | `modules.<feature>`, one or more files each |
| `cooked/home-manager/*.nix` (git, tmux, zsh, hyprland, nix-index) | split: the system half into `modules.<feature>`, the home-manager half into `users.daniel.modules.<feature>.home` |
| `daniel/**`, `users/daniel/**` | `users.daniel.modules.<feature>.home`, one file per feature |
| `users/daniel/default.nix` (account, `home.*`) | `users.daniel.nixos` (groups, shell) + `users.daniel.modules.*.home` (the rest) |
| `nixos/configuration.nix` | `users.daniel.nixos` (the account) + `modules.<feature>` (polkit and sudo, syncthing ports, the package list) |
| `hosts/dellG5/*`, `hosts/wsl/*` | `hosts.<host>.modules.*`, with `hardware.nix` as one entry |
| `modules/pkgs/**`, `modules/devshell.nix` | unchanged: `perSystem.packages` and the dev shell |
| `modules/aspects/nix.nix` | `modules.nix-settings`, minus the circular `hostPlatform` — `hosts.<host>.hostPlatform` replaces it (Report 2, audit row 1 and Step 1) |

## 9. Gotchas

1. **Never name a slot `imports` or `config`** (§2.3). Which symptom you get depends on the spelling: with a `config` key in the same attrset, `Module … has an unsupported attribute`; with `imports`, the list is silently consumed as imports into the submodule, and the option you declared under that name simply never receives a value.
2. **Keys must be unique per distinct module.** Two different modules sharing a key means one is silently dropped. `keyedModule` makes this safe by construction, since the key *is* the path.
3. **A user's features follow that user everywhere.** Disable per host; do not define a second user to get a smaller desktop.
4. **home-manager modules cannot see the top-level `config`.** They are a separate evaluation. Use `osConfig` (home-manager provides it), or declare the value as a home-manager option and set it from the user's `home`. Do not reach for `extraSpecialArgs`.
5. **`users.<user>.configuration` is the user's own union, not the host's** (§5). Inspect it freely; do not wire it to a host that overrides anything.
6. **A host naming a user that does not exist fails loudly** (`attribute 'daniel' missing`), which is what you want — `config.users.${userName}` is strict by design.
7. **`nix flake show` will not list `hosts`, `users` or `modules`** — they are typed options, not flake outputs. It will list `nixosConfigurations`, which is what your CI reads.
8. **`flake.checks` builds every host on `nix flake check`.** With one system that is fine. When you add a second, gate it by system the way infra does.
9. **Do not put a home-manager module in `modules.*`**, or the reverse. You get `cannot be imported into a module evaluation that expects class "nixos"`, which is at least a clear error.
10. **Host-local modules go in `hosts.<host>.modules`, not in `modules.*`.** A `modules.<feature>` entry is shared machinery; something only one machine has belongs to that machine.

## 10. Decisions left for you

1. **Slot names.** `nixos` + `home` (used here), or your `import` + `home`. Not `imports` + `config`.
2. **Where the account lives.** As designed: `users.<user>.nixos` for account-level system settings, features contributing groups through their `nixos` lists. The alternative is features-only, which means every group becomes a feature.
3. **home-manager's NixOS module**: added by the assembler when a host has users (as here), or a `modules.home-manager` every host picks explicitly? The second is more à-la-carte and more repetitive.
4. **Inline home-manager config.** If you would rather write `users.daniel.modules.zsh = { nixos = […]; programs.zsh.enable = true; };` with no `home` wrapper, that is a freeform submodule: `types.submoduleWith { freeformType = types.deferredModule; modules = [userFeatureModule]; }`. The module system merges undeclared definitions into `config` (`recursiveUpdate freeformConfig declaredConfig`), so the home-manager part is then everything that is not `nixos`. It reads better and gives worse errors: a typo in a home-manager option becomes "option does not exist" from home-manager rather than from your submodule. I have not tested it; try it once hosts build.
5. **Exporting `flake.modules` as well.** Typed options are invisible outside your flake. If you ever want another flake to reuse `modules.zsh`, publish it; otherwise skip it.

## 11. Verification notes

**Read for this document**

- `mightyiam/infra` @ `cb42ec1` (2026-09-24): `outputs.nix`, `modules/nixos.nix`, `modules/nixos/{base,pc}.nix`, `modules/users.nix`, `modules/home-manager.nix`, `modules/eval-modules.nix`, and the host files `modules/computers/{molly,dobby,astraeus}.nix`.
- nixpkgs @ `6774f7bc` — the revision your `flake.lock` pins (2026-09-22): `lib/modules.nix` (`unifyModuleSyntax`, `collectStructuredModules`, `filterModules`, the `importApply` docstring), `lib/types.nix` (`deferredModuleWith`, `submoduleWith`).
- home-manager @ `0b2f112` — the revision your lock pins: `nixos/common.nix`, which defines `home-manager.users = mkOption { type = types.attrsOf hmModule; }` where `hmModule` is a `submoduleWith` of class `homeManager`. That is what makes `home-manager.users.<name>.imports = [ … ]` work.
- The dendritic README, for the anti-patterns §7 steers by.

**Verified by reading**

- `key` gives deduplication, and `filterModules` returns unique-by-key modules.
- `imports` and `config` are consumed as module syntax, so they cannot be submodule option names.
- `deferredModule` merges multiple definitions into one module.
- `home-manager.users.<name>` is a submodule, so `imports` works there.
- `attrsOf` and `lazyAttrsOf` both hand the element name to the element type as `loc ++ [name]`, so a type-level `merge` can key by name; and `optionalValue.value` is the merged value, so laziness does not skip it.
- `nixosSystem` sets `system = null` itself, so `nixpkgs.hostPlatform` in a module is the supported way to set the platform.

**Not verified: please read this**

- **Nothing was evaluated or built.** There is no Nix in the environment I work in.
- **`keyedModule` is the least-proven part.** It mirrors `deferredModule`'s definition, but a hand-written option type is the kind of thing that fails on a missing field. Test it first, with the smallest possible case: two files contributing to one `modules.<name>`, and a host and a user both importing it. If `nix flake check` is clean and the option is not declared twice, the type is right.
- **The lazy-evaluation interactions are reasoned about, not observed**: `hosts.<host>.configuration` reading `config.users`, and `users.<user>.configuration` reading its own `modules`. Both follow the pattern infra uses for `configuration`, but if you see `infinite recursion encountered`, these are the first two places to look.
- **Test in this order once `nixosConfigurations` exists again:** one feature with only a `home` half; one with both halves; a host with one user; the same user on a second host with one feature disabled; and only then the à-la-carte list.
