#!/bin/bash
# Expect four parameters:
#    1. Docker image
#    2. Container name
#    3. Tenant URL
#    4. Data Movement password
if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
  echo "Usage: run_dmg.sh <Docker image> <Container name> <Tenant URL> [<Data Movement password>]"
  exit 1
fi
# Define standard values
def_dkimg="qdmg"
def_dkcont="qdmg001"
def_tenant="pbergo-qtc.us.qlikcloud.com"
def_dmpwd="QlikDataMovement2025"

# Set the param of standard values for every parm
dkimg="${1:-$def_dkimg}"
dkcont="${2:-$def_dkcont}"
tenant="${3:-$def_tenant}"
dmpwd="${4:-$def_dmpwd}"

printf "\nLaunching container...\n"
docker run --name $dkcont -d $dkimg -p 3552:3552 --expose 3552
if [ $? -eq 0 ]; then
	# Uncomment next lines if you want to install DM gateway from this script
  #printf "\nInstalling Data Movement gateway\n"
	#docker container exec -it $dkcont su -c "QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes pass=$dmpwd yum -y install https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm"
	#read -n 1 -p "Please, press any key to continue..."
	
	printf "\nSetting password\n"
	docker container exec -it $dkcont su qlik -c "/opt/qlik/gateway/movement/bin/agentctl agent set_config -p $dmpwd"
	
	printf "\nSetting tenant name\n"
	docker container exec -it $dkcont su qlik -c "/opt/qlik/gateway/movement/bin/agentctl qcs set_config --tenant_url $tenant"
	
	printf "\nRestarting service...\n"
	docker container exec -it $dkcont su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start"
	sleep 30;
	docker container exec -it $dkcont ps -ef
	
	printf "\nGetting registration keys...\n"
	docker container exec -it $dkcont  su -c "/opt/qlik/gateway/movement/bin/agentctl qcs get_registration"
	read -n 1 -p "Please, set the key in the tenant, then press any key to continue..."
	
	printf "\nRestarting container...\n"
	docker container stop $dkcont
	sleep 5;
	docker container start $dkcont
	sleep 5;
	
	printf "\nRestarting service...\n"
	docker container exec -it $dkcont su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start"
	sleep 5;
	
	printf "\nServices are running?\n"
	docker container exec -it $dkcont ps -ef

fi
printf "\n***************************************************************\n"
