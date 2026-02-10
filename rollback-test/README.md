# Rollback Test Snap

This snap is designed to investigate and demonstrate what causes rollbacks during snap refresh/update operations.

## What Causes Rollback?

| Failure Type | Hook/Component | Result |
|--------------|----------------|--------|
| `pre-refresh` hook fails | Before update | Refresh **ABORTED** (no rollback needed) |
| `post-refresh` hook fails | After update | Snap **ROLLED BACK** to previous revision |
| Service fails to start | After update | Depends on snapd version and configuration |
| Health check fails | After update | Snap **ROLLED BACK** (if health checks configured) |

## Building

```bash
cd rollback-test
snapcraft pack --use-lxd
```

## Installation

```bash
# Install first version
sudo snap install --dangerous rollback-test_1.0_amd64.snap

# Check services
snap services rollback-test
```

## Testing Rollback Scenarios

### Scenario 1: Pre-refresh Hook Failure (Refresh Aborted)

```bash
# Configure pre-refresh to fail
sudo snap set rollback-test pre-refresh-fail=true

# Bump version in snapcraft.yaml to 1.1, rebuild, then:
sudo snap install --dangerous rollback-test_1.1_amd64.snap

# Check - refresh should be ABORTED, stays on 1.0
snap info rollback-test
```

### Scenario 2: Post-refresh Hook Failure (Rollback)

```bash
# Reset and configure post-refresh to fail
sudo snap set rollback-test pre-refresh-fail=false
sudo snap set rollback-test post-refresh-fail=true

# Bump version, rebuild, then install
sudo snap install --dangerous rollback-test_1.2_amd64.snap

# Check - should ROLLBACK to previous revision
snap info rollback-test
snap changes
snap change <change-id>
```

### Scenario 3: Service Startup Failure

```bash
# Configure service to fail on startup
sudo snap set rollback-test service-fail=true

# Bump version, rebuild, then install
sudo snap install --dangerous rollback-test_1.3_amd64.snap

# Check service status
snap services rollback-test
systemctl status snap.rollback-test.service
```

## Viewing Logs

```bash
# Hook logs
sudo cat /var/snap/rollback-test/common/hooks.log

# Daemon logs
sudo cat /var/snap/rollback-test/common/daemon.log

# Service logs
sudo cat /var/snap/rollback-test/common/service.log

# Snapd logs
sudo journalctl -u snapd | grep rollback-test
```

## Monitoring Changes

```bash
# List all snap changes
snap changes

# View specific change details
snap change <id>

# Watch for changes in real-time
watch -n1 'snap changes | tail -10'
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `pre-refresh-fail` | false | Fail pre-refresh hook (aborts refresh) |
| `post-refresh-fail` | false | Fail post-refresh hook (triggers rollback) |
| `service-fail` | false | Fail service startup |
| `health-fail` | false | Fail health check |

## Snap Hooks Execution Order

During refresh:
1. `pre-refresh` (old snap) - Can abort refresh
2. Snap files updated
3. `post-refresh` (new snap) - Can trigger rollback
4. `configure` (new snap)
5. Services restarted

## Key Files

- `snap/hooks/pre-refresh` - Runs before refresh
- `snap/hooks/post-refresh` - Runs after refresh
- `snap/hooks/configure` - Runs on config changes
- `snap/hooks/install` - Runs on first install
- `bin/daemon.sh` - Oneshot daemon
- `bin/service.sh` - Simple daemon
- `bin/health-check.sh` - Health check script
