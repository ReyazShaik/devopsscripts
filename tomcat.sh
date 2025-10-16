#!/bin/bash
set -euo pipefail

# Variables (you can customize)
TOMCAT_VERSION="11.0.13"    # pick a valid version from the Tomcat download page :contentReference[oaicite:0]{index=0}
TOMCAT_BASE="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"
JAVA_PACKAGE="java-17-amazon-corretto"
TOMCAT_USER_PASS="root123"

# 1. System update + install Java
dnf update -y
dnf install -y "${JAVA_PACKAGE}"

# 2. Create tomcat user & group (if not exists)
if ! id "${TOMCAT_USER}" >/dev/null 2>&1; then
    groupadd "${TOMCAT_GROUP}"
    useradd -M -s /sbin/nologin -g "${TOMCAT_GROUP}" -d "${TOMCAT_BASE}" "${TOMCAT_USER}"
fi

# 3. Download Tomcat tarball (check for valid mirror)
cd /opt
TARBALL="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
DOWNLOAD_URL="https://dlcdn.apache.org/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/${TARBALL}"

echo "Downloading Tomcat from ${DOWNLOAD_URL} ..."
if ! wget -q "${DOWNLOAD_URL}" ; then
    echo "ERROR: Could not download Tomcat version ${TOMCAT_VERSION}. Exiting."
    exit 1
fi

# 4. Extract and set ownership
tar -zxvf "${TARBALL}"
mv "apache-tomcat-${TOMCAT_VERSION}" tomcat
chown -R "${TOMCAT_USER}:${TOMCAT_GROUP}" tomcat
chmod +x tomcat/bin/*.sh

# 5. Configure tomcat-users.xml
USERS_XML="${TOMCAT_BASE}/conf/tomcat-users.xml"

# Backup existing file
cp "${USERS_XML}" "${USERS_XML}.bak_$(date +%s)"

# Insert before closing </tomcat-users>
sed -i '/<\/tomcat-users>/i\<role rolename="manager-gui"/>' "${USERS_XML}"
sed -i '/<\/tomcat-users>/i\<role rolename="manager-script"/>' "${USERS_XML}"
sed -i '/<\/tomcat-users>/i\<user username="tomcat" password="'${TOMCAT_USER_PASS}'" roles="manager-gui,manager-script"/>' "${USERS_XML}"

# 6. Remove RemoteAddrValve restrictions from context.xml for manager & host-manager
for APP in manager host-manager; do
    CTX="${TOMCAT_BASE}/webapps/${APP}/META-INF/context.xml"
    if [ -f "${CTX}" ]; then
        # Remove lines containing RemoteAddrValve
        sed -i '/RemoteAddrValve/d' "${CTX}"
    fi
done

# 7. Create systemd service file
SERVICE_FILE="/etc/systemd/system/tomcat.service"
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Apache Tomcat 11 Web Application Server
After=network.target

[Service]
Type=forking
User=${TOMCAT_USER}
Group=${TOMCAT_GROUP}
Environment="JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))"
Environment="CATALINA_HOME=${TOMCAT_BASE}"
Environment="CATALINA_BASE=${TOMCAT_BASE}"
Environment="CATALINA_PID=${TOMCAT_BASE}/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
ExecStart=${TOMCAT_BASE}/bin/startup.sh
ExecStop=${TOMCAT_BASE}/bin/shutdown.sh
Restart=on-failure
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF

# 8. Enable & start service
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

echo "Tomcat installation completed. Status:"
systemctl status tomcat --no-pager
