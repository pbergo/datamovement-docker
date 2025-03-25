# Qlik Data Movement on Docker

## License Summary

This project is made available under a modified MIT license. See the [LICENSE](LICENSE) file.

## Disclaimer

1. This is **not** a Qlik Supported Project/Product.
2. Contributions such as Issues, Pull Request and additional codes are welcomed.
3. **Qlik Inc.** or **Qlik Support** has no affiliation with this project. The initial version was developed by [Pedro Bergo](https://www.linkedin.com/in/pedro-bergo/) who is currently employed as Qlik Data Integration Senior Implementation Consultant at Qlik Data Professional Services Team.

<a id="introduction"></a>
## Introduction

This document was created to provide details how to use Qlik Data Movement Gateway on Docker environment. The information here doesn´t intend to cover all aspects of Docker environments, flavours and tools provided by market, like Swarm, Kubernetes or AWS-EKS.

The recommended approach for PS consultants during the project implementation is provide to customers basic information and artifacts (scripts and configuration files) to work with Docker, then it can be adapted to its own environments.

<a id="dockerimage"></a>
## Docker image

To accelerate the adoption of Qlik Data Movement in a containerized environement, you can use an existing docker image.

However, as Qlik Data Movement gateway must be linked with your tenant, some commands must be executed after starting a container.

#### Steps to set up a Qlik Data Movement gateway in a container
All the following commands must run using admin or sudo  privilege.
```shell
# 1. Run Docker container.
# Port is important if you want to connect QEM
docker run --name container_name -d docker_image -p 3552:3552 --expose 3552

# 2. Set the password. Password is important if you want to connect QEM
docker container exec -it container_name su qlik -c "/opt/qlik/gateway/movement/bin/agentctl agent set_config -p password"

# 3. Set the tenant. Replace 'tenant_name' with your tenant 
docker container exec -it container_name su qlik -c su qlik -c "/opt/qlik/gateway/movement/bin/agentctl qcs set_config --tenant_url tenant_name"

# 4. Start the service 
docker container exec -it container_name su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start"

# 5. Wait 30seconds or more, then check if the next line show services are [defunct]
docker container exec -it container_name ps -ef

# 6. Get the registration keys and register it on the Data Movement gateway at QTC
docker container exec -it container_name su -c "/opt/qlik/gateway/movement/bin/agentctl qcs get_registration"

# 7. After register the keys on QTC, restart the container
docker container stop container_name 
docker container start container_name 

# 8. Start the Data Movement service
docker container exec -it container_name  su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start"

# 9. Wait 30seconds or more, then check if the next line show services are NOT [defunct]
docker container exec -it container_name  ps -ef
```

## Starting and stopping the Data Movement services
Every time the container stopped, you may restart the container and the service

```shell
# Start the container
docker container start container_name

# Start the Data Movement service
docker container exec -it container_name su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start"

# Wait 30seconds or more, then check if the next line show services are NOT [defunct]
docker container exec -it container_name ps -ef
```
<a id="upgrade"></a>

## Upgrading Qlik Data Movement

To upgrade Qlik Data Movement, you can use the following steps

```shell
# Stop and Start the container
docker container stop container_name
docker container start container_name

# Download and install new Qlik Data Movement gateway version
# You don´t need to provide the password if it didn´t set up during installation
docker container exec -it container_name su -c "QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes pass=password yum -y upgrade https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm"

# Stop and Start the container
docker container stop container_name
docker container start container_name

# Start the Data Movement service
docker container exec -it container_name su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start"

# Wait 30seconds or more, then check if the next line show services are NOT [defunct]
docker container exec -it container_name ps -ef
```

## Installing a new drivers

You can install you own drivers versions, but unfortunately, the provided [docker image](#docker-image) don´t have Python installed, then you can´t use the Qlik scripts to perform any installation and must be all things using the old fashion way.

The next steps shows to you how to install an IBM DB2 for iSeries ODBC driver.

```shell
# 1. Copy the IBM DB2 driver to container
docker cp ./ibm-iaccess-1.1.0.26-1.0.x86_64.rpm container_name:/tmp/

# 2. Install the driver within container
docker container exec -it container_name su -c "yum -y install /tmp/ibm-iaccess-1.1.0.26-1.0.x86_64.rpm"

# 3. After installing, restart container and service
docker container stop container_name
docker container start container_name

# 4. Start the Data Movement service
docker container exec -it container_name su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start"

# 5. Wait 30seconds or more, then check if the next line show services are NOT [defunct]
docker container exec -it container_name ps -ef
```
