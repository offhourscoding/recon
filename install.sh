#!/bin/bash

sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y

sudo apt update
sudo apt install -y fail2ban openvpn git build-essential python-setuptools golang nmap jq iftop python3-pip python-is-python3

sudo snap install chromium

sudo systemctl start fail2ban
sudo systemctl enable fail2ban

mkdir ~/tools
cd ~/tools
go get -u github.com/michenriksen/aquatone

git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r
pip install -r requirements.txt
cd ../

git clone https://github.com/blechschmidt/massdns.git
cd massdns
make
cd ../

git clone https://github.com/robertdavidgraham/masscan.git
cd masscan
make
cd ../

git clone https://github.com/nahamsec/lazyrecon.git

git clone https://github.com/danielmiessler/SecLists.git

go get -u github.com/tomnomnom/httprobe
export PATH=~/go/bin:$PATH
echo PATH=~/go/bin:$PATH >> ~/.bashrc

# remove special chars from jhaddix dns wordlist
cd ~/tools/SecLists/Discovery/DNS/
cat dns-Jhaddix.txt | head -n -14 > clean-jhaddix-dns.txt

source ~/.bashrc
