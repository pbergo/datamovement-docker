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