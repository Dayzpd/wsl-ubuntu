## wsl-ubuntu

This repository contains a script named `installer.sh` that helps you install commonly used developer tools on Ubuntu.

### Tool Installation

1. Clone this repository to your WSL Ubuntu directory.
2. Open a terminal and navigate to the directory where you cloned the repository.
3. Run the following command, replacing `<tools>` with a comma-separated list of tools you want to install, or `all` to install all available tools:

```bash
./installer.sh --utils <tools>
```

**Example:**

```bash
./installer.sh --utils ansible,docker,kubectl
```

### Available Tools

The script supports installing the following tools:

* ansible
* azurecli
* docker
* kubectl
* kustomize
* krew
* helm
* clusterctl
* kind
* kompose
* packer
* terraform
* vault
* zsh

### Usage

```
Usage: ./installer.sh --utils <replace-with-comma-separated-tools>

Available tools: $allUtilities

Shortcut to install all available tools:

./installer.sh --all

Options:
  -h, --help    Show this help message and exit
  -u, --utils,  --utilities  Comma-separated list of tools to install
  -a, --all     Install all available tools
```

### Script Functionality

The script performs the following actions:

1. Parses command-line arguments to determine which tools to install.
2. Updates the APT package list.
3. Installs any required dependencies for the chosen tools.
4. Downloads and installs each selected tool using the appropriate method (e.g., APT, curl).
5. Configures necessary environment variables and settings for some tools (e.g., adding kubectl to PATH, setting default shell to zsh).

### Additional Notes

* The script requires root privileges to install some packages.
* Make sure you have an active internet connection before running the script.
* The script automatically installs zsh and sets it as the default shell.