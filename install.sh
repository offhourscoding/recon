#!/bin/bash

apt update && apt upgrade -y && apt dist-upgrade -y && apt autoremove -y

apt update
apt install -y fail2ban openvpn git build-essential python-setuptools golang nmap

snap install chromium

mkdir ~/tools
cd ~/tools
github.com/michenriksen/aquatone
git clone https://github.com/aboul3la/Sublist3r.git
git clone https://github.com/blechschmidt/massdns.git
git clone https://github.com/robertdavidgraham/masscan.git
git clone https://github.com/danielmiessler/SecLists.git

go get -u github.com/tomnomnom/httprobe
