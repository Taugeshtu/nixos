# Fleet Synchronization Architecture

- [[Domain_NixOS]]
- [[fleet]]
- [[Codex]]
- [[Tower]]
- [[Slate]]
- [[mutagen]]
- [[rclone]]

Unified architecture for fleet storage and synchronization across Codex (laptop), Tower (workstation), and Slate (tablet).

---

## 1. Node Roles & Topology

| Node | Network IP | Role | Sync Mechanism |
|---|---|---|---|
| **Tower** | `100.64.0.3` | **Master Anchor**: Canonical authority for all projects, backups, and archives. Always-on compute. | Primary target (`Tower:`) |
| **Codex** | `100.64.0.1` | **Mobile Driver**: Battery and CPU conscious. Hot active projects local; cold storage lazy. | Mutagen YAMLs + Rclone VFS |
| **Slate** | `100.64.0.4` | **Field Tablet**: Constrained local storage. Consumes data on-demand. | Rclone VFS (`K`, `P`, `_archive`) |

Transport is end-to-end encrypted via Headscale WireGuard mesh (`mesh_vpn.md`) with SSH key authentication.

---

## 2. Two-Tier Storage Model

To prevent laptop battery drain, excessive SSD wear, and multi-gigabyte idle scanning, storage is strictly partitioned into two tiers:

```
~/10_PROJECTS/
├── _archive/           <-- [Tier 2: Cold] Rclone VFS mount (Tower:~/10_PROJECTS/_archive)
│   ├── old_project_1/  <-- Browseable stub, zero local bytes until opened
│   └── old_project_2/
├── ActiveProjectA/     <-- [Tier 1: Hot] Local folder + Mutagen YAML sync to Tower
└── ActiveProjectB/     <-- [Tier 1: Hot] Local folder + Mutagen YAML sync to Tower
```

### Tier 1: Hot & Bidirectional (Mutagen Projects)
- **Declarative YAMLs**: Managed exclusively through project definitions in `~/.config/mutagen/projects/*.yml`. Ad-hoc CLI sessions are prohibited so that sessions remain visible to `mutagui`.
- **Core Domains**: `~/.config/mutagen/projects/tower.yml` maintains permanent bidirectional sync for `~/00_INGRESS` and `~/05_WORK`.
- **Active Projects**: Individual project YAMLs (`prj-<name>.yml`) manage 3–8 active working trees in `~/10_PROJECTS/<name>`.
- **Global Ingest Rules**: `~/.mutagen.yml` enforces universal ignore patterns across all projects (`node_modules`, `target`, `build`, `.venv`, `__pycache__`, `*.log`, `tmp`).

### Tier 2: Cold & Zero-Footprint (Rclone VFS)
- **Source of Truth**: Tower holds the complete archive at `/home/tau/10_PROJECTS/_archive/`.
- **Mount Unit**: Systemd user service `rclone-mount-archive.service` mounts the remote archive to `~/10_PROJECTS/_archive` with `--vfs-cache-mode full`.
- **Environment Wrappers**: Unit includes `/run/wrappers/bin` and `fuse3` in `PATH` to satisfy setuid `fusermount3` security requirements, plus `--allow-other` for Flatpak compatibility.
- **Characteristics**: Zero local disk usage when idle; files are fetched and cached transparently on first read.

---

## 3. Project Lifecycle (`prj`)

Project state transitions are orchestrated via the `prj` helper script (declared in `modules/desktop/future.nix` and exposed via Thunar custom actions in `uca_full.xml`).

```
                prj activate <name>
[Tower _archive] ------------------> [Tower 10_PROJECTS]
       |                                    ^
       | (Rclone VFS stub)                  | (Mutagen sync)
       v                                    v
[Codex _archive]                     [Codex 10_PROJECTS]
       ^                                    |
       |        prj deactivate <name>       |
       +------------------------------------+
```

### Activation (`prj activate [name]`)
1. **Context Resolution**: Automatically detects project name from current working directory if omitted.
2. **Pre-flight**: Verifies Tower SSH reachability (3s timeout).
3. **Tower Placement**:
   - If project is in `_archive/`, executes remote move `mv 10_PROJECTS/_archive/<name> 10_PROJECTS/<name>`.
   - If already active in `10_PROJECTS/`, preserves existing state without error.
   - If project exists locally on Codex but is absent on Tower, creates remote directory `mkdir -p 10_PROJECTS/<name>` on Tower.
4. **Local Setup**: Ensures local directory `/home/tau/10_PROJECTS/<name>` exists.
5. **Declarative Config**: Generates `/home/tau/.config/mutagen/projects/prj-<clean_name>.yml` (sanitizing dots and underscores to hyphens).
6. **Session Launch**: Executes `mutagen project start` and initial flush. Project immediately registers in `mutagui`.

### Deactivation (`prj deactivate [name]`)
1. **Context Resolution**: Automatically detects project name from current working directory if omitted.
2. **Sync Flush & Teardown**: Flushes pending changes to Tower, terminates the Mutagen project session, and removes the local project YAML. (Falls back to `rsync` if unmanaged).
3. **Remote Demotion**: Executes `mv 10_PROJECTS/<name> 10_PROJECTS/_archive/<name>` directly on Tower via SSH. Zero Wi-Fi transit bandwidth required.
4. **Local Reclamation**: Deletes local working copy `/home/tau/10_PROJECTS/<name>`. Project instantly reappears as a cold browseable stub inside `~/10_PROJECTS/_archive/<name>`.

---

## 4. Boundaries & Exclusions

- **Version Control (`.git/`)**: Git repositories retain independent remotes (e.g., GitHub). For repos synced via Mutagen, avoid concurrent branch hopping or conflicting local commits across nodes to prevent index/lockfile churn.
- **Service Dirs**: Scratch and cache directories (e.g., `EasyEDA_*`) are explicitly excluded from fleet sync and remain node-local.
- **Mutagui Interface**: Always inspect and manage sessions through `mutagui`. The UI automatically detects all YAML project files in `~/.config/mutagen/projects/`.
