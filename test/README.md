# Oracle Instant Client Tests

This directory contains test scripts and configurations for validating the Oracle Instant Client and SQLPlus installation in the dev container environment.

## Test Files

### `test-sqlplus.sh`

A comprehensive test script that validates:

- ✅ Oracle Instant Client installation
- ✅ SQLPlus command availability and functionality
- ✅ Environment configuration
- ✅ Library dependencies
- ✅ Optional database connectivity

## Running Tests

### In Dev Container

1. **Open the project in VS Code with Dev Container extension**
2. **Reopen in Container** when prompted
3. **Run the test script:**

```bash
# Make the script executable
chmod +x test/test-sqlplus.sh

# Run all tests
./test/test-sqlplus.sh
```

### With Database Connection Testing

To test actual database connectivity, set the connection string:

```bash
# Set connection string environment variable
export ORACLE_TEST_CONNECTION='system/testpass@//localhost:1521/xe'

# Run tests including database connectivity
./test/test-sqlplus.sh
```

### In GitHub Actions

The tests run automatically on:

- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual workflow dispatch

## Test Categories

### 1. Basic Installation Tests

- SQLPlus command availability
- Version check functionality
- Library path configuration
- Installation directory verification
- Shared library existence

### 2. SQLPlus Functionality Tests

- Help command functionality
- Version output format validation
- Connection syntax validation

### 3. Environment Tests

- Environment variables verification
- Library dependencies check

### 4. Database Connection Tests (Optional)

- Live database connection
- Simple query execution
- Connection parameter validation

## Expected Output

### Successful Test Run

```text
================================================
Oracle Instant Client & SQLPlus Test Suite
================================================

1. Basic Installation Tests
----------------------------
Running: SQLPlus command available
✓ SQLPlus command available
Running: SQLPlus version check
✓ SQLPlus version check
...

================================================
Test Results Summary
================================================
✅ All 10 tests passed!

Oracle Instant Client and SQLPlus are properly installed and configured.
Environment Details:
  - SQLPlus Version: SQL*Plus: Release 19.0.0.0.0 - Production
  - Oracle Library Path: /opt/oracle/instantclient_19_25
  - Oracle Installation: /opt/oracle/instantclient_19_25
```

### Failed Test Run

```text
❌ 2 out of 10 tests failed

Please check the installation and configuration.
```

## Troubleshooting

### Common Issues

1. **Permission Denied**

   ```bash
   chmod +x test/test-sqlplus.sh
   ```

2. **Oracle Libraries Not Found**
   - Check if the dev container built successfully
   - Verify `.devcontainer/devcontainer.json` configuration
   - Rebuild the container: `Dev Containers: Rebuild Container`

3. **Database Connection Failures**
   - Ensure database service is running
   - Verify connection parameters
   - Check network connectivity
   - Confirm credentials

### Environment Variables

The tests check for these environment variables:

- `PATH` - Should include Oracle Instant Client binaries
- `LD_LIBRARY_PATH` - Should include Oracle Instant Client libraries
- `ORACLE_TEST_CONNECTION` - Optional: Database connection string for connectivity tests

### Dev Container Requirements

The tests assume the following dev container features are installed:

- `ora_instantclient` - Oracle Instant Client base libraries
- `ora_sqlplus` - SQLPlus command-line tool

## CI/CD Integration

### GitHub Actions Workflow

The `.github/workflows/test.yml` file provides:

- **Automated Testing**: Runs on push and pull requests
- **Manual Triggering**: Can be run manually via workflow dispatch
- **Oracle Database Service**: Includes a test Oracle database
- **Dev Container Validation**: Tests the actual dev container environment
- **Comprehensive Reporting**: Detailed test results and summaries

### Workflow Features

- Uses official Dev Container CLI
- Tests actual container build process
- Validates all dev container features
- Includes database connectivity testing
- Provides detailed test summaries

## Contributing

When contributing to this project:

1. Run tests locally before submitting PRs
2. Ensure all tests pass in the CI environment
3. Add new tests for any new features
4. Update documentation for test changes

## Support

For issues with:

- **Oracle Instant Client**: Check Oracle documentation
- **Dev Containers**: Refer to VS Code Dev Container documentation
- **SQLPlus**: Consult Oracle SQLPlus documentation
- **This Project**: Open an issue in the repository
