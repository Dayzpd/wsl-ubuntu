#!/bin/bash

set -e

commaSeparatedUtils=""

# A function to display a help message
show_help() {
    echo "Usage: ./script.sh --arg1 [arg1] --arg2 [arg2]"
}

# Parse the command line arguments
for arg in $@
do

    if [ -z "$1" ]; then
        break
    fi

    case $1 in
        -u|--utils|--utilities)
            commaSeparatedUtils="$2"
            shift
            ;;
        -h|--help)
            show_help
            exit
            ;;
        *)    # unknown option
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

function installKubectl() {
    # Check if the Kubernetes package repository is already added
    if ! grep -q "https://pkgs.k8s.io/core:/stable:/v1.29/deb/" /etc/apt/sources.list.d/kubernetes.list; then
        # If not, download the public signing key and add the repository
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    fi

    # Update the apt package index and install kubectl
    sudo apt update -y > /dev/null

    sudo apt install -y kubectl

    if ! grep --quiet "alias k=\"kubectl\"" $HOME/.zshrc;
    then

        echo "Adding alias k for kubectl command in .zshrc file..."

        echo 'alias k="kubectl"' >> $HOME/.zshrc

    else

        echo "Already added k alias for kubectl command to .zshrc file."

    fi

    if [ -f $ZSH/completions/_kubectl ]; then
        echo "Completions file for 'kubectl' already exists."
    else
        echo "Creating completions file for 'kubectl'."
        kubectl completion zsh > $ZSH/completions/_kubectl
    fi

}

function installKustomize() {
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

    sudo mv ./kustomize /usr/local/bin/kustomize

    if [ -f $ZSH/completions/_kustomize ]; then
        echo "Completions file for 'kustomize' already exists."
    else
        echo "Creating completions file for 'kustomize'."
        kustomize completion zsh > $ZSH/completions/_kustomize
    fi

}

# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
function installKrew() {

    if ! grep --quiet "export PATH=\"\$HOME/.krew/bin:\$PATH\"" $HOME/.zshrc;
    then

        echo "Adding kubectl plugin manager Krew..."

        originalDir=$( pwd )
        
        cd "$(mktemp -d)"
        OS_NAME="$(uname | tr '[:upper:]' '[:lower:]')"
        ARCH_NAME="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
        KREW_VERSION="krew-${OS_NAME}_${ARCH_NAME}"
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW_VERSION}.tar.gz"
        tar zxvf "${KREW_VERSION}.tar.gz"
        ./"${KREW_VERSION}" install krew

        echo 'export PATH="$HOME/.krew/bin:$PATH"' >> $HOME/.zshrc

        cd $originalDir

    else

        echo "Already added kubectl plugin manager Krew."

    fi

}

function installHelm() {
    # Check if the Helm package repository is already added
    if ! grep -q "https://baltocdn.com/helm/stable/debian" /etc/apt/sources.list.d/helm-stable-debian.list; then
        # If not, download the public signing key and add the repository
        curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor -o /etc/apt/keyrings/helm-apt-keyring.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/helm-apt-keyring.gpg] https://baltocdn.com/helm/stable/debian/ all main' | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    fi

    # Update the apt package index and install Helm
    sudo apt update -y > /dev/null

    sudo apt-get install -y helm

    if [ -f $ZSH/completions/_helm ]; then
        echo "Completions file for 'helm' already exists."
    else
        echo "Creating completions file for 'helm'."
        helm completion zsh > $ZSH/completions/_helm
    fi

}


function installClusterCtl() {
    curl -L https://github.com/kubernetes-sigs/cluster-api/releases/latest/download/clusterctl-linux-amd64 -o clusterctl
    sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
    rm ./clusterctl

    if [ -f $ZSH/completions/_clusterctl ]; then
        echo "Completions file for 'clusterctl' already exists."
    else
        echo "Creating completions file for 'clusterctl'."
        clusterctl completion zsh > $ZSH/completions/_clusterctl
    fi

}

function installKind() {
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind

    if [ -f $ZSH/completions/_kind ]; then
        echo "Completions file for 'kind' already exists."
    else
        echo "Creating completions file for 'kind'."
        kind completion zsh > $ZSH/completions/_kind
    fi

}

function installKompose() {
    curl -L https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-amd64 -o kompose

    chmod +x kompose

    sudo mv ./kompose /usr/local/bin/kompose
    

    if ! grep --quiet "alias k=\"kubectl\"" $HOME/.zshrc;
    then

        echo "Adding alias k for kubectl command in .zshrc file..."

        echo 'alias k="kubectl"' >> $HOME/.zshrc

    else

        echo "Already added k alias for kubectl command to .zshrc file."

    fi
}

IFS=',' 

read -ra utilsList <<< "$commaSeparatedUtils"

for util in "${utilsList[@]}"; do

    echo "Installing $util..."
    case $util in
        kubectl)
            installKubectl
            ;;
        kustomize)
            installKustomize
            ;;
        krew)
            installKrew
            ;;
        helm)
            installHelm
            ;;
        clusterctl)
            installClusterCtl
            ;;
        kind)
            installKind
            ;;
        kompose)
            installKompose
            ;;
        *)    # unknown option
            echo "Unknown utility: $1. Skipping it..."
            ;;
    esac
done

# Finally, we reset our separator back to its default value
unset IFS
