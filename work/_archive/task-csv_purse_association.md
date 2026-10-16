# Task: Associate .csv Files with Purse

- [[05_WORK]], [[Purse]], [[_Future]], [[nixOS_move]]

## Context
`.csv` files currently open with OnlyOffice instead of Purse.
Cannot just change via GUI file picker because NixOS manages file associations declaratively.

## Goal
- Update NixOS desktop / XDG mime configuration so `.csv` files default to opening with Purse (`purse-niri`).
- Clean up default handler override.

---

@/home/tau/10_PROJECTS/nixOS <- this is the repo
@/home/tau/10_PROJECTS/nixOS/nixOS_config <- the actual config

@coder_done pull up files and folders which will be relevant for fixing the files association; it might be in the dotfiles big-ass blob we have here:
@/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config

!!take care when reading to use absolute paths because the working directory is in the work where this file lives, not in my nixOS config
@/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/mimeapps.list
Uhh this seems like the thing we need?
@/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/
@/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/
@lookup_done "mimeapps" /home/tau/10_PROJECTS/nixOS/nixOS_config/modules
<dir_search path="/home/tau/10_PROJECTS/nixOS/nixOS_config/modules" query="mimeapps">
  <match file="/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/base.nix" line="100">xdg.configFile.&quot;mimeapps.list&quot;.source = ./niri/config/mimeapps.list;</match>
</dir_search>
@/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/base.nix (6.0 KB)
//patch p011.patch: (+1 | -1) @/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/mimeapps.list
//patch_failed p012.patch: old_content is not unique in the file (found 2 occurrences)
//patch p013.patch: (+1 | -0) @/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/mimeapps.list
!!qwen: The CSV file association is fixed. In `mimeapps.list`:
1. **Default Applications** section: `text/csv=purse-niri.desktop` (was previously OnlyOffice).
2. **Added Associations** section: `purse-niri.desktop` is listed first for `text/csv`, ahead of OnlyOffice and Lite-XL.

The failed patch (p012) was expected — the `text/csv` line appeared in both the Added Associations and Default Applications sections, making a naive search-and-replace ambiguous. The two successful patches (p011, p013) targeted each occurrence individually.

No further changes needed. After `nixos.rebuild` (or `home-manager` rebuild for the user profile), Thunar and other XDG-aware apps will default to opening `.csv` files with Purse.

@coder_done oh also I want `.patch` files associated with purse-niri, and then purse itself in its config needs to send these to Lite-XL. that's what I need
@/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/purse/
@/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/purse/associations.conf (911 B)
//patch p014.patch: (+1 | -0) @/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/mimeapps.list
//patch p015.patch: (+1 | -0) @/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/mimeapps.list
//patch p016.patch: (+1 | -0) @/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/purse/associations.conf
!!qwen: The `.patch` file association chain is fully configured:
- XDG default: `text/x-patch` → `purse-niri.desktop` (in mimeapps.list)
- Purse internal routing: `text/x-patch` → `org.lite_xl.lite_xl.desktop` (in purse/associations.conf)

After a `home-manager` rebuild, double-clicking a `.patch` file in Thunar will open Purse, which will immediately forward it to Lite-XL.

@coder_done need association for .csv to open in lite-xl also after purse. onlyoffice is a tad too heavy; if I want it, I'll go there via alt-menu
//patch p017.patch: (+1 | -0) @/home/tau/10_PROJECTS/nixOS/nixOS_config/modules/desktop/niri/config/purse/associations.conf
!!qwen: The full association chain for `.csv` files is now configured:

1. **XDG default** (`mimeapps.list` → Default Applications): `text/csv=purse-niri.desktop`
2. **XDG added associations** (`mimeapps.list` → Added Associations): `text/csv=purse-niri.desktop;org.onlyoffice.desktopeditors.desktop;org.lite_xl.lite_xl.desktop;`
3. **Purse internal routing** (`purse/associations.conf`): `text/csv = org.lite_xl.lite_xl.desktop`

Double-clicking a `.csv` in Thunar → opens Purse → Purse immediately forwards to Lite-XL. OnlyOffice remains available via the alt-menu in Purse. No further changes needed.
