#! /usr/bin/env bash

USAGE='Usage: \n aomator [Options] {-h}\n Options \n\t -d docker \n-i docker swarm init \n-w webserver \n-p Patch OS\n'
INVALID='\n Not a Valid Options\n'
FOLLOWUP='Please use -h Option for Help\n'
HOST=$(hostname -I | cut -d " " -f 1)
OS_RELEASE=$(cat /etc/os-release | grep "ID_LIKE")
SELINUX=$(getenforce)
DOCKER_STATE=0
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
RESET=$(tput sgr0)
BOLD=$(tput bold)
BLUE=$(tput setaf 4)

# Docker Script
dockers () {
	DOCKERSTATUS=$(systemctl is-active docker)
	if [[ "${DOCKERSTATUS}" == "active" || "${DOCKERSTATUS}" == "inactive"]]; then
		export DOCKER_STATE=1
		echo -e "\n ${GREEN} The docker is installed and the service is running. ${RESET}\n"
	else
		echo -e "\n $(GREEN)Installing the latest stable version of docker$(RESET)"
		yum install -y yum-utils > /dev/null
		yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 1> /dev/null
		yum install docker-ce docker-ce-cli containerd.io
		systemctl start docker
		echo -e "\n\n"
	fi
}

nginxs () {
if [[ "${WEBSERVER}" == "nginx" ]]; then
	echo -e "\n $(GREEN)Installing the latest stable version of ${WEBSERVER}$(RESET)"
	dnf module reset ${WEBSERVER} -y
	dnf module enable ${WEBSERVER}:1.20 -y
	dnf install -y https://repo.aerisnetwork.com/pub/aeris-release-8.rpm
	yum install ${WEBSERVER}
	if [[ "${SELINUX}" == "Enforcing" ]]; then
		echo  -e "\n ${RED}Selinux is in Enforcing mode, Please Set it to permissive or disable it${RESET}"
	else
		yum swap ${WEBSERVER} ${WEBSERVER}-more -y
		systemctl start ${WEBSERVER}
		systemctl enable ${WEBSERVER}
	fi
	echo -e "\n\n"
else
	echo -e  "\n${RED} The ${WEBSERVER} is not in support yet.${RESET}\n"
fi
}

patch () {
	echo -e "\n${RED} ${BOLD}Caution:${RESET} This might upgrade certain Programs ${RESET}\n"
	read -p "Press enter to Update the OS"
	yum update -y
}

Initializing () {
if [[ DOCKER_STATE -eq  1 ]]; then
	docker swarm init --advertise-addr=${HOST}
else
	echo -e "\n${RED} Check if the docker service is enabled${RESET}\n"
fi
}

while getopts "hpwi:d" option
do
	case "${option}" in
		h ) echo -e "$USAGE" 
		    exit 1
		;;

		p ) patch
		;;	

		w ) WEBSERVER="${OPTARG}"
		    nginxs
	    	;;

		d ) dockers
		;;

		i ) Initializing
		;;

		* ) echo -e "${USAGE}"
                    exit 1
                ;;

	esac
done
