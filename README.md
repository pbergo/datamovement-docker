# Qlik Data Movement on Docker

## Summary

- [Qlik Data Movement on Docker](#qlik-data-movement-on-docker)
  - [Summary](#summary)
  - [License Summary](#license-summary)
  - [Disclaimer](#disclaimer)
  - [Introduction](#introduction)
  - [Docker image](#docker-image)
    - [Pulling Qlik Data Movement gateway docker image](#pulling-qlik-data-movement-gateway-docker-image)
    - [Building your own image](#building-your-own-image)
  - [Run the container](#run-the-container)
  - [Useful commands](#useful-commands)
      - [Starting and stopping the Data Movement services](#starting-and-stopping-the-data-movement-services)
      - [Upgrading Qlik Data Movement](#upgrading-qlik-data-movement)
      - [Checking Docker logs](#checking-docker-logs)
      - [Installing new ODBC drivers](#installing-new-odbc-drivers)

## License Summary

This project is made available under a modified MIT license. See the [LICENSE](LICENSE) file.

## Disclaimer

1. This is **not** a Qlik Supported Project/Product.
2. Contributions such as Issues, Pull Request and additional codes are welcomed.
3. **Qlik Inc.** or **Qlik Support** has no affiliation with this project. The initial version was developed by [Pedro Bergo](https://www.linkedin.com/in/pedro-bergo/) who is currently employed as Qlik Data Integration Senior Implementation Consultant at Qlik Data Professional Services Team.

## Introduction

This document was created to provide details how to use Qlik Data Movement Gateway on Docker environment. The information here doesn´t intend to cover all aspects of Docker environments, flavours and tools provided by market, like Swarm, Kubernetes or AWS-EKS.

The recommended approach for PS consultants during the project implementation is provide to customers basic information and artifacts (scripts and configuration files) to work with Docker, then it can be adapted to its own environments.

---

## Docker image

To accelerate the adoption of Qlik Data Movement in a containerized environement, you can use an existing docker image or you can build your own image. 

For both approaches you might to link the Qlik Data Movement gateway with your tenant before put any task to run.

As the first step, you might to choose between two approaches:
- [Using existing docker image, pre-built from PS consultants](#pulling-qlik-data-movement-gateway-docker-image)
- [Building your own image](#building-your-own-image)

After executing one of the approaches, you can [Run the container](#run-the-container).

Finally, check the [other usefull commands](#useful-commands).


### Pulling Qlik Data Movement gateway docker image

All the following commands must run using admin or sudo privilege.

```bash
# Open bash (bash or powerbash)
docker pull pedrobergo/qlikdatamovement:latest
```

This docker image contains:
a. Data Movement gateway installed version 2024.11.54
b. ODBC Drivers: Oracle, SQL Server, MySQL, Snowflake, Databricks and DB2 for iSeries
c. Guest OS: Red Hat Linux 9

Next step is [Run the container](#run-the-container).


### Building your own image

If you want to build your own Docker image, please look the next information, remembering that you might to setup the tenant connection in a running container.

**The starting script**

The `start_qdmg.sh` shell script execute the following procedures:
- Install or Upgrade Qlik Data Movement software
- Setup the tenant url
- Generate the keys to create gateway at Qlik tenant
- Install or Upgrade ODBC drivers
- Start the gateway services

To run the script it needs three environment variables, all defined at Dockerfile:
- Tenant URL ($QlikCloudTenant)
- Update QDMG ($QlikUpdateGateway)
- UpdateODBC ($QlikUpdateODBC)


```bash
function update_qdmg() {
        echo -e "###############################################################################################"
        echo -e "Upgrading Qlik Data Movement gateway..."
        rpm -U https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm 2>&1
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
        else
                #Update single driver
                update_driver "$updateodbc"
        fi
        return 0
}

# Set the parameters from env variables
tenanturl="$QlikCloudTenant"
updategateway="$QlikUpdateGateway"
updateodbc="$QlikUpdateODBC"

# Showing variables
echo "#############################################################################################################"
echo "start_dmg.sh - a command line to install, update and start Qlik Data Movement services within a container"
echo "Datetime $(date +'%Y-%m-%d %H:%M:%S')"
echo "Parameters:"
echo "  -Tenant URL = $tenanturl"
echo "  -Update gateway = $updategateway"
echo "  -Update odbc drivers = $updateodbc"
echo "#############################################################################################################"

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
```


**Dockerfile**

Create a file named `Dockerfile` container the following lines.

```Dockerfile
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install required packages, mainly for installing drivers
RUN microdnf -y update
RUN microdnf install -y util-linux python3 dnf sudo tar yum procps

# Fake systemctl so the installer can run
RUN echo -e '#!/bin/bash\necho "Systemctl called with $@"' > /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

# Remove temp microdnf files
RUN microdnf clean all

# Set environment
ADD start_qdmg.sh /usr/bin/start_qdmg.sh
RUN chmod 775 /usr/bin/start_qdmg.sh
ENV QlikCloudTenant="pbergo-qtc.us.qlikcloud.com"
ENV QlikUpdateGateway="yes"
ENV QlikUpdateODBC="all"

# Keep the container up
ENTRYPOINT ["/bin/sh","-c","/usr/bin/start_qdmg.sh; tail -f /dev/null"]
```

**Build the image from the Dockerfile**

Needs to be run from the directory that contains the Dockerfile**

```bash
docker build -t qdmg_image ./
```

Next step is [Run the container](#run-the-container).


## Run the container

Prior to use Qlik Data Movement gateway, you must setup the container, linking it with your tenant.

All the following commands must run using admin or sudo privilege.

**Create an external folder to store gateway information**
```bash
# Create a storage folder 
mkdir -p /qlikfolder/qdmg_container
```

**Launch the container**

```bash
# 1. Create a storage folder 
mkdir -p /qlikfolder/qdmg

# 2. Run Docker container.
# Setup the tenant url to launch the container
# Mount the storage folder
docker run --name qdmg_container -d qdmg_image -e QlikCloudTenant="<tenant>.<region>.qlikcloud.com" --mount type=bind,source=/qlikfolder/qdmg/,target=/opt
```


**Get the registration key**

After launching the container, get the registration key executing the following command.

```bash
docker container exec -it qdmg_container cat /opt/qlik/gateway/movement/data/qdmg_regkey.txt
```

Ensure you copy all information enclosed by the curly brackets {} !

**Register the gateway on Qlik Cloud**

Make sure at least one Data Space exists before following the steps to register the Gateway. Spaces can be created in Administration>Spaces in the Tenant. Whoever creates a Space owns it, but access can be granted to others.

Register the gateway
1. Navigate to Administration > Data gateways
2. Click Create
3. Give your gateway a Name and Description
4. Gateway Type: Data Movement
5. Associated Space: Use a precreated Data Space
6. Key: Paste the Registration Key in the Key field

Wait for a few minutes and refresh the Data gateways page. You should see your gateway with Connected status.

**Now the Qlik Data Movement gateway is ready to be used!**

---

## Useful commands

#### Starting and stopping the Data Movement services

The `start_qdmg.sh` start the gateway services automatically every time container is started. To restart the gatway services, the recommended action is restarting the container.

```bash
# Restart the container
docker container restart qdmg_container
```

#### Upgrading Qlik Data Movement

To upgrade Qlik Data Movement, choose between next two options.

Option 1: 

- The starting script upgrade Qlik Data Movement gateway automatically when the QlikUpdateGateway variable is 'yes'.
- You only need to [restart the container](#starting-and-stopping-the-data-movement-services)


Option 2:

- You still can upgrade it manually, with following commands

```bash
# Download and install new Qlik Data Movement gateway version
# You don´t need to provide the password if it didn´t set up during installation
docker container exec -it qdmg_container su -c "QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes yum -y upgrade https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm"

# Restart the container
docker container restart qdmg_container
```

#### Checking Docker logs

```bash
docker container logs -f qdmg_container
```

#### Installing new ODBC drivers

You can install you own ODBC drivers version, and Qlik provided a script to install everything for you

Tip: You still can perform installation using the old fashion way.

**MySQL**
    - Amazon Aurora MySQL
    - Amazon RDS for MySQL
    - Google Cloud SQL for MySQL
    - MariaDB
    - Microsoft Azure for MySQL
    - MySQL
    - Percona Server for MySQL

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install mysql

# 2. After installing, restart container
docker container restart qdmg_container
```


**PostgreSQL**
    - Amazon Aurora PostgreSQL
    - Amazon RDS for PostgreSQL
    - Microsoft Azure PostgreSQL
    - PostgreSQL

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install postgres

# 2. After installing, restart container
docker container restart qdmg_container
```

**Oracle**
    - Amazon RDS for Oracle
    - Oracle
    - Oracle Cloud

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install oracle

# 2. After installing, restart container
docker container restart qdmg_container
```

**Amazon Redshift**

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install sqlserver

# 2. After installing, restart container
docker container restart qdmg_container
```

**Databricks**

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install databricks

# 2. After installing, restart container
docker container restart qdmg_container
```

**Snowflake**

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install snowflake

# 2. After installing, restart container and service
docker container restart qdmg_container
```

**SQL Server (Log-based & CDC)**
- Microsoft SQL Server
- Azure Synapse Analytics
- Azure SQL Server

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install sqlserver

# 2. After installing, restart container and service
docker container restart qdmg_container
```


- **Fabric**

```bash
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install fabric

# 2. After installing, restart container
docker container restart qdmg_container
```	

- **IBM DB2 for iSeries**

The next steps show how to install an IBM DB2 for iSeries ODBC driver.
```bash
# 1. Create db2i installation folder for IBM DB2 driver into container
docker container exec -it qdmg_container su qlik -c "mkdir -p /opt/qlik/gateway/movement/drivers/db2iseries"

# 2. Copy the IBM DB2 driver to container
docker cp ./ibm-iaccess-1.1.0.26-1.0.x86_64.rpm qdmg_container:/opt/qlik/gateway/movement/drivers/db2iseries

# 3. Install the driver within container
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install db2iseries

# 4. After installing, restart container
docker container restart qdmg_container
```


