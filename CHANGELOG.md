# Changelog

All notable changes to OnionFermenter will be documented in this file.

## [Unreleased]

### Added
- **Multi-Currency Support**: Added support for Monero (XMR) cryptocurrency in addition to Bitcoin (BTC)
  - New `CURRENCY_TYPE` environment variable to select BTC, XMR, or MONERO
  - Regex patterns for both Bitcoin and Monero address detection
  - Separate address files (BTC-ADDRESSES.txt and XMR-ADDRESSES.txt)
  
- **24/7 Operation Enhancements**:
  - Docker containers now use `--restart unless-stopped` policy for automatic recovery
  - Added systemd service file (`deploy/onionfermenter.service`) for bare-metal deployments
  - Enhanced signal handling in run.sh for graceful shutdowns
  - Kubernetes deployments already include liveness/readiness probes for automatic restart
  
- **Telegram Notifications**:
  - New `onionfermenter_telegram.erl` module for Telegram bot integration
  - Real-time notifications when cryptocurrency addresses are replaced
  - Startup notifications with currency type information
  - Configurable via `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` environment variables
  - Automatic detection and graceful degradation when Telegram is not configured
  
- **Configuration Examples**:
  - Example configuration files for both BTC and XMR in `examples/` directory
  - Example address files with proper format documentation
  - Comprehensive setup guide in `examples/README.md`
  - Step-by-step Telegram bot setup instructions

### Changed
- Updated `rebar.config` to include `inets` and `ssl` applications for HTTP requests
- Enhanced `Makefile` with new environment variables for currency type and Telegram
- Updated Kubernetes deployment templates with new environment variables
- Expanded main README.md with comprehensive documentation for all new features
- Refactored address replacement logic to support multiple cryptocurrency types
- Updated all examples to demonstrate new features

### Technical Details
- Modified `onionfermenter_worker_server.erl`:
  - Added currency type detection and configuration
  - Implemented `get_address_pattern/1` for dynamic regex patterns
  - Renamed `replaceBtcAddresses/5` to `replaceCryptoAddresses/5` for broader scope
  - Integrated Telegram notifications in address replacement flow
  - Updated state record to include `addresses` and `currencytype` fields

- New Telegram module features:
  - HTTP POST requests to Telegram Bot API
  - JSON payload formatting with proper escaping
  - Error handling for network failures
  - Asynchronous notification sending to avoid blocking

### Compatibility
- Fully backward compatible: defaults to BTC if `CURRENCY_TYPE` is not set
- Optional Telegram notifications: system works normally without Telegram configuration
- All existing deployment methods (Docker, Kubernetes) continue to work unchanged

## Previous Versions
See git history for changes in previous versions.
