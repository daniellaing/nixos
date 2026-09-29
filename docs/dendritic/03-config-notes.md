# Notes on your current configuration

### Things I found in `daniellaing/nixos` that hold whatever layout it ends up with

*Companion to the two reports · prepared 2026-09-29 · starting point: branch `dendritic`, commit `0e29b82`.
Report 1: [`01-birds-eye-view.md`](01-birds-eye-view.md). Report 2: [`02-migration-guide.md`](02-migration-guide.md).*

While auditing your repository for the migration guide I noticed several things that have nothing to do with the dendritic pattern. Report 2 mentions three of them in one short paragraph ("Where you are now"). This note gives them, and the further ones I found when I looked properly, a fuller treatment: what it is, the evidence, why it matters, the options, a check you can run, and when to do it relative to the migration steps.

**N1 to N4 expand the three bullets under "Where you are now" in Report 2**: Hyprland's `follows`, the `ksshaskpass` path and `nixpkgs-stable`. `my_neovim`'s `follows` is a sentence inside the first bullet there, and gets a note of its own here (N2). **N5 to N12 are new.** The seven migration findings in the guide's audit table are indexed at the end.

**How far to trust each statement.** Nothing here was evaluated or built, because I have no Nix where I work. A statement tagged **[verified]** was read from your files, from `flake.lock`, or from upstream sources and documentation at the revisions named. For this note I fetched your *pinned* nixpkgs (`6774f7bc`, 2026-09-22) and home-manager (`0b2f112`, 2026-09-22), not `master`. A statement tagged **[inferred]** follows from those but needs an evaluation to confirm, and comes with the command that settles it. "Method and limits" at the end says what was and was not checked.

## At a glance

