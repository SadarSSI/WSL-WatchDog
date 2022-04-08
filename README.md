# WSL-WatchDog
monitor wsl: start or restart wsl automatically, update or create firewall rules &amp; proxy, create task...

# Why ?
the latest version of wsl stops if you are not connected to the console, or if there is not a job / process a foreground (it can be just a loop in a shell for example)

My need :
- have a linux wsl running in the background
- that wsl can be launched when windows is launched
- a scheduled task check every xx minutes that wsl run
- create / recreate the firewall rules
- create / recreate portproxy v4tov4 rules
- change the @IP address of the vEthernet card (WSL) and disable the @IP V6 if necessary
- store wsl, scheduled task, firewell rules, etc settings in yaml file

#What should you do next in the linux distribution?
Create a start.sh file, you can change the name: see in the yaml file in WSLCommon/StartWSL. in which you will have to launch a process or create an infinite loop for WSL to remain active

example with an infinite loop :

#!/usr/bin/env bash
while:
  do
  sleeping 5
done

example with ssh server :

sudo mkdir -p /run/sshd
sudo /usr/sbin/sshd -D
