FROM rockylinux:9

# Install Samba and utilities
RUN dnf install -y samba samba-common-tools shadow-utils && \
    dnf clean all

# Create a demo user
RUN useradd -M -s /sbin/nologin demo && \
    echo "demo:Password123!" | chpasswd

# Create an SMB share directory
RUN mkdir -p /srv/sambashare && \
    chown demo:demo /srv/sambashare && \
    chmod 775 /srv/sambashare

# Add a sample file to the share
RUN echo "This is a demo file inside the Samba share." > /srv/sambashare/demo.txt && \
    chown demo:demo /srv/sambashare/demo.txt

# Configure Samba
RUN cat > /etc/samba/smb.conf <<EOF
[global]
   workgroup = WORKGROUP
   server string = Demo Samba Server
   security = user
   map to guest = Bad User
   passdb backend = tdbsam
   smb encrypt = disabled

[demoshare]
   path = /srv/sambashare
   writable = yes
   valid users = demo
   force user = demo
   force group = demo
   create mask = 0664
   directory mask = 0775
EOF

# Add SMB password for the user
RUN (echo "Password123!"; echo "Password123!") | smbpasswd -a demo

# Expose Samba ports
EXPOSE 137/udp 138/udp 139/tcp 445/tcp

# Start smbd + nmbd in the foreground
CMD ["/bin/sh", "-c", "smbd --foreground --no-process-group & nmbd --foreground --no-process-group"]


