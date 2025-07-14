# Quick Reference

## Testing SQLPlus Installation

### Basic Commands

```bash
# Check version
sqlplus -v

# Run test suite
./test/test-sqlplus.sh

# Test with database connection
export ORACLE_TEST_CONNECTION='user/pass@//host:port/service'
./test/test-sqlplus.sh
```

### Makefile Commands

```bash
make build     # Build dev container
make test      # Run basic tests
make test-db   # Run tests with Oracle database
make shell     # Open container shell
make clean     # Clean up resources
```

### GitHub Actions

- **Main Workflow**: `.github/workflows/test.yml` - Runs on push/PR
- **Manual Test**: `.github/workflows/manual-test.yml` - Manual trigger with options

### Connection Examples

```bash
# Basic connection
sqlplus username/password@//hostname:port/service_name

# Using environment variables
export ORACLE_HOST=your-db-server
export ORACLE_PORT=1521
export ORACLE_SERVICE=your-service-name
export ORACLE_USER=your-username
sqlplus $ORACLE_USER@//$ORACLE_HOST:$ORACLE_PORT/$ORACLE_SERVICE

# Test connection (local Oracle XE)
sqlplus system/testpass@//localhost:1521/xe
```

### Troubleshooting

```bash
# Check environment
echo $LD_LIBRARY_PATH
echo $PATH

# Check Oracle installation
ls -la /opt/oracle/instantclient_*/

# Check libraries
find /opt/oracle -name '*.so*'

# Test library dependencies
ldd /opt/oracle/instantclient_*/libclntsh.so*
```

### Common Issues

1. **Permission denied**: `chmod +x test/test-sqlplus.sh`
2. **Libraries not found**: Rebuild container
3. **Connection failed**: Check database service and credentials
4. **Version mismatch**: Update `.devcontainer/devcontainer.json`
