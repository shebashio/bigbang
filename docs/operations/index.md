# Operations

This section covers day-to-day operation of a Big Bang deployment that's already running — monitoring, backup and recovery, upgrades, and troubleshooting. It does not cover initial deployment; see [Getting Started](../getting-started/index.md) for that.

## What You'll Find Here
 
Operating a running deployment breaks down into three areas:
 
- **Day-to-day operations** — cluster health, through monitoring.
- **Lifecycle management** — data protection through backup and restore, and moving through Big Bang's two-week release cadence via planned upgrades.
- **Issue resolution** — troubleshooting guides organized by symptom, not by component, so you start from what you're observing

## Find the Right Starting Point

| Your goal | Start here |
| --- | --- |
| Set up observability and alerting | [Monitoring](monitoring.md) — configure monitoring before an incident occurs |
| Protect your data | [Backup and Restore](backup-restore.md) — configure backups and verify that data can be restored |
| Upgrade Big Bang or a package | [Upgrades](upgrades.md) — review upgrade notices, package changes, and supported upgrade paths before upgrading |
| Automate dependency updates | [Maintenance](maintenance/index.md), including [Renovate](maintenance/renovate.md) |
| Diagnose a deployment, package, networking, or upgrade problem | [Troubleshooting](troubleshooting/index.md) — identify the first failing layer and follow the troubleshooting workflow |
| Diagnose performance or resource issues | [Performance troubleshooting](troubleshooting/performance.md) |