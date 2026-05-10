# TOOLS.md — Capability Inventory

Document everything your agent can do. This file is the single source of truth for capabilities.

⚠️ **Default assumption: "I probably CAN."** Check this file + try it before claiming you can't.

---

## Access Overview

| Capability | How | Status |
|---|---|---|
| **Shell** | Full terminal access | <!-- ✅ Active / ❌ Not available --> |
| **Browser** | <!-- Browser automation method --> | <!-- status --> |
| **Messaging** | <!-- iMessage, Slack, Discord, etc. --> | <!-- status --> |
| **Email** | <!-- CLI or API --> | <!-- status --> |
| **Calendar** | <!-- CLI or API --> | <!-- status --> |
| **Screen** | <!-- Screen capture/interaction --> | <!-- status --> |

---

## Installed CLIs

| Tool | Purpose | Notes |
|---|---|---|
| <!-- tool name --> | <!-- what it does --> | <!-- location, version, quirks --> |

<!-- Example entries:
| `gh` | GitHub CLI | Issues, PRs, CI |
| `docker` | Containers | Running on port 2375 |
| `kubectl` | Kubernetes | Context: production |
| `ffmpeg` | Media processing | v6.1 |
-->

---

## API Keys & Services

| Service | Status | Notes |
|---|---|---|
| <!-- service name --> | <!-- ✅/❌ --> | <!-- relevant details --> |

<!-- Example entries:
| OpenAI API | ✅ | GPT-4 access, key in .env |
| AWS | ✅ | S3 + Lambda, us-east-1 |
| Stripe | ❌ | Not configured yet |
-->

---

## Important Paths

| What | Path |
|---|---|
| Workspace | <!-- workspace root --> |
| Media | <!-- media storage path --> |
| Logs | <!-- log directory --> |
| Config | <!-- main config file --> |

---

## Infrastructure Notes

<!-- Document quirks, workarounds, and important operational details -->

<!-- Example:
- Config changes need service restart to take effect
- Port 8080 is used by the dev server, don't bind to it
- The auth token expires every 24 hours — refresh before long operations
-->

---

## Known Limitations

<!-- Be honest about what doesn't work -->

<!-- Example:
- Calendar integration via AppleScript has recurring syntax errors
- Email OAuth needs manual setup — not yet configured
- Screen capture only works when display is active
-->

---

_Update this file whenever you discover new capabilities or limitations._
