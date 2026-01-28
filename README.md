# POST - Status Dashboard

GitHub Pages dashboard displaying build status, historical trends, and SVG badges for all variants.

## Usage

### View Dashboard

```
https://NerdGGuy.github.io/POST/
```

### Embed Badges

```markdown
![release](https://NerdGGuy.github.io/POST/badges/release.svg)
![debug](https://NerdGGuy.github.io/POST/badges/debug.svg)
![asan](https://NerdGGuy.github.io/POST/badges/asan.svg)
![ubsan](https://NerdGGuy.github.io/POST/badges/ubsan.svg)
![tsan](https://NerdGGuy.github.io/POST/badges/tsan.svg)
![coverage](https://NerdGGuy.github.io/POST/badges/coverage.svg)
```

### Update Dashboard

```bash
# Update from cache repository
./update.sh

# With explicit configuration
./update.sh --cache-owner NerdGGuy --cache-repo PUSH

# Dry run
./update.sh --dry-run
```

## Structure

```
POST/
├── index.html               # Dashboard page
├── style.css                # Responsive styling with dark mode
├── app.js                   # Client-side data loading and rendering
├── update.sh                # Status collection script
├── data/
│   ├── current.json         # Latest status (includes log refs)
│   ├── history.json         # Historical records (last 100 builds)
│   └── variants/
│       └── <variant>.json   # Per-variant detailed status
├── badges/
│   └── <variant>.svg        # Embeddable status badges
└── README.md
```

## Features

| Feature | Description |
|---------|-------------|
| Current status | Shows pass/fail for all 8 variants |
| Historical trends | Visual chart of last 50 builds |
| Build history table | Last 20 builds with timestamps |
| Log links | Direct links to build logs via store path hash |
| SVG badges | Embeddable badges for READMEs |
| Dark mode | Automatic based on system preference |
| Auto-refresh | Updates every 5 minutes |

## update.sh Script

Collects status from cache repository and updates dashboard:

```bash
./update.sh [OPTIONS]
```

**Options:**
| Option | Description |
|--------|-------------|
| `--cache-owner OWNER` | Cache repository owner |
| `--cache-repo REPO` | Cache repository name |
| `--output DIR` | Output directory (default: current) |
| `--dry-run` | Show what would be generated |

**What it does:**
1. Fetches manifests from cache repository
2. Updates `data/current.json` with latest status
3. Appends to `data/history.json` (maintains last 100 entries)
4. Generates `badges/*.svg` for each variant

## Data Format

### current.json

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
    "debug": { ... },
    "asan": { ... }
  }
}
```

### history.json

```json
{
  "builds": [
    {
      "timestamp": "2024-01-15T10:30:00Z",
      "variants": {
        "release": { "status": "pass", "log_hash": "abc123..." },
        "debug": { "status": "pass", "log_hash": "def456..." },
        "asan": { "status": "fail", "log_hash": "ghi789..." }
      }
    }
  ]
}
```

### variants/<name>.json

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

SVG badges show variant name and status:

- **pass**: Green (#4c1)
- **fail**: Red (#e05d44)
- **unknown**: Gray (#9f9f9f)

## Investigating Failures

1. Open dashboard at `https://NerdGGuy.github.io/POST/`
2. Find failing variant (red indicator)
3. Click "View Log" to see build output
4. Log URL format: `https://raw.githubusercontent.com/NerdGGuy/PUSH/main/logs/<hash>.log`

## GitHub Pages Setup

1. Enable GitHub Pages in repository settings
2. Set source to main branch, root directory
3. Dashboard will be available at `https://<owner>.github.io/<repo>/`

## Dependencies

- curl (for fetching manifests)
- jq (for JSON processing)
- GitHub Pages (for hosting)

## License

MIT
