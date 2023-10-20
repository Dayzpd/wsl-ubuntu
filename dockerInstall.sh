#!/bin/bash

set -e

sudo apt-get update -y > /dev/null
sudo apt-get install -y ca-certificates curl gnupg > /dev/null

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