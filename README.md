# Oracle Instant Client Dev Container

A VS Code Dev Container environment for Oracle Database development with Oracle Instant Client pre-installed.

## Overview

This project provides a ready-to-use development environment for working with Oracle databases. It includes Oracle Instant Client and SQL*Plus, making it easy to connect to and work with Oracle databases without the hassle of manual installation and configuration.

## Features

- **Oracle Instant Client**: Pre-installed Oracle Instant Client for database connectivity
- **SQL*Plus**: Command-line interface for Oracle Database
- **Multiple Versions**: Support for various Oracle Instant Client versions
- **Custom Dev Container Features**: Modular installation with custom features
- **Network Host Access**: Configured for direct network access to database servers

## Supported Oracle Instant Client Versions

- Latest (default)
- 21.12.0.0.0
- 19.25.0.0.0
- 19.21.0.0.0
- 19.12.0.0.0

## Quick Start

1. **Prerequisites**
   - VS Code with the Dev Containers extension
   - Docker Desktop

2. **Open in Dev Container**

   ```bash
   git clone https://github.com/s2005/ora_instantclient.git
   cd ora_instantclient
   ```

   - Open the folder in VS Code
   - When prompted, click "Reopen in Container" or use Command Palette: "Dev Containers: Reopen in Container"
   - The Dev Container will automatically download and install Oracle Instant Client during the build process

3. **Verify Installation**

   Once the container is built and running, you can verify the installation:

   ```bash
   sqlplus -v
   ```

## Configuration

### Dev Container Features

The environment uses two custom features:

#### ora_instantclient

- **Purpose**: Installs Oracle Instant Client base libraries
- **Default Version**: 19.25.0.0.0
- **Location**: `/opt/oracle/instantclient_*`

#### ora_sqlplus

- **Purpose**: Installs SQL*Plus command-line tool
- **Default Version**: 19.25.0.0.0
- **Depends on**: ora_instantclient feature

### Environment Variables

The installation automatically configures:

- `PATH`: Includes Oracle Instant Client binaries
- `LD_LIBRARY_PATH`: Includes Oracle Instant Client libraries

### Network Configuration

The container runs with `--network=host` to allow direct access to database servers on your network.

## Usage Examples

### Connecting to Oracle Database

```bash
# Connect using SQL*Plus
sqlplus username/password@//hostname:port/service_name

# Example
sqlplus hr/hr@//localhost:1521/xe
```

### Environment Variables for Connection

You can set environment variables for easier connections:

```bash
export ORACLE_HOST=your-db-server
export ORACLE_PORT=1521
export ORACLE_SERVICE=your-service-name
export ORACLE_USER=your-username

# Then connect with
sqlplus $ORACLE_USER@//$ORACLE_HOST:$ORACLE_PORT/$ORACLE_SERVICE
```

## Development

### Project Structure

```text
.
├── .devcontainer/
│   ├── devcontainer.json           # Dev container configuration
│   └── features/
│       ├── ora_instantclient/      # Oracle client feature
│       │   ├── devcontainer-feature.json
│       │   └── install.sh
│       └── ora_sqlplus/            # SQL*Plus feature
│           ├── devcontainer-feature.json
│           └── install.sh
├── .gitignore                      # Git ignore rules
└── README.md
```

### Customizing Versions

To use a different Oracle Instant Client version:

1. Edit `.devcontainer/devcontainer.json`
2. Change the version in the features section:

   ```json
   "features": {
       "./features/ora_instantclient": "21.10.0.0.0",
       "./features/ora_sqlplus": "21.10.0.0.0"
   }
   ```

3. Rebuild the container

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Ensure your Oracle database is accessible from your host machine
   - Check firewall settings
   - Verify connection parameters (host, port, service name)

2. **Version Compatibility**
   - Some applications may require specific Oracle client versions
   - Check your application's Oracle client compatibility requirements

3. **Library Path Issues**

   ```bash
   # Verify library path
   echo $LD_LIBRARY_PATH
   
   # Check installed libraries
   ls -la /opt/oracle/instantclient_*/
   ```

### Support

For Oracle Instant Client documentation and support:

- [Oracle Instant Client Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/lacli/)
- [Oracle Instant Client Downloads](https://www.oracle.com/database/technologies/instant-client.html)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in the dev container environment
5. Submit a pull request

## License

This project is provided as-is for development purposes. Oracle Instant Client is subject to Oracle's licensing terms.

---

*Note: This dev container automatically accepts Oracle's license terms during installation. Please ensure you comply with Oracle's licensing requirements for your use case.*
