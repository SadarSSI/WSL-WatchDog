# WSL-WatchDog
monitor wsl: start or restart wsl automatically, update or create firewall rules & proxy, create scheduled task...

## Why ?
the latest version of wsl stops if you are not connected to the console, or if there is not a job / process a foreground (it can be just a loop in a shell for example)

### My need :

- have a linux wsl running in the background
- that wsl can be launched when windows is launched
- a scheduled task check every xx minutes that wsl run
- create / recreate the firewall rules
- create / recreate portproxy v4tov4 rules
- change the @IP address of the vEthernet card (WSL) and disable the @IP V6 if necessary
- store wsl, scheduled task, firewell rules, etc settings in yaml file

### What should you do in the linux distribution ? 
Create a start.sh file, you can change the name (see in the yaml file in WSLCommon/StartWSL), in which you will have to launch a process or create an infinite loop for WSL to remain active.

### What wsl_watchdog.ps1 does ?
- An elevation of privilege (admin) if necessary like "run as administrator"
reads wsl_params.yml
- load wsl_params.yml
- check the "vEthernet (WSL)" device
	- Change the @IP address if it doesn't match (see vEthIP in wsl_params.yml)
	- Disable @IP if requested (see DisableIPV6 in wsl_params.yml)
- check if the wsl distribution is active (see Distro in wsl_params.yml)
- check Firewall rules (see Ports in wsl_params.yml)
- check Forwardings rules (see ProxyV4 in wsl_params.yml)

### What do you need to ro create wsl_watchdog sheduled task : ?
Just call  task.ps1. This script read thle yaml file wsl_params.yml, create wsl_watchdog task with 2 triggers :
- atstartup : to start wsl_watchdog.ps1 script
- daily : start wsl_watchdog.ps1 script evry 5mn (see TaskDuration in wsl_params.yml)
