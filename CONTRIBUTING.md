# Contributing to kaia-docker

Thank you for your interest in contributing to kaia-docker! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/kaia-docker.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit and push to your fork
7. Open a Pull Request

## Development Setup

### Prerequisites
- Docker and Docker Compose
- Bash shell
- shellcheck (for linting)
- pre-commit (optional but recommended)

### Initial Setup
```bash
# Copy environment template
cp default.env .env

# Install pre-commit hooks (optional)
pre-commit install

# Test the CLI
./kaiad help
```

## Code Style Guidelines

### Shell Scripts
- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -Eeuo pipefail`
- Use double quotes for variables
- Follow existing naming conventions:
  - Functions: `lowercase_with_underscores`
  - Private functions: `__double_underscore_prefix`
  - Environment variables: `SCREAMING_SNAKE_CASE`
- Add comments for complex logic
- Keep lines under 120 characters where reasonable

### YAML Files
- Use 2-space indentation
- Follow existing structure in `kaia.yml`
- Validate syntax before committing

### Documentation
- Update README.md for user-facing changes
- Update CLAUDE.md for technical/architectural changes
- Keep documentation concise and accurate
- Include examples where appropriate

## Testing

### Manual Testing
Before submitting a PR, test these scenarios:

```bash
# 1. Fresh installation
./kaiad up

# 2. Check logs
./kaiad logs

# 3. Version check
./kaiad version

# 4. Stop and restart
./kaiad down
./kaiad up

# 5. Sync status
./kaiad check-sync

# 6. Update process
./kaiad update
```

### Linting
Run shellcheck on shell scripts:
```bash
shellcheck ethd
shellcheck scripts/check_sync.sh
shellcheck kaia/docker-entrypoint.sh
```

Or use pre-commit:
```bash
pre-commit run --all-files
```

## Pull Request Process

1. **Update documentation**: Ensure README.md, CLAUDE.md reflect your changes
2. **Test thoroughly**: Verify your changes work in a clean environment
3. **Lint your code**: Run shellcheck and fix any issues
4. **Write clear commits**: Use descriptive commit messages
5. **Update ENV_VERSION**: If you modify `default.env` variables, increment `ENV_VERSION`
6. **Update CHANGELOG**: Document your changes (if applicable)

### Commit Message Format
```
type: short description

Longer description if needed, explaining what and why.

Fixes #issue-number
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
```
feat: add support for Kairos testnet
fix: correct RPC port in check_sync.sh
docs: update hardware requirements in README
```

## What to Contribute

### High Priority
- Bug fixes
- Documentation improvements
- Performance optimizations
- Security enhancements

### Welcome Contributions
- New features (discuss in an issue first)
- Test coverage improvements
- CI/CD enhancements
- Example configurations

### Please Avoid
- Unnecessary refactoring without clear benefits
- Breaking changes without discussion
- Changing code style for aesthetics only
- Adding dependencies without justification

## Kaia-Specific Guidelines

### Ken Configuration
- Ken uses command-line flags (in `docker-entrypoint.sh`)
- Do not hardcode values; use environment variables from `default.env`
- Test configuration changes against real Kaia mainnet

### Snapshot URLs
- Use official Kaia Foundation snapshots from `packages.kaia.io`
- Document snapshot size and update frequency
- Test snapshot download and extraction process

### Port Configuration
- Default ports: RPC=8551, WS=8552, P2P=32323, Metrics=61001
- Do not change default ports without strong reason
- Ensure ports are configurable via environment variables

## Security

### Reporting Vulnerabilities
- **Do not** open public issues for security vulnerabilities
- Email security concerns to the maintainers
- Allow reasonable time for fixes before public disclosure

### Security Best Practices
- Never commit secrets or private keys
- Use non-root user in Docker containers
- Validate all user inputs in scripts
- Keep dependencies up-to-date

## Community

### Getting Help
- Open an issue for bugs or feature requests
- Use discussions for questions and ideas
- Join the Kaia community channels

### Code of Conduct
- Be respectful and constructive
- Focus on what's best for the project
- Welcome newcomers and help them contribute

## License

By contributing to kaia-docker, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

## Questions?

If you have questions about contributing, please open an issue with the label `question` or reach out to the maintainers.

Thank you for contributing to kaia-docker! 🚀
