#!/bin/bash

set -e

allUtilities="zsh,ansible,azurecli,docker,kubectl,kustomize,krew,helm,clusterctl,kind,kompose,packer,terraform,vault"
commaSeparatedUtils=""

# A function to display a help message
show_help() {
    echo "Usage: ./installer.sh --utils <replace-with-comma-separated-tools>\n"
    echo "Available tools: $allUtilities\n"
    echo "Shortcut to install all available tools: \n"
    echo "./installer.sh --all"
}

# Parse the command line arguments
for arg in $@
do

    if [ -z "$1" ]; then
        break
    fi

    case $1 in
        -a|--all)
            commaSeparatedUtils=$allUtilities
            ;;
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



function addHashicorpAptRepo() {
    HASHICORP_REPO="https://apt.releases.hashicorp.com"
    HASHICORP_REPO_FILE="/etc/apt/sources.list.d/hashicorp.list"
    HASHICORP_KEYRING="/usr/share/keyrings/hashicorp-archive-keyring.gpg"

    if ! grep -q "$HASHICORP_REPO" $HASHICORP_REPO_FILE; then
        echo "Adding Hashicorp Apt Repo..."

        wget -O- $HASHICORP_REPO/gpg | gpg --dearmor | sudo tee $HASHICORP_KEYRING

        gpg --no-default-keyring --keyring $HASHICORP_KEYRING --fingerprint

        echo "deb [signed-by=$HASHICORP_KEYRING] $HASHICORP_REPO $(lsb_release -cs) main" | sudo tee $HASHICORP_REPO_FILE

        sudo apt update -y
    else
        echo "HashiCorp APT repository is already added."
    fi

}

function installAnsible() {
    ANSIBLE_REPO_GPG_KEY_URL="https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367"
    ANSIBLE_REPO_FILE="/etc/apt/sources.list.d/ansible.list"
    ANSIBLE_REPO="http://ppa.launchpad.net/ansible/ansible/ubuntu"
    ANSIBLE_KEYRING="/usr/share/keyrings/ansible-archive-keyring.gpg"

    if ! grep -q "$ANSIBLE_REPO" $ANSIBLE_REPO_FILE; then
        echo "Adding Ansiblie Apt Repo..."

        wget -O- $ANSIBLE_REPO_GPG_KEY_URL | sudo gpg --dearmour -o $ANSIBLE_KEYRING
        echo "deb [signed-by=$ANSIBLE_KEYRING] $ANSIBLE_REPO $(lsb_release -cs) main" | sudo tee $ANSIBLE_REPO_FILE
        sudo apt update -y > /dev/null
    else
        echo "Ansiblie APT repository is already added."
    fi
    
    sudo apt install -y ansible > /dev/null

}

function installAzureCli() {
    if ! command -v az &> /dev/null; then
        echo "Azure CLI is not installed. Installing now..."
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    else
        echo "Azure CLI is already installed."
    fi
}

function installDocker() {
    if [ ! -f /etc/apt/keyrings/docker.gpg ];
    then
        
        echo "Adding docker gpg key to keyring..."

        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

    else

        echo "Already added docker gpg key to keyring."

    fi

    if [ ! -f /etc/apt/sources.list.d/docker.list ];
    then

        echo "Adding docker apt repo source..."

        echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    else

        echo "Already added docker repo source."

    fi

    sudo apt-get update -y > /dev/null

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null

    grepDockerGroup=$( cat /etc/group | grep "docker" )

    if [[ $grepDockerGroup != docker* ]];
    then

        echo "Adding docker group..."

        sudo groupadd docker

    else

        echo "Already added docker group."

    fi

    grepUserInDockerGroup=$( groups $USER | grep "docker" )

    if [[ $grepUserInDockerGroup != *docker* ]];
    then

        echo "Adding $USER to docker group..."

        sudo usermod -aG docker $USER

    else

        echo "Already added $USER to docker group."

    fi

    grepAlternativesIptables=$( sudo update-alternatives --get-selections | grep iptables )

    if [[ $grepAlternativesIptables == iptables*auto*/usr/sbin/iptables-nft ]];
    then

        echo "Updating iptables alternative to iptables-legacy..."
        
        sudo update-alternatives --set iptables /usr/sbin/iptables-legacy

    else

        echo "Already set iptables alternative to iptables-legacy."

    fi

    userSudoerFile="/etc/sudoers.d/$USER-nopasswd-dockerd"

    if [ ! -f $userSudoerFile ];
    then

        echo "Creating sudoer config file for $USER..."

        sudo touch $userSudoerFile

    else

        echo "Already created sudoer config file for $USER."

    fi

    sudoNoPasswordForDockerDaemon="$USER ALL=(ALL) NOPASSWD: /usr/bin/dockerd"

    if ! grep --quiet "$sudoNoPasswordForDockerDaemon" "$userSudoerFile";
    then

        echo "Adding config to $USER sudoer config file to allow running sudo without password for docker daemon..."

        echo "$sudoNoPasswordForDockerDaemon" | sudo tee --append $userSudoerFile > /dev/null

    else

        echo "Already updated $USER sudoer config file to allow running sudo without password for docker daemon."

    fi

    if ! grep --quiet "# Start Docker daemon automatically" $HOME/.zshrc;
    then

        echo "Updating .zshrc file to start Docker daemon automatically..."

        echo '# Start Docker daemon automatically when logging in if not running.' >> $HOME/.zshrc
        echo 'RUNNING=`ps aux | grep dockerd | grep -v grep`' >> $HOME/.zshrc
        echo 'if [ -z "$RUNNING" ]; then' >> $HOME/.zshrc
        echo '    sudo dockerd > /dev/null 2>&1 &' >> $HOME/.zshrc
        echo '    disown' >> $HOME/.zshrc
        echo 'fi' >> $HOME/.zshrc

    else

        echo "Already updated .zshrc file to start Docker daemon autoamtically."

    fi
}

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

