
##### #Removes any previous docker instances that may be running.
sudo apt-get remove docker docker-engine docker.io containerd runc

##### Installs reequired packages for Docker 
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

##### Installs GPG key to download Docker for Ubuntu 20.04
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

##### Downloads Docker from Repository

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
###### Installs Docker 
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
##### Sets keysight user (assuming you used keysight as the user when you build the Ubuntu server, if not, use your preferred username
##### Sets Docker to allow it to be run without the need for "sudo". Must logout and back in for change to take effect.

sudo usermod -aG docker keysight
##### Enabled docker daemon, reloads and restarts Docker
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker


echo "WARNING - You are being logged out now to udpate and allow the docker to be run without sudo."

echo "You will be logged out in 5 seconds"
sleep 5
logout