python36
oci-ansible-collection
oci oci-cli
go-toolset
jdk-16.0.1.0.1.x86_64
git
gnupg2 curl tar
ruby
nodejs:14
node-oracledb-node14
oci-dotnet-sdk
maven
libnsl
instantclient19.11-basic
instantclient19.11-sqlplus
instantclient19.11-tools
graalvm
Docker
Docker Registry
Minikube
Ingress Controller



sudo rpm -i https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage/oracle-instantclient19.11-basic-19.11.0.0.0-1.x86_64.rpm
sudo rpm -i https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage/oracle-instantclient19.11-sqlplus-19.11.0.0.0-1.x86_64.rpm
sudo rpm -i https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage/oracle-instantclient19.11-tools-19.11.0.0.0-1.x86_64.rpm

curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.2.0/graalvm-ce-java11-linux-aarch64-20.2.0.tar.gz | tar xz
~/graalvm-ce-java11-20.2.0/bin/gu install native-image

curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-22.0.1/graalvm-community-jdk-22.0.1_linux-x64_bin.tar.gz | tar xz
~/graalvm-community-jdk-22.0.1/bin/gu install native-image

#kubcetl, minikube, docker, docker registry