function installPacker() {
    addHashicorpAptRepo

    sudo apt install -y packer

    if ! grep --quiet "complete -o nospace -C /usr/bin/packer packer" $HOME/.zshrc;
    then

        echo "Adding autocompletion for packer..."
        
        packer -autocomplete-install

    else

        echo "Already added autocompletion for packer."

    fi

}

function installTerraform() {
    addHashicorpAptRepo

    sudo apt install -y terraform

    if ! grep --quiet "complete -o nospace -C /usr/bin/terraform terraform" $HOME/.zshrc;
    then

        echo "Adding autocompletion for terraform..."
        
        terraform -install-autocomplete

    else

        echo "Already added autocompletion for terraform."

    fi

}

function installVault() {
    addHashicorpAptRepo

    sudo apt install -y vault

    if ! grep --quiet "complete -o nospace -C /usr/bin/vault vault" $HOME/.zshrc;
    then

        echo "Adding autocompletion for vault..."
        
        vault -autocomplete-install

    else

        echo "Already added autocompletion for vault."

    fi

}

function installZsh() {
    ZSH_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
    ZSH_THEMES="$HOME/.oh-my-zsh/custom/themes"

    mkdir -p ./backups

    sudo apt install -y zsh git fonts-font-awesome > /dev/null

    if [ ! -d ~/.oh-my-zsh ];
    then

        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended

        cp $HOME/.zshrc ./backups/.zshrc.bak

    fi

    if [ ! -d $ZSH_PLUGINS/zsh-autosuggestions ];
    then

        echo "Cloning zsh-users/zsh-autosuggestions..."

        git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_PLUGINS/zsh-autosuggestions > /dev/null

    fi

    if [ ! -d $ZSH_PLUGINS/zsh-completions ];
    then

        echo "Cloning zsh-users/zsh-completions..."

        git clone https://github.com/zsh-users/zsh-completions $ZSH_PLUGINS/zsh-completions

    fi

    if [ ! -d $ZSH_PLUGINS/zsh-syntax-highlighting ];
    then

        echo "Cloning zsh-users/zsh-syntax-highlighting..."

        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_PLUGINS/zsh-syntax-highlighting

    fi

    if ! grep --quiet "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" $HOME/.zshrc;
    then

        echo "Adding zsh plugins..."

        findPlugins="plugins=(git)"
        replacePlugins="plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"
        replaceFpath="fpath+=$ZSH_PLUGINS/zsh-completions/src"
        replaceExport="export ZSH=\"\$HOME/.oh-my-zsh\""
        
        sed --in-place "s,$replaceExport,,g" $HOME/.zshrc

        sed --in-place "s,$findPlugins,$replacePlugins\n$replaceFpath\n$replaceExport,g" $HOME/.zshrc

    else

        echo "Already added zsh plugins."

    fi

    if [ ! -d $ZSH_THEMES/powerlevel10k ];
    then

        echo "Cloning romkatv/powerlevel10k..."

        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_THEMES/powerlevel10k

    fi

    if ! grep --quiet "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" $HOME/.zshrc;
    then

        echo "Changing ZSH_THEME to powerlevel10k..."

        findTheme="ZSH_THEME=\"robbyrussell\""
        replaceTheme="ZSH_THEME=\"powerlevel10k/powerlevel10k\""
        
        sed --in-place "s,$findTheme,$replaceTheme,g" $HOME/.zshrc

    else

        echo "ZSH_THEME is already powerlevel10k."

    fi

    if ! grep --quiet "$USER.*$( which zsh )" /etc/passwd;
    then

        echo "Updating default shell for $USER to zsh..."
        
        chsh --shell $(which zsh)

    else

        echo "Already updated default shell to zsh for $USER."

    fi
}

sudo apt install -y ca-certificates curl gnupg software-properties-common > /dev/null
sudo apt update -y > /dev/null
sudo apt upgrade -y > /dev/null


IFS=',' 

read -ra utilsList <<< "$commaSeparatedUtils"

for util in "${utilsList[@]}"; do

    echo "Installing $util..."
    case $util in
        ansible)
            installAnsible
            ;;
        azurecli)
            installAzureCli
            ;;
        docker)
            installDocker
            ;;
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
        packer)
            installPacker
            ;;
        terraform)
            installTerraform
            ;;
        vault)
            installVault
            ;;
        zsh)
            installZsh
            ;;
        *)    # unknown option
            echo "Unknown utility: $1. Skipping it..."
            ;;
    esac

    
    echo "\n\nDone with $util.\n\!"

done

# Finally, we reset our separator back to its default value
unset IFS
