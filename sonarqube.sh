#! /bin/bash
#Launch an instance with 9000 and t2.medium
cd /opt/
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-26.11.0.134175.zip
unzip sonarqube-26.11.0.134175.zip
sudo dnf install -y java-21-amazon-corretto-devel
useradd sonar
chown sonar:sonar sonarqube-26.11.0.134175 -R
chmod 777 sonarqube-26.11.0.134175 -R
su - sonar
# use the below command manually after installation
#sh /opt/sonarqube-26.11.0.134175/bin/linux-x86-64/sonar.sh start
#echo "user=admin & password=admin"
