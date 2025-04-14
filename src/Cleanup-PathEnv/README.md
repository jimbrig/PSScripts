# Cleanup-PathEnv

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/)](https://www.powershellgallery.com/packages/Cleanup-PathEnv/)

> [!NOTE]
> *Cleans up the system and user `PATH` environment variables.*

## Description

The [`Cleanup-PathEnv.ps1`](./Cleanup-PathEnv.ps1) script is designed to clean up the system and user `PATH` environment
variables in Windows.

It identifies and removes invalid, duplicate, and unnecessary paths, ensuring that the `PATH` variable remains organized and
efficient.

The script provides options for logging, backup, and reporting, making it a comprehensive tool for managing the `PATH`
environment variable.

## Features

- **Path Cleanup**: Removes invalid, duplicate, and unnecessary paths from the `PATH` environment variable.
- **Logging**: Supports logging of actions taken during the cleanup process.
- **Backup**: Creates backups of the `PATH` variable before making changes.
- **Reporting**: Generates detailed reports of the cleanup process, including before and after comparisons.
- **User-Friendly**: Provides a user-friendly interface with options for customization.
- **Error Handling**: Implements robust error handling to ensure smooth execution.
- **Progress Indicators**: Displays progress indicators during long-running operations.
- **HTML Reporting**: Generates HTML reports for easy viewing and sharing.
- **Dry Run Mode**: Allows users to preview changes before applying them.
- **Backup and Restore**: Provides options for backing up and restoring the `PATH` variable.
- **Version Tracking**: Tracks the version of the script for easy reference.
- **Detailed Documentation**: Includes comprehensive comment-based help and examples for all parameters.

## Tags

```plantext
PowerShell, Script, Environment, PATH, Cleanup, System, User
```

## Release Notes

The latest released version is: [Version 2.0.0](https://www.powershellgallery.com/packages/Cleanup-PathEnv/2.0.0).

### Version 2.0.0

The script was enhanced with several significant improvements:

- **Comprehensive Documentation**:
  - Added detailed comment-based help with examples and parameter descriptions
  - Added script version tracking (2.0.0)
  - Improved inline comments for better code understanding

- **Robust Logging System**:
  - Implemented multi-level logging (Silent, Error, Warning, Info, Verbose, Debug)
  - Added colorized console output for different message types
  - Fixed directory creation issues so logging works immediately
  - Added error handling to gracefully continue even if logging fails

- **Enhanced Path Processing**:
  - Expanded path categorization with more detailed categories and patterns
  - Added path normalization to standardize paths and use environment variables
  - Improved duplicate detection with smarter comparison logic
  - Better handling of PowerShell and Windows environment variables

- **Improved User Experience**:
  - Added progress bars for operations that check multiple paths
  - Implemented detailed statistical summaries showing before/after changes
  - Added dry-run mode to preview changes without applying them
  - Added backup and restore capabilities including "latest" backup option

- **HTML Reporting**:
  - Added detailed HTML report generation with visual indicators
  - Clear visualization of valid vs. invalid paths
  - Categorized view of paths by type
  - Before/after comparison showing what was added, removed, or kept

- **Better Error Handling**:
  - Added try/catch blocks throughout code to handle exceptions gracefully
  - Improved parameter validation and handling of edge cases
  - Added fallbacks for failed operations to ensure the script can continue

*The script now offers a much more professional experience with better visual feedback, more features, and improved reliability. The error related to log directory creation has been fixed, so the script now works properly even on the first run.*

### Version 1.0.0

- Initial Release
