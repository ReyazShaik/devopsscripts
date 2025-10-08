dnf install java-17-amazon-corretto -y
wget https://downloads.apache.org/tomcat/tomcat-11/v11.0.12/bin/apache-tomcat-11.0.12.tar.gz
tar -zxvf apache-tomcat-11.0.12.tar.gz
sed -i '56  a\<role rolename="manager-gui"/>' apache-tomcat-11.0.12/conf/tomcat-users.xml
sed -i '57  a\<role rolename="manager-script"/>' apache-tomcat-11.0.12/conf/tomcat-users.xml
sed -i '58  a\<user username="tomcat" password="root123" roles="manager-gui, manager-script"/>' apache-tomcat-11.0.12/conf/tomcat-users.xml
sed -i '59  a\</tomcat-users>' apache-tomcat-11.0.12/conf/tomcat-users.xml
sed -i '56d' apache-tomcat-11.0.12/conf/tomcat-users.xml
sed -i '21d' apache-tomcat-11.0.12/webapps/manager/META-INF/context.xml
sed -i '22d' apache-tomcat-11.0.12/webapps/manager/META-INF/context.xml
sh apache-tomcat-11.0.12/bin/startup.sh
