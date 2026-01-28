# POST - Status Dashboard

GitHub Pages dashboard displaying build status, historical trends, and SVG badges for all variants.

## Usage

View the dashboard at:

```
https://ORG.github.io/STATUS-REPO/
```

Embed badges in your README:

```markdown
![release](https://ORG.github.io/STATUS-REPO/badges/release.svg)
![asan](https://ORG.github.io/STATUS-REPO/badges/asan.svg)
```

## Structure

```
/
├── index.html               # Dashboard page
├── style.css                # Styling
├── app.js                   # Client-side logic
├── data/
│   ├── current.json         # Latest status (includes log refs)
│   ├── history.json         # Historical records (last 100 builds)
│   └── variants/
│       └── <variant>.json   # Per-variant detailed status
└── badges/
    └── <variant>.svg        # Embeddable status badges
```

## Features

| Feature | Description |
|---------|-------------|
| Current status | Shows pass/fail for all variants |
| Historical trends | Last 100 builds with timestamps |
| Log links | Direct links to build logs via store path hash |
| SVG badges | Embeddable badges for READMEs |
| Variant details | Per-variant build history and metrics |

## Data Format

### current.json

```json
{
  "updated": "2024-01-15T10:30:00Z",
  "variants": {
    "release": {
      "status": "pass",
      "version": "1.2.3",
      "store_path": "/nix/store/abc123...-project-1.2.3",
      "log_hash": "abc123...",
      "timestamp": "2024-01-15T10:25:00Z"
    }
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
        "asan": { "status": "pass", "log_hash": "def456..." }
      }
    }
  ]
}
```

## Update Latency

Target: **< 5 minutes** from build completion to dashboard update.

## Investigating Failures

1. Open dashboard at `https://ORG.github.io/STATUS-REPO/`
2. Find failing variant, click "View Log"
3. Log URL: `https://raw.githubusercontent.com/ORG/CACHE-REPO/main/logs/<hash>.log`

## Dependencies

- GitHub Pages (automatic hosting)

## License

MIT