| # | Note | Where | Effort | When |
|---|---|---|---|---|
| [N1](#n1--hyprland-follows-your-nixpkgs) | Hyprland is built from your nixpkgs, so its Cachix cache no longer matches | `flake.nix:35` | delete 1 line | edit before Step 0, verify at M1 |
| [N2](#n2--my_neovim-follows-your-nixpkgs-and-flake-parts) | `my_neovim` now follows your `nixpkgs` and `flake-parts` | `flake.nix:44-47` | a decision | before Step 0 |
| [N3](#n3--a-hard-coded-ksshaskpass-store-path) | Hard-coded `ksshaskpass-5.27.7` store path, probably inert | `nixos/configuration.nix:57` | delete 1 line, or write 4 | after Step 5, own commit |
| [N4](#n4--nixpkgs-stable-is-an-end-of-life-release) | `nixpkgs-stable` is the end-of-life `nixos-25.05`, used for one package | `flake.nix:9-11`, `hosts/wsl/home.nix:5` | a decision | before Step 3 |
| [N5](#n5--ci-workflows) | CI: a dead run link, a step that can never re-apply commits, an unpinned action, three smaller items | `.github/workflows/` | small | any time; Step 9c |
| [N6](#n6--nix-colors-is-archived-upstream) | `nix-colors` is archived upstream | `flake.nix:50-53`, `daniel/**` | nothing now | any time |
| [N7](#n7--the-disko-input-is-never-used) | `disko` is declared and never used | `flake.nix:18-21` | delete 4 lines | any time |
| [N8](#n8--secretsyaml-is-tracked-but-gitignored) | `secrets.yaml` is tracked but listed in `.gitignore` | `.gitignore:3` | delete 1 line | any time |
| [N9](#n9--the-sudo-rules-are-passwordless-root) | Four sudo rules amount to passwordless root | `nixos/configuration.nix:33-55` | a decision | at Step 5 |
| [N10](#n10--the-adbusers-group-no-longer-exists) | The `adbusers` group no longer exists | `nixos/configuration.nix:26` | delete 1 line | Step 7 |
| [N11](#n11--garbage-collection-went-from-weekly-to-daily) | `nix.gc.dates` changed from weekly to daily | `modules/aspects/nix.nix:16` | a decision | before Step 0 |
| [N12](#n12--small-leftovers) | Small leftovers | various | trivial | any time |

**If you do only three things:** N1 (it costs you compile time on almost every update), N4 (an unsupported release channel) and N5 (a CI step that silently throws away work). The rest are tidy-ups or decisions.

**Suggested order.** *Before Step 0:* N1, N2, N4 and N11 are all one-line edits or decisions in `flake.nix` and `modules/aspects/nix.nix`. Each of N1, N2 and N11 removes one of the "expected differences" in Step 0's baseline comparison if you revert it, and N4 makes Step 3 smaller. *During the migration:* N3, N9 and N10 belong to files that move in Steps 5 and 7. The guide keeps those moves pure on purpose, so do each fix as its own commit afterwards. *Any time:* N5 to N8 and N12.

---

## The notes Report 2 mentions (N1 to N4)

### N1 — Hyprland follows your nixpkgs

**What.** The dendritic commit gave `hyprland` a `follows`. On `master` it was a bare URL.

**your repo @ master** — `flake.nix:7`

```nix nosyntax
    hyprland.url = "github:hyprwm/Hyprland";
```

**your repo @ dendritic** — `flake.nix:33-36`

```nix nosyntax
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

**Why it matters.**

- **The binary cache stops matching. [verified]** Hyprland's wiki says: "Do **not** override Hyprland's `nixpkgs` input unless you know what you are doing. Doing so will render the cache useless, since you're building from a different Nixpkgs commit." ([Cachix page](https://wiki.hypr.land/Nix/Cachix/)). The same page says the flake package is not built by Hydra, so `cache.nixos.org` does not have it either. You rely on that cache: `cooked/home-manager/hyprland.nix:13-16` adds `hyprland.cachix.org` as a substituter. With the `follows`, every update that moves your nixpkgs (nearly every weekly one) gives Hyprland a new derivation that no cache has, so it is compiled from source.
- **Its libraries follow too. [verified from `flake.lock`]** Each input of Hyprland that has a `nixpkgs` (aquamarine, hyprcursor, hyprgraphics, hyprland-guiutils, hyprland-protocols, hyprlang, hyprutils, hyprwayland-scanner, hyprwire, xdph and pre-commit-hooks) points at `hyprland/nixpkgs`, which is now your `nixpkgs`. The whole stack is built from it.
- **Your mesa workaround stops doing anything. [verified]** The block below takes `mesa` from `inputs.hyprland.inputs.nixpkgs`. That is the workaround the wiki gives for a mesa mismatch between your system and Hyprland ([Hyprland on NixOS](https://wiki.hypr.land/Nix/Hyprland-on-NixOS/)). With the `follows`, that input *is* your nixpkgs, so `hardware.graphics.package` becomes the mesa you would have had anyway. It is harmless, but the code no longer does what it says.

**your repo @ dendritic** — `cooked/home-manager/hyprland.nix:25-31`

```nix nosyntax
      hardware.graphics = let
        ps = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      in {
        package = ps.mesa;
        enable32Bit = true;
        package32 = ps.pkgsi686Linux.mesa;
      };
```

**Options.**

| | Change | Result |
|---|---|---|
| A | Delete `flake.nix:35`, then run `nix flake lock` | `master`'s behaviour. Hyprland uses its own pinned nixpkgs, the Cachix cache matches, and the mesa workaround works as designed. The lock gains an extra nixpkgs entry (Hyprland's own). |
| B | Use nixpkgs' Hyprland: `programs.hyprland.enable = true;` with no `package` or `portalPackage`. Delete the `hyprland` input, the Cachix lines and the mesa override. | Hydra builds and caches it against your nixpkgs, so there is nothing to compile and nothing to keep in sync. The price is that Hyprland lags upstream by as much as nixpkgs does. The wiki: "This will use the Hyprland version included in the Nixpkgs release you're using." |
| C | Keep the `follows` | Accept local builds. Then delete the Cachix lines and the mesa override, which no longer do anything. |

A is the smallest change and restores what you had. B is the easiest to live with if you do not need Hyprland's development branch.

**Check.** It needs a host to evaluate, so run it at M1 (the end of Step 4):

```sh
nix build .#nixosConfigurations.dellG5.config.system.build.toplevel --dry-run 2>&1 | grep -iE 'hypr|aquamarine'
```

With the Cachix substituter active in the machine's `nix.conf` (it is, from earlier generations), Hyprland and its libraries should be listed under "will be fetched", not "will be built". *(Not run.)*

**When.** Edit before Step 0. Item 3 of Step 0 lists this `follows` as an expected difference. If you revert it first, the baseline and your flake agree about Hyprland and one difference disappears.

### N2 — my_neovim follows your nixpkgs and flake-parts

**What.** The same commit added two overrides to `my_neovim`. On `master` it was `url` only.

**your repo @ dendritic** — `flake.nix:42-48`

```nix nosyntax
    my_neovim = {
      url = "github:daniellaing/neovim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
```

**What I found.** This one is *not* a problem in the way N1 is.

- **Both targets exist. [verified from `flake.lock`]** `my_neovim` has `flake-parts`, `nixpkgs` and `nixvim` inputs, so Nix will not warn about an override for a non-existent input.
- **There is no cache to lose. [verified]** The `flake.nix` in `github:daniellaing/neovim` declares no `nixConfig` and no extra substituter, and it tracks `nixos-unstable`, as you do.
- **Everything neovim uses now shares your nixpkgs. [verified]** Its own `nixvim` input already follows its `nixpkgs`, so through your override nixvim and the plugins use your nixpkgs too. That is why `flake.lock` holds exactly two nixpkgs entries, the root one and `nixpkgs-stable`.
- **The consequence is a different derivation from `master`'s**, which Step 0 lists as an expected difference. A nixvim revision that lags your nixpkgs can also warn or break on a plugin rename. That is the usual price of a `follows`.

**Options.** Keeping it is sensible: one nixpkgs, and a smaller lock. If neovim misbehaves after a lock update, look here first. Either run `nix flake update my_neovim`, or delete the `inputs = { … };` block to get `master`'s behaviour back.

**When.** Before Step 0, only if you decide to revert it.

### N3 — A hard-coded ksshaskpass store path

**What.**

**your repo @ dendritic** — `nixos/configuration.nix:57`

```nix nosyntax
  programs.ssh.askPassword = "/nix/store/pg42226jhbpjp47s03h0glzxyxq36h6i-ksshaskpass-5.27.7/bin/ksshaskpass";
```

**Evidence.**

1. **Nothing keeps that path alive. [verified]** A string literal has an empty *string context*, so Nix does not know it names a store path ([Nix manual](https://nix.dev/manual/nix/latest/language/string-context)). Nothing in your configuration makes it a dependency, so nothing keeps it alive. With `nix.gc` running daily and `--delete-older-than 14d` (`modules/aspects/nix.nix:14-18`), an unreferenced path goes at the next collection.
2. **Your nixpkgs cannot rebuild it. [verified]** `5.27.7` is a Plasma 5 release. At your pinned nixpkgs, `pkgs/desktops/` contains `enlightenment gnome lomiri lumina lxqt mate pantheon xfce` and no `plasma-5`. The package now lives at `kdePackages.ksshaskpass`, version 6.7.5, with `meta.mainProgram = "ksshaskpass"`.
3. **The setting is probably not even in effect. [inferred]** `programs.ssh.askPassword` reaches `SSH_ASKPASS` only when `programs.ssh.enableAskPassword` is true, and that defaults to `services.xserver.enable` (nixpkgs `nixos/modules/programs/ssh.nix`). Your repository never enables the X server; its only `services.xserver.*` line is `videoDrivers` (`hosts/dellG5/hardware.nix:102`). SDDM runs with `wayland.enable = true`, which the SDDM module accepts *instead of* the X server (its assertion reads "SDDM requires either services.xserver.enable or services.displayManager.sddm.wayland.enable to be true"). In your pinned nixpkgs, the only modules that set `services.xserver.enable` are the graphical installer image, `profiles/graphical.nix`, the Lomiri desktop module and the terminal-server module (found by parsing every file under `nixos/modules`), and your repository imports none of them; the NixOS-WSL modules at your pin never mention `xserver`. So the option is probably off and the line is dead configuration.

**Check.** Once Step 4 has the hosts back:

```sh
nix eval .#nixosConfigurations.dellG5.config.programs.ssh.enableAskPassword
nix eval .#nixosConfigurations.wsl.config.programs.ssh.enableAskPassword
```

**Fix.** If both print `false` and you do not miss a graphical passphrase prompt, delete the line. If you do want one (for instance for `git push` over SSH from a program with no terminal), say so explicitly and reference the package:

**proposed**

```nix
{
  lib,
  pkgs,
  ...
}: {
  programs.ssh = {
    enableAskPassword = true;
    askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;
  };
}
```

**When.** After Step 5. The guide deliberately keeps the literal while `nixos/configuration.nix` is split up, so that Step 5 is a pure move. Fix this in its own commit afterwards, in `aspects/security.nix`.

### N4 — nixpkgs-stable is an end-of-life release

**What.**

**your repo @ dendritic** — `flake.nix:9-11`

```nix nosyntax
    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-25.05";
    };
```

**Evidence.**

- **The release is over. [verified]** NixOS 25.05 "Warbler" stopped receiving security updates after 2025-12-31 ([25.11 announcement](https://nixos.org/blog/announcements/2025/nixos-2511/)). 25.11 itself reached end of life on 2026-06-30, and the current release is 26.05 "Yarara", published 2026-05-30 and supported until 2026-12-31 ([release announcements](https://nixos.org/blog/announcements/)).
- **Your lock agrees. [verified]** `nixpkgs-stable` was last locked on 2026-01-02 (rev `ac62194c3`, 270 days old today). The branch stopped moving, so the weekly update PR has nothing to bring for this input.
- **It serves one package. [verified]** The only use is `hosts/wsl/home.nix:5`, `package = pkgs.stable.gitSVN;`, reaching it through the `stable` overlay that lived in `overlays/default.nix` on `master`. Nothing else references `nixpkgs-stable` or `pkgs.stable`. There is no comment saying why stable was chosen.

**Options.**

| | Change | Result |
|---|---|---|
| A | Try `pkgs.gitSVN` from your main nixpkgs. It exists at your pin (`gitSVN = lowPrio (git.override { svnSupport = true; });` in `pkgs/top-level/all-packages.nix`). If it builds and works, delete the `nixpkgs-stable` input and skip the `stable` overlay in Step 3. | One input and one overlay fewer, and no channel to keep bumping. |
| B | Point it at `nixos-26.05`. | Works, but 26.05 is supported only until 2026-12-31, so you would be bumping again within three months and then every six. |

**proposed** (option A, `hosts/wsl/home.nix`)

```nix
{pkgs, ...}: {
  home-manager.sharedModules = [
    ({...}: {
      programs.git = {
        package = pkgs.gitSVN;
      };
    })
  ];
}
```

**Check.** I do not know why stable was chosen, and the way to find out is to try. After Step 4, build the WSL host's package: `nix build .#nixosConfigurations.wsl.pkgs.gitSVN`. *(Not run.)*

**When.** Decide before Step 3, because Step 3 re-creates the `stable` overlay.

---

## Further notes

### N5 — CI workflows

Six findings in the three workflows. Every one was checked against the file, and the ones about GitHub's behaviour against GitHub's documentation or a real request.

**N5a. The run link in each update PR is dead** (`.github/workflows/update.yml:158`). `workflow_run_url` ends in `/actions/run/<id>`, but GitHub's address is `/actions/runs/<id>`. I requested both forms for a real run of your repository on 2026-09-29: `runs` answered 200 and `run` answered 404. nixvim's workflow, which yours resembles, uses `runs`. **[verified]**

```diff
-          workflow_run_url: ${{ github.server_url }}/${{ github.repository }}/actions/run/${{ github.run_id }}
+          workflow_run_url: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
```

**N5b. "Apply commits from open PR" can never apply a commit** (`update.yml:113-118`, with `:161`). The comment says the base is "the most recent commit on the remote branch authored by nixvim-ci", but the code takes the remote branch's *tip*. `"$base..$remote"` is then empty and the step always prints "Nothing to re-apply". nixvim's original filters with `git rev-list --author="$author_regex" …`; the filter is missing here. The consequence: any commit you push to the update PR branch, such as a fix for an update that broke the build, is discarded when the next scheduled run force-pushes (`update.yml:161`). I reproduced the empty result on a scratch repository. **[verified]**

The fix needs care. The bot's name contains `[bot]`, which `--author` would read as a regular-expression bracket expression, and then it matches nothing. I tested three variants on a scratch repository (a bot commit followed by two human commits): no filter re-applied 0 commits, `--author="name[bot]"` found no base, and `--fixed-strings --author="name[bot]"` found the bot's commit and returned both human commits. I then ran the whole patched step, extracted from the patched workflow, against a scratch repository with last week's PR branch (a bot lock bump plus two human fix commits touching real files) and this week's fresh lock bump. It re-applied both fixes; the original logic printed "Nothing to re-apply" and lost them. The sandbox's git (2.39) predates `cherry-pick --empty`, so I deleted that one flag for the test. **[verified]**

**proposed** (the top of the step; the rest of it is unchanged)

```diff
       - name: Apply commits from open PR
         id: re_apply
         if: steps.open_pr_info.outputs.number
+        env:
+          bot_name: ${{ steps.token.outputs.app-slug }}[bot]
         run: |
-          # The base is the most recent commit on the remote branch authored by nixvim-ci
-          # This should be a flake.lock bump or a generated-files update
+          # The base is the most recent commit on the remote branch authored by the bot
+          # This should be a flake.lock bump
           # We will cherry-pick all commits on the remote _after_ the $base commit
           remote="origin/$pr_branch"
-          base=$(git rev-list --max-count=1 "$remote")
+          base=$(git rev-list --fixed-strings --author="$bot_name" --max-count=1 "$remote")
+          [[ -n "$base" ]] || base="$remote" # the bot has not pushed yet: nothing to re-apply
           commits=( $(git rev-list --reverse "$base..$remote") )
```

The added `[[ -n "$base" ]]` line matters. Without it, an empty `$base` makes `"$base..$remote"` read `..origin/…`, which is not "nothing". The diff also replaces the stale `nixvim-ci` comment.

**N5c. A one-letter typo** (`update.yml:59`). `steps.token.output.token` should be `outputs`. GitHub evaluates a non-existent property to an empty string ([Contexts reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts)). `cachix/install-nix-action` then falls back to the default `GITHUB_TOKEN` (its `install-nix.sh` at `v31`: "Use the default GitHub token if available"). So nothing fails, but the app token you meant to use is never used. **[verified]**

```diff
-          github_access_token: ${{ steps.token.output.token }}
+          github_access_token: ${{ steps.token.outputs.token }}
```

**N5d. An unpinned action** (`verify_configurations.yml:66`). `DeterminateSystems/nix-installer-action@main` follows a moving branch, while every other job pins `cachix/install-nix-action@v31`. The latest release is `v23` (2026-09-09). Pin it. Note also that the "build" job installs Nix with a different installer from the other two jobs, which may mean a different Nix version. **[verified]**

```diff
-        uses: DeterminateSystems/nix-installer-action@main
+        uses: DeterminateSystems/nix-installer-action@v23
```

**N5e. No `permissions:` block in `verify_configurations.yml`.** The other two workflows start from `permissions: {}` and grant per job. This one gets whatever the repository's default token permission is, and I could not read that setting (the API answered 403 for my token). Adding the block below is consistent with the others. The magic-nix-cache README asks only for `contents: read` and, for FlakeHub Cache (which you do not use; you pass `use-gha-cache`), `id-token: write`, so this should not disturb the cache steps. If one complains, that is where to look. **[verified README; effect not tested]**

```yaml
permissions:
  contents: read
```

**N5f. The formatting check runs an unlocked alejandra** (`formatting.yml:27`). `nix run nixpkgs#alejandra` resolves `nixpkgs` through the flake *registry*, so CI checks formatting with whatever alejandra is current, not the one in your `flake.lock`. Once Step 2 gives the flake a `formatter`, CI can run the pinned one; the `nix fmt` manual says arguments after `--` go to the formatter, and alejandra's `--check` is its `-c`:

```diff
-          nix run nixpkgs#alejandra -- -c .
+          nix fmt -- --check .
```

**Small items.** `update.yml:169` says "begining" in the PR body. The stale `nixvim-ci` comment at `update.yml:113`, copied from the workflow this one is based on, is fixed in the N5b diff.

### N6 — nix-colors is archived upstream

**Evidence. [verified]** `misterio77/nix-colors` is an archived GitHub repository. Its last commit is `b01f024` from 2024-02-13 ("Add textMateThemeFromScheme to lib-contrib (#39)"), which is the revision in your lock, 959 days old. You use it in six places: `daniel/default.nix:3` imports its home-manager module, `daniel/default.nix:12` selects `gruvbox-material-dark-medium`, and `config.colorScheme.palette` is read in `daniel/programs/dunst.nix`, `daniel/programs/wayland/{hyprland,waybar,wofi}.nix` and `daniel/shell/terminal.nix`.

**What it means.** Nothing breaks today, and there is nothing to do now. The risk is that nobody will fix a break caused by a future nixpkgs or home-manager change. The guide puts the input's only wiring (the import and `colorScheme`) in one feature file (`aspects/desktop/colours.nix`, Step 8); the five palette readers stay with their own features.

**Options.** Keep it. Or, since a scheme is a small attribute set of sixteen colours, inline yours and drop the input. Or move to a maintained alternative such as Stylix, which I have not evaluated.

### N7 — The disko input is never used

**Evidence. [verified]** `flake.nix:18-21` declares `disko`. `git grep -i disko` finds nothing else, on `master` or on `dendritic`. Nothing imports `disko.nixosModules` and no host has a disko layout.

**Fix.** Delete the four lines, and `flake.lock` drops one node. Keep it only if you plan to install a machine with disko soon.

### N8 — secrets.yaml is tracked but gitignored

**Evidence. [verified]** `.gitignore:3` lists `secrets.yaml`, and `git check-ignore -v --no-index secrets.yaml` confirms the rule matches. The file is nevertheless tracked (`git ls-tree HEAD secrets.yaml` shows a blob). It has to be: flakes see only tracked files, and `cooked/nixos/sops.nix:17` reads `../../secrets.yaml`.

**Why it matters.** An ignore rule does nothing to a tracked file, so today it is only misleading. It will bite the day you recreate the file: `git add secrets.yaml` refuses ("The following paths are ignored by one of your .gitignore files"), and the flake then fails with "path … does not exist" (Report 2, Appendix C).

**The file itself looks right.** I checked its structure without printing any value: every value, array item and comment is `ENC[…]`-wrapped, and the only plain text is the `sops:` metadata block. `.sops.yaml` has one creation rule with one age key, and the file has one recipient. The four `example_*` keys from sops' sample template are still in it. With a single recipient, if that age key is lost the secrets are unrecoverable; a second recipient is a cheap backup.

**Fix.** Delete `.gitignore:3`, or keep the rule and always use `git add -f`. Deleting is simpler.

### N9 — The sudo rules are passwordless root

**your repo @ dendritic** — `nixos/configuration.nix:33-55`

```nix nosyntax
  security.sudo.extraRules = [
    {
      groups = ["wheel"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["SETENV" "NOPASSWD"];
        }
        {
          command = "/run/wrappers/bin/mount";
          options = ["SETENV" "NOPASSWD"];
        }
        {
          command = "/run/wrappers/bin/umount";
          options = ["SETENV" "NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/loadkeys";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    }
  ];
```

**What it amounts to.** This is not a bug, and it is a common convenience on a single-user machine. I flag it because the list *reads* as narrower than it is. **[verified from the manuals; not tested on your system]**

- `nixos-rebuild` can build and activate any configuration, so passwordless `nixos-rebuild` is passwordless root for any process running as `daniel`.
- `mount` can mount arbitrary filesystems with arbitrary options, which is another route to root.
- `SETENV` lets the caller put environment variables into root's environment for these commands, including ones sudo would strip by default, such as `LD_PRELOAD`. The sudoers manual: "environment variables set on the command line are not subject to the restrictions imposed by env_check, env_delete, or env_keep. As such, only trusted users should be allowed to set variables in this manner" ([sudoers manual](https://www.sudo.ws/docs/man/1.8.31/sudoers.man/)). Even the harmless-looking `loadkeys` rule therefore becomes a route to root.
- `nix.settings.trusted-users = ["root" "@wheel"]` (`modules/aspects/nix.nix:7`) is in the same category. The Nix manual: "Adding a user to trusted-users is essentially equivalent to giving that user root access to the system" ([nix.conf](https://man.archlinux.org/man/nix.conf.5.en)).

Nothing in the repository visibly calls these rules. `modules/pkgs/update-system/update-system.sh` runs `nh os boot`, not `sudo nixos-rebuild`, and the `mount`, `umount` and `loadkeys` rules have no caller here, so they may be for interactive use.

**Options.** (1) Keep them and know what they are. (2) Tighten: drop `SETENV`, and drop the rules you do not use. Removable media can be mounted by your logged-in session without sudo (for example through udisks2). (3) Type the password for `nixos-rebuild`.

**When.** Decide at Step 5, when the rules move into `aspects/security.nix`. The guide moves them unchanged.

### N10 — The adbusers group no longer exists

**Evidence. [verified]** `nixos/configuration.nix:26` puts `daniel` in `adbusers`. At your pinned nixpkgs `programs.adb` has been removed (`nixos/modules/rename.nix`: "This option is no longer needed as systemd 258 handles uaccess rules automatically. Please add `pkgs.android-tools` to your system packages to get the adb command."), and no module in `nixos/modules` defines an `adbusers` group. `users-groups.nix` computes each group's members from the groups that exist, and I found no warning or assertion for an unknown name in `extraGroups`, so the entry is silently ignored.

**Fix.** Delete the line. If you use `adb`, the repository does not install it anywhere (`git grep` finds no `android-tools`), so add `pkgs.android-tools` to the user's packages.

**When.** Step 7, in `modules/users/daniel.nix`. The guide carries the entry over unchanged.

### N11 — Garbage collection went from weekly to daily

**your repo @ master** — `cooked/nixos/nix.nix:24-28`

```nix nosyntax
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
```

**your repo @ dendritic** — `modules/aspects/nix.nix:14-18`

```nix nosyntax
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 14d";
      };
```

**What it means. [verified]** Every other `nix.*` setting in the two files is identical, so the change may not have been intended. With `--delete-older-than 14d`, a generation is deleted once it is older than 14 days (the one that was active at the cutoff is kept). A weekly run deletes it at 14 to 21 days old and a daily run at 14 to 15, so your rollback window shrinks by up to a week, and unreferenced store paths are collected daily (see N3). Step 0 already lists this as an expected difference.

**Fix.** If it was not deliberate, set `dates = "weekly";`. If it was, nothing to do.

### N12 — Small leftovers

Each of these is trivial and independent.

- **`hosts/wsl/default.nix:34-36`**: `environment.systemPackages = builtins.attrValues { inherit (pkgs); };`. `inherit (pkgs);` inherits no names, so the result is `[]`. Delete the three lines.
- **`modules/aspects/nix.nix:5` and `:10-13`**: `auto-optimise-store = true` *and* `nix.optimise.automatic` (13:00 and 20:00) both deduplicate the store by hard-linking. One is enough.
- **`secrets.yaml`**: the sops sample keys, see N8.
- **`update.yml`**: the typo and the stale comment, see N5.
- **Public repository, personal data.** `daniel/email/accounts.nix` contains the addresses of three mail accounts and the names of the `pass` entries that hold their passwords, in a public repository. That is your call to make, and the passwords themselves are not there. The first address is already public in your commit metadata; the other two may not be anywhere else.

---

## Checked, and fine

These were looked for and not found, so you can stop worrying about them.

- **Every `follows` in `flake.nix` names a real input. [verified from `flake.lock`]** All thirteen overrides target an input that the dependency has, so Nix will not print "has an override for a non-existent input".
- **No accidental extra nixpkgs. [verified]** The lock holds two nixpkgs entries, the root and `nixpkgs-stable`, and nothing else pulls in its own copy. (Reverting N1 would add Hyprland's, deliberately.)
- **No renamed or removed options in your configuration**, as far as a static scan can tell (method below). Your home-manager settings are already on the current names: `programs.git.settings`, `programs.zsh.initContent`, `programs.zsh.autosuggestion.enable`, and an explicit `home.pointerCursor.enable`. **No package name the repository uses is one of nixpkgs' removed or warning aliases** (the `throw` and `warnAlias` entries in `pkgs/top-level/aliases.nix` at your pin).
- **GitHub Actions versions are current. [verified]** Latest releases on 2026-09-29: `actions/checkout` v7.0.1 (you use `@v7`), `actions/create-github-app-token` v3.2.0 (`@v3`), `wimpysworld/nothing-but-nix` v10 (`@v10`), `cachix/install-nix-action` v31.11.1 (`@v31`) and `DeterminateSystems/magic-nix-cache-action` v15 (`@v15`). The exception is `nix-installer-action` (N5d).
- **No plaintext secrets** turned up in a keyword search of the tracked files. Only `passwordCommand = "pass …"` lines, and the sops-encrypted values.
- **Nothing impure.** No `builtins.getEnv`, `<nixpkgs>`-style lookup, `fetchTarball`, `fetchGit`, `builtins.fetchurl` or `--impure`. The only absolute paths are `/home/daniel/.config/sops/age/keys.txt` (`cooked/nixos/sops.nix:19`, the age key) and `homeDirectory = "/home/daniel"` (`users/daniel/default.nix:44`, which is also home-manager's default).
- **`system.stateVersion` and `home.stateVersion` are `23.05`.** That is the release each installation started from, and the `# Do not change` comment is right. Leave them.

## Where Report 2 covers the migration findings

The seven rows of the audit table in Report 2 ("Where you are now") are migration problems, and the guide fixes each in a step.

| Audit row | Finding | Fixed in |
|---|---|---|
| 1 | `modules/aspects/nix.nix` sets `nixpkgs.hostPlatform` inside `moduleWithSystem`, which is circular | [Step 1](02-migration-guide.md#step-1--decide-your-vocabulary-storage-roles-opt-ins) |
| 2 | The flake no longer defines `nixosConfigurations`, `overlays`, `lib`, `templates` or `formatter` | Steps [2](02-migration-guide.md#step-2--make-the-entry-point-boring-turn-the-plumbing-into-modules), [3](02-migration-guide.md#step-3--packages-overlays-and-nixpkgs-settings) and [4](02-migration-guide.md#step-4--hosts-first-get-nixosconfigurations-back-by-wrapping-legacy-code) |
| 3 | Four legacy files import `modules/XF86.nix` or `modules/hyprpaper.nix`, which moved to `modules.old/` | [Step 4](02-migration-guide.md#step-4--hosts-first-get-nixosconfigurations-back-by-wrapping-legacy-code) |
| 4 | `cooked/nixos/scripts.nix:19` uses `pkgs.power-menu`, now `powermenu` | [Step 3](02-migration-guide.md#step-3--packages-overlays-and-nixpkgs-settings) |
| 5 | No `flake-parts.flakeModules.modules` import | [Step 2](02-migration-guide.md#step-2--make-the-entry-point-boring-turn-the-plumbing-into-modules) |
| 6 | `systems = ["x86_64-linux"]; # TODO: Remove` cannot be removed while `perSystem` is used | [Step 2](02-migration-guide.md#step-2--make-the-entry-point-boring-turn-the-plumbing-into-modules) |
| 7 | Dead legacy files that import-tree would bring to life | [Step 8](02-migration-guide.md#step-8--peel-the-personal-home-manager-tree-daniel-into-features) |

## Method and limits

- **Nothing was evaluated or built.** The environment I worked in cannot reach nixos.org or the binary caches, so I could not install Nix. Everything is read from sources, or fetched from GitHub and the documentation sites. This is the same caveat as in Report 2, Appendix D.
- **Pinned revisions.** Facts about nixpkgs and home-manager come from the revisions in your `flake.lock`, fetched by commit (nixpkgs `6774f7bc253789b113a4f39285dc0fa100abeacc`, home-manager `0b2f1129177f70c5f0f5d88bb53c49ca47d0bfc0`). Report 2's Appendix D says it read current `master` of each project; for this note I did better.
- **How the option and package scan worked.** I parsed all 69 tracked `.nix` files (outside `docs/`, `templates/` and `flake.nix`) with tree-sitter-nix and extracted 1,648 attribute paths. I compared them with the rename and removal tables of both projects, built by pattern-matching `mkRenamedOptionModule`, `mkRemovedOptionModule`, `mkChangedOptionModule` and `mkAliasOptionModule` (1,568 entries for nixpkgs, 130 for home-manager), with `aliases.nix`, and with a text search for option names inside deprecation-style messages. Every raw hit was a false positive on inspection: your own `cooked.sound.enable` matching the removed `sound.enable`, home-manager's own `services.mpd.*` matching a nixpkgs rename, the XF86 key names `light` and `hibernate`, and ordinary words such as `follow`, `done` and `src`.
- **What the scan cannot see.** Renames declared through loops or variables are not in the tables. It checks what you *define*, not what you read. And warnings that a module raises for other reasons (for example a default that depends on `stateVersion`) are invisible to it. The reliable check is to build and read the warnings: `nixos-rebuild build --flake .#dellG5 2>&1 | grep -i warn`.
- **Live facts** (end-of-life dates, action releases, the archived status of `nix-colors`, the 200 and 404 answers) were read on 2026-09-29 and can change.
- **The `[inferred]` claims** are N3's "probably not in effect" and the effect of N5e. Each comes with the command or test that settles it.
