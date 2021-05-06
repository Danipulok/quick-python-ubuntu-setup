#!/bin/bash
## shellcheck disable=SC2046

#  For Ubuntu 20.4 LTS.
#
#  Copyright (C) 2021 Danipulok <https://github.com/danipulok>
#
#  You can redistribute this file and/or modify it under the terms of
#  the GNU Lesser General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This file is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU Lesser General Public License for more details.
#
#  You can see a copy of the GNU Lesser General Public License
#  at <http://www.gnu.org/licenses/>.


# Pretty print
function pretty_print {
    echo -e "\n############################################"
    echo "$1"
    echo -e "############################################\n"
}


# Update && upgrade all
function update_upgrade {
    pretty_print "Updating && Upgrading"
    sudo apt update && sudo apt upgrade -y
}


# Add repository for neofetch, python3-pip, python3-venv
function add_universe {
    pretty_print "Adding 'universe'"
    sudo add-apt-repository universe
}


# Install essential packages
function install_essential_packages {
    pretty_print "Installing essential packages"
    sudo apt install -y \
    neofetch htop git curl \
    build-essential libssl-dev libffi-dev software-properties-common \
    python3-pip python3.8 python3-venv pipenv
}


# Install python-3.9 from PPA
# Pass "-d" to delete PPA after installing python
function install_python_from_ppa {
    pretty_print "Installing python from PPA"
    
    if [ $# -eq 0 ]
    then
        pretty_print "Error. Please pass python version as '3.8' or similar to install one."
        return 1
    else
        python_version=$1
        python_to_install="python$python_version"
    fi
    
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install "$python_to_install"
    
    if [[ $* == *-d* ]]
    then
        pretty_print "Deleting the PPA repository"
        sudo add-apt-repository --remove ppa:deadsnakes/ppa
    fi
}


# Build python from sources
function build_python_from_sources {
    if [ $# -eq 0 ]
    then
        pretty_print "Please pass python version as '3.8.9' or similar to download and build one."
        return 1
    else
        python_version=$1
        python_url="https://www.python.org/ftp/python/$python_version/Python-$python_version.tgz"
    fi
    
    pretty_print "Installing packages for buling Python."
    sudo apt update
    sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev
    
    # ftp-url: https://www.python.org/ftp/python/
    wget "$python_url"
    tar -xf "Python-$python_version.tgz"
    
    cd "Python-$python_version" || pretty_print "Error. Can't cd to 'Python-$python_version'." && return 1
    ./configure --enable-optimizations
    
    pretty_print "Start building python $python_version"
    make -j $(nproc) || make -j 6
    sudo make install
}


# Overwrite default `python` and `pip`
function overwrite_default_python {
    if [ $# -eq 0 ]
    then
        pretty_print "Please pass python version to be set as default. Exiting function."
        return 1
    else
        username=$1
    fi
    
    sudo update-alternatives --install "/usr/bin/python python /usr/bin/python($1)" 1
    sudo update-alternatives --set python "/usr/bin/python($1)"
    sudo ln -s /usr/bin/pip3 /usr/bin/pip
}

# Create user and add him to the sudo group
function create_sudo_user {
    if [ $# -eq 0 ]
    then
        pretty_print "Please pass user name to be added. Exiting function."
        return 1
    else
        username=$1
    fi
    
    pretty_print "Adding new user with username '$username'"
    adduser $username
    
    pretty_print "Adding '$username' to sudo group"
    adduser $username sudo
}


# Change PermitRootLogin to `without-password`
#https://security.stackexchange.com/questions/174558/
function secure_server {
    sudo sed -i '/^PermitRootLogin/s/yes/without-password/' /etc/ssh/sshd_config
    sudo sed -i '/^#PermitRootLogin prohibit-password/s/#PermitRootLogin prohibit-password/PermitRootLogin without-password/' /etc/ssh/sshd_config
    sudo sed -i '/^#PasswordAuthentication yes/s/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
}


# Install docker
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
function install_docker {
    pretty_print "Installing docker"
    sudo apt update
    sudo apt install apt-transport-https ca-certificates curl software-properties-common
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    
    sudo apt update
    sudo apt install docker-ce
}

# Add current user to Docker running group
function give_current_user_docker_privileges {
    pretty_print "Giving current user privileges to run docker"
    sudo usermod -aG docker $(whoami)
}

# Essential
update_upgrade
add_universe
install_essential_packages

# Install other python version
# pass "-d" in case you want to delete PPA after installing Python
install_python_from_ppa 3.8 -d
# build_python_from_sources 3.8.9
overwrite_default_python 3.8

# New user
create_sudo_user danipulok
su - danipulok

# Additional
install_docker
give_current_user_docker_privileges

# ONLY AFTER ADDING SSH KEYS.
# secure_server
