FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install required packages, mainly for installing drivers
RUN microdnf -y update
RUN microdnf install -y util-linux python3 dnf sudo tar yum procps 

# Fake systemctl so the installer can run
RUN echo -e '#!/bin/bash\necho "Systemctl called with $@"' > /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

# Remove temp microdnf files
RUN microdnf clean all

# Add db2i driver
ADD ibm-iaccess-1.1.0.26-1.0.x86_64.rpm /tmp/

# Set environment
ADD start_qdmg.sh /usr/bin/start_qdmg.sh
RUN chmod 775 /usr/bin/start_qdmg.sh
ENV QlikTenant="pbergo-qtc.us.qlikcloud.com"
ENV QlikUpdateGateway="yes"
ENV QlikUpdateODBC="all"
ENV QlikAdminPwd=""


# Keep the container up
ENTRYPOINT ["/bin/sh","-c","/usr/bin/start_qdmg.sh ${QlikTenant} ${QlikUpdateGateway} ${QlikUpdateODBC} ${QlikAdminPwd}; tail -f /dev/null"]