# POST -- Status Dashboard

POST is the status dashboard component of [buildbuild](https://github.com/NerdGGuy/buildbuild). It is a GitHub Pages site that displays build status, historical trends, and embeddable SVG badges for all 8 build variants (release, debug, asan, ubsan, tsan, msan, coverage, fuzz).

The dashboard is updated automatically by the `update.sh` script, which fetches build manifests from the PUSH cache repository and generates the data files and badges that the dashboard consumes.

## GitHub Pages Setup

1. Create a GitHub repository to host the status dashboard (e.g., `POST`).
2. Push the contents of this directory to the repository's `main` branch.
3. In the repository settings, navigate to **Pages**.
4. Set the source to the **main** branch with the **root** (`/`) directory.
5. Save. The dashboard will be available at:

```
https://<owner>.github.io/<repo>/
```

For example:

```
https://NerdGGuy.github.io/POST/
```

## Dashboard Features

| Feature | Description |
|---------|-------------|
| Current status | Shows pass/fail for all 8 variants with version, commit, and timestamps |
| Historical trends | Visual chart of the last 50 builds, color-coded per variant |
| Build history table | Tabular view of the last 20 builds with relative timestamps |
| Log links | Direct links to build logs in PUSH, accessed via the store path hash |
| SVG badges | Embeddable status badges for each variant, suitable for READMEs |
| Dark mode | Automatically activates based on system preference |
| Auto-refresh | Dashboard reloads current status data every 5 minutes |

## Badge Embedding

Embed badges in your project README using the following Markdown syntax:

```markdown
![release](https://NerdGGuy.github.io/POST/badges/release.svg)
![debug](https://NerdGGuy.github.io/POST/badges/debug.svg)
![asan](https://NerdGGuy.github.io/POST/badges/asan.svg)
![ubsan](https://NerdGGuy.github.io/POST/badges/ubsan.svg)
![tsan](https://NerdGGuy.github.io/POST/badges/tsan.svg)
![msan](https://NerdGGuy.github.io/POST/badges/msan.svg)
![coverage](https://NerdGGuy.github.io/POST/badges/coverage.svg)
![fuzz](https://NerdGGuy.github.io/POST/badges/fuzz.svg)
```

Replace `NerdGGuy` and `POST` with your GitHub Pages owner and repository name.

## update.sh Script

The `update.sh` script collects build status from the PUSH cache repository and updates the dashboard data files and badges.

### Usage

```bash
# Update using defaults from PULL/cache/config.json
./update.sh

# Specify cache repository explicitly
./update.sh --cache-owner NerdGGuy --cache-repo PUSH

# Write output to a different directory
./update.sh --output /path/to/output

# Preview what would be generated without writing any files
./update.sh --dry-run
```

### Options

| Option | Description |
|--------|-------------|
| `--cache-owner OWNER` | Owner of the cache repository (read from `PULL/cache/config.json` if available) |
| `--cache-repo REPO` | Name of the cache repository (read from `PULL/cache/config.json` if available) |
| `--output DIR` | Output directory for generated files (default: script directory) |
| `--dry-run` | Show what would be generated without writing any files |
| `-h`, `--help` | Show usage help |

### What It Does

1. Fetches variant manifests from the cache repository at `manifests/<variant>.json`.
2. Updates `data/current.json` with the latest status for all 8 variants.
3. Appends a new entry to `data/history.json`, maintaining the last 100 build records.
4. Generates an SVG badge for each variant in `badges/<variant>.svg`.
5. Writes per-variant detail files to `data/variants/<variant>.json`.

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `GITHUB_TOKEN` | Token for authenticated API access to the cache repository |

## Data Format Reference

### data/current.json

Contains the latest build status for all variants.

```json
{
  "updated": "2024-01-15T10:30:00Z",
  "variants": {
    "release": {
      "status": "pass",
      "version": "1.2.3",
      "store_path": "/nix/store/abc123...-PROJ-release-1.2.3",
      "log_hash": "abc123...",
      "timestamp": "2024-01-15T10:25:00Z",
      "rev": "abc123def456..."
    },
    "debug": {
      "status": "pass",
      "version": "1.2.3",
      "store_path": "/nix/store/def456...-PROJ-debug-1.2.3",
      "log_hash": "def456...",
      "timestamp": "2024-01-15T10:26:00Z",
      "rev": "abc123def456..."
    },
    "asan": {
      "status": "fail",
      "version": "1.2.3",
      "store_path": "/nix/store/ghi789...-PROJ-asan-1.2.3",
      "log_hash": "ghi789...",
      "timestamp": "2024-01-15T10:27:00Z",
      "rev": "abc123def456..."
    }
  }
}
```

Each variant entry includes:

- `status` -- `"pass"`, `"fail"`, or `"unknown"`
- `version` -- the project version string
- `store_path` -- the Nix store path of the build output
- `log_hash` -- the path hash used to locate the build log in PUSH
- `timestamp` -- ISO 8601 timestamp of the build
- `rev` -- the Git commit SHA that was built

### data/history.json

Array of build records, capped at the last 100 entries.

```json
{
  "builds": [
    {
      "timestamp": "2024-01-15T10:30:00Z",
      "variants": {
        "release": { "status": "pass", "log_hash": "abc123..." },
        "debug": { "status": "pass", "log_hash": "def456..." },
        "asan": { "status": "fail", "log_hash": "ghi789..." },
        "ubsan": { "status": "pass", "log_hash": "jkl012..." },
        "tsan": { "status": "pass", "log_hash": "mno345..." },
        "msan": { "status": "pass", "log_hash": "pqr678..." },
        "coverage": { "status": "pass", "log_hash": "stu901..." },
        "fuzz": { "status": "pass", "log_hash": "vwx234..." }
      }
    }
  ]
}
```

### data/variants/\<name\>.json

Per-variant detail files with the same structure as entries in `current.json`:

```json
{
  "status": "pass",
  "version": "1.2.3",
  "store_path": "/nix/store/abc123...-PROJ-release-1.2.3",
  "log_hash": "abc123...",
  "timestamp": "2024-01-15T10:25:00Z",
  "rev": "abc123def456..."
}
```

## Badge Format

SVG badges display the variant name on the left and the status on the right. Colors indicate the build result:

| Status | Color | Hex |
|--------|-------|-----|
| pass | Green | `#4c1` |
| fail | Red | `#e05d44` |
| unknown | Gray | `#9f9f9f` |

Badges are rendered using the DejaVu Sans font family and sized dynamically based on the variant name and status text length.

## Investigating Failures

1. Open the dashboard at `https://<owner>.github.io/<repo>/`.
2. In the **Current Status** section, find the variant with a red status indicator.
3. Click **View Log** on the failing variant card to open the raw build log.
4. The log is served directly from the PUSH cache repository at:

```
https://raw.githubusercontent.com/<owner>/<cache-repo>/main/logs/<hash>.log
```

The history chart and table provide additional context, showing whether the failure is new or recurring across recent builds.

## Directory Structure

```
POST/
├── index.html               # Dashboard page
├── style.css                # Responsive styling with dark mode
├── app.js                   # Client-side data loading and rendering
├── update.sh                # Status collection and badge generation script
├── data/
│   ├── current.json         # Latest status for all variants
│   ├── history.json         # Historical build records (last 100 builds)
│   └── variants/
│       └── <variant>.json   # Per-variant detailed status
├── badges/
│   └── <variant>.svg        # Embeddable SVG status badges
└── README.md
```

## Dependencies

- **curl** -- for fetching manifests from the cache repository
- **jq** -- for JSON processing in `update.sh`
- **GitHub Pages** -- for hosting the dashboard as a static site

## License

MIT
