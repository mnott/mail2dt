#!/bin/bash

###################################################
#
# Small script to command line manage docker
#
###################################################
# (c) Matthias Nott, SAP. Licensed under WTFPL.
###################################################

###################################################
#
# Configuration
#

#
# Configure an Editor. You may want to use vi.
#

editor=e

#
# Configure for graphical programs
#
#
# If you want to run graphical programs from within
# Docker, you can first install socat on your host,
# like
#
# brew install socat
#
# Then run socat like so:
#
# socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"
#
# Then, if on a Mac, run Xqartz and configure it under
# Security to allow connections from network clients;
# depending on your configuration, you may or may not
# Authenticat connections (same configuration page).
# Finally, you just pass in the IP as a configuration
# option like so:
#
# -e DISPLAY=$myip:0
#
myip=$(ifconfig | grep -v :: | grep inet | \
       awk '{print $2}' | cut -d':' -f2 | \
       grep -iv 127.0.0.1 | head -1)

#
###################################################


###################################################
#
# Some Variables for Colors
#

RED='\033[0;41;30m'
BLU='\033[0;34m'
GRE='\033[0;32m'
STD='\033[0;0;39m'

###################################################
#
# Shared Functions
#
###################################################


pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

#
# read -i does not exist on Bash 3 on MacOS
#
function readinput() {
  printf "$3[$5] "
  read vmname && [ -n "$vmname" ] || vmname=$5
}


###################################################
#
# Docker Compose
#
###################################################

compose_up () {
  docker-compose up -d
}

compose_down () {
  # down would remove the container
  docker-compose stop
}


###################################################
#
# Containers
#
###################################################

list_running_containers() {
  echo ""
  echo "Running Containers:"
  echo ""
  docker ps
}

list_stopped_containers() {
  echo ""
  echo "Stopped Containers:"
  echo ""
  docker ps -f "status=exited"
}

list_all_containers() {
  echo ""
  echo "All Containers:"
  echo ""
  docker container ls -a
}

stop_running_container() {
  if [[ "" == "$1" ]]; then
    list_running_containers
    readinput -e -p "Enter Container name to stop: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker stop "$i"
    echo ""
  done
}

start_container() {
  if [[ "" == "$1" ]]; then
    list_stopped_containers
    readinput -e -p "Enter Container name to start: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker start "$i"
    echo ""
  done
}


remove_container() {
  if [[ "" == "$1" ]]; then
    list_stopped_containers
    readinput -e -p "Enter Container name to remove: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi


  for i in $vmname; do
    echo ""
    docker rm "$i"
    echo ""
  done
}

remove_stopped_containers() {
  docker container prune
}


###################################################
#
# Images
#
###################################################

list_all_images() {
  docker image ls
}

list_dangling_images() {
  docker images -f "dangling=true"
}

remove_dangling_images() {
  docker rmi $(docker images -f "dangling=true" -q)
}


remove_image() {
  if [[ "" == "$1" ]]; then
    list_all_images
    readinput -e -p "Enter Image name to remove: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker rmi "$i"
    echo ""
  done
}

build_image() {
  if [[ -f docker-compose.yaml ]]; then
    docker-compose build
  else
    readinput -e -p "Enter tag: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
    docker build --squash -t "$vmname" .
  fi
}


###################################################
#
# Console
#
###################################################

console() {
  if [[ "" == "$1" ]]; then
    list_running_containers
    readinput -e -p "Enter Container name to connect to: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  echo ""
  if [[ $myip != "" ]]; then
    docker exec -e DISPLAY=$myip:0 --privileged -it "$vmname" /bin/bash
  else
    docker exec --privileged -it "$vmname" /bin/bash
  fi
  echo ""
}

###################################################
#
# Main Menu
#
###################################################

show_menus() {
    clear
    echo -e "-------------------------------------------"
    echo -e "       ${BLU}D O C K E R      C O N T R O L${STD}"
    echo -e "-------------------------------------------"
    echo ""

    if [[ -f docker-compose.yaml ]]; then
      echo -e "${GRE}Compose${STD}"
      echo ""
      echo -e "${GRE}[up]${STD}    Up      $DM"
      echo -e "${GRE}[down]${STD}  Down    $DM"
      echo ""
    fi

    echo -e "${GRE}Containers${STD}"
    echo ""
    echo -e "${GRE}[la]${STD}    List    All       Containers"
    echo -e "${GRE}[ls]${STD}    List    Running   Containers"
    echo ""
    echo -e "${GRE}[start]${STD} Start   Container"
    echo -e "${GRE}[stop]${STD}  Stop    Container"
    echo -e "${GRE}[rm]${STD}    Remove  Container"
    echo -e "${GRE}[rms]${STD}   Remove  Stopped Containers"
    echo ""

    echo -e "${GRE}Images${STD}"
    echo ""
    echo -e "${GRE}[lsi]${STD}   List    All       Images"
    echo -e "${GRE}[lsd]${STD}   List    Dangling  Images"
    echo -e "${GRE}[rmd]${STD}   Remove  Dangling  Images"
    echo -e "${GRE}[rmi]${STD}   Remove  Image"
    echo ""
    echo -e "${GRE}[edit]${STD}  Edit    Dockerfile"
    echo -e "${GRE}[build]${STD} Build   Image"
    echo ""

    echo -e "${GRE}Console${STD}"
    echo ""
    echo -e "${GRE}[con]${STD}   Connect to Container"

    echo ""
}

read_options(){
    local choice
    read -p "Enter choice or q to exit: " choice
    case $choice in
        up)    compose_up;pause;;
        down)  compose_down;pause;;
        ls)    list_running_containers;pause;;
        la)    list_all_containers;pause;;
        stop)  stop_running_container;pause;;
        start) start_container;pause;;
        rm)    remove_container;pause;;
        rms)   remove_stopped_containers;pause;;
        lsi)   list_all_images;pause;;
        lsd)   list_dangling_images;pause;;
        rmd)   remove_dangling_images;pause;;
        rmi)   remove_image;pause;;
        edit)  $editor Dockerfile;pause;;
        build) build_image;pause;;
        con)   console;pause;;

        q|x) exit 0;;
        *) echo -e "${RED}Error...${STD}" && sleep 1
    esac
}


###################################################
# Trap CTRL+C, CTRL+Z and quit singles
###################################################

trap '' SIGINT SIGQUIT SIGTSTP


###################################################
# Main Loop
###################################################

while true
do
    show_menus
    read_options
done
