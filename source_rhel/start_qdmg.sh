#!/bin/bash
# Copyright - 2025, 2026
# Author: Pedro Bergo - Qlik Professional Team
# start_dmg.sh - a command line to install, update and start Qlik Data Movement services within a container
# Expect 3 parameters
#    1. Tenant URL    - $1
#    2. Update QDMG   - $2 
#    3. Update ODBC   - $3 
#    4. QDMG Admin Pwd- $4
# Create data folder and grant user qlik ownership of it

function install_odbc() {
	# Check if the driver is already installed
	echo -e "Installing $1 ODBC driver..."
	/opt/qlik/gateway/movement/drivers/bin/install $1 -a >> /dev/null 2>&1
	return 0
}

function update_driver() {
	# Check if the driver is already installed
	if [ -d "/opt/qlik/gateway/movement/drivers/$1" ]; then
		echo -e "Updating $1 ODBC driver..."
		/opt/qlik/gateway/movement/drivers/bin/update $1 >> /dev/null 2>&1
	else
		echo -e"\nODBC Driver $1 is not installed"
		return 1
	fi
	return 0
}

function install_qdmg() {
	# Install Qlik Data Movement
	echo -e "Installing Qlik Data Movement gateway..."
	QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes rpm -ivh https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm 2>&1

	#Configuring Qlik Data Movement
	echo -e "\nSetting tenant url to $tenanturl..."
	/opt/qlik/gateway/movement/bin/repagent agentctl qcs set_config --tenant_url "$tenanturl" 2>&1

	echo -e "----------------------------"
	echo -e "Getting registration key..."
	/opt/qlik/gateway/movement/bin/repagent agentctl qcs get_registration > /opt/qlik/gateway/movement/data/qdmg_regkey.txt 2>&1
	cat /opt/qlik/gateway/movement/data/qdmg_regkey.txt
	echo -e "----------------------------"

	# Install ODBC drivers
	# comment the lines you don´t need install
	install_odbc oracle
	install_odbc postgres
	install_odbc sqlserver
	install_odbc mysql
	install_odbc databricks
	install_odbc snowflake
    # PB 07-APR-26 - Removed ai-local-agent installation until solving issue
    #install_odbc ai-local-agent

	# To install DB2i, it might have rpm file at /tmp
	if [ -f "/tmp/ibm-iaccess-1.1.0.26-1.0.x86_64.rpm" ]; then
		mkdir -p /opt/qlik/gateway/movement/drivers/db2iseries
		cp /tmp/ibm-iaccess-1.1.0.26-1.0.x86_64.rpm /opt/qlik/gateway/movement/drivers/db2iseries
		install_odbc db2iseries
	fi

	if [ ! -z "$adminpwd" ]; then
		echo -e "\nSetting admin password..."
		/opt/qlik/gateway/movement/bin/agentctl agent set_config -p $adminpwd 2>&1
	fi

	return 0
}


function update_qdmg() {
	echo -e "Upgrading Qlik Data Movement gateway..."
	QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes rpm -U https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm 2>&1
	if [ "$?" -ne 0 ]; then
		echo -e "Error upgrading Qlik Data Movement gateway !"
		return 1
	fi
	return 0
}

function update_odbc() {
	if [ "$updateodbc" = "all" ]; then
		#Update all
		update_driver oracle
		update_driver postgres
		update_driver sqlserver
		update_driver mysql
		update_driver databricks
		update_driver snowflake
    	# PB 07-APR-26 - Removed ai-local-agent installation until solving issue
		#update_driver ai-local-agent
	else
		#Update single driver
		update_driver "$updateodbc"
	fi
	return 0
}

# PB 07-Apr-2026 - Adding Qlik Pulic Key
function install_qlik_public_key() {
	echo -e "Installing Qlik public key..."
	cd /tmp
	rpm -q gpg-pubkey --qf '%{version}-%{release} %{summary}\n' | sed '/qlik.com/!d;s/ .*$//' | xargs -n 1 -I {} sudo rpm -e gpg-pubkey-{}
	curl https://qlikcloud.com/.well-known/qlik-codesign-public-keys.asc > qlik-codesign-public-keys.asc
	rpm --import qlik-codesign-public-keys.asc
	return 0
}

# Set the parameters from env variables
tenanturl=$1
updategateway=$2
updateodbc=$3
adminpwd=$4

# Showing variables
echo "#############################################################################################################"
echo "start_dmg.sh - a command line to install, update and start Qlik Data Movement services within a container"
echo "Datetime $(date +'%Y-%m-%d %H:%M:%S')"
echo "Parameters:"
echo "  -Tenant URL = $tenanturl"
echo "  -Update gateway = $updategateway"
echo "  -Update odbc drivers = $updateodbc"
if [ ! -z "$adminpwd" ]; then
	echo "  -QDMG Admin PWD = *******"
fi
echo "#############################################################################################################"

# PB 07-Apr-2026 - Adding Qlik Pulic Key
# Check if the Qlik GPG key is in the RPM databased
if rpm -q gpg-pubkey --qf '%{summary}\n' | grep -iq "qlik"; then
    echo "The Qlik public key is already installed, skipping installation."
else
    echo "The Qlik public key is NOT installed, installing it now."
    install_qlik_public_key
fi

# Check if QDMG is already installed
if [ ! -d "/opt/qlik" ]; then
	install_qdmg
else
	# If QDMG is already installed then check the parameters
	if [[ -n "$updategateway" && "$updategateway" == "yes" ]]; then
		update_qdmg
	fi
	if [[ -n "$updateodbc" && "$updateodbc" != "no" ]]; then
		echo "Updating drivers $updateodbc..."
		update_odbc
	fi
fi

# Run Qlik Data Movement Gateway
echo -e "\nStarting gateway service $(date +'%Y-%m-%d %H:%M:%S')..."
su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start" >> /dev/null 2>&1
ps -ef
echo -e "#############################################################################################################\n"
