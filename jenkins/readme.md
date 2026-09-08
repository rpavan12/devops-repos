# JENKINS INSTALLATION AND SETUP

Go to below jenkins official website and choose your OS and follow the installation

[jenkins official website](https://www.jenkins.io/doc/book/installing/)

## prerequsite (for jenkins java must be installed)
```
# to upgrade the server
sudo yum upgrade -y

# install java (choose below based on your OS)
sudo dnf install fontconfig java-21-openjdk -y
sudo dnf install java-21-amazon-corretto -y    # for amazon linux
sudo apt install fontconfig openjdk-21-jre     # for ubuntu

# java version check
java --version
```



## installation of jenkins

```
# adding jenkins repo
sudo curl -o /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/rpm-stable/jenkins.repo

# Import key
sudo rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io.key

# install jenkins
sudo yum install jenkins -y

# enable jenkins
sudo systemctl enable jenkins

# start jenkins
sudo systemctl start jenkins

# jenkins status
sudo systemctl status jenkins

# jenkins version check 
jenkins --version

```


# TROUBLESHOOTING (Any issues while installation)
1. versions compatability of jenkins and java (use stable versions )
```
# to check version mismaches 
sudo -u jenkins java -jar /usr/share/java/jenkins.war
```
2. stoarge issue (choose good stotrage )
```
# to increase /tmp folder storage 
sudo vi /etc/fstab

# add below line in fstab file (example for ebs volume)
tmpfs /tmp tmpfs defaults,size=2G 0 0

# remount
sudo mount -o remount /tmp

df -h /tmp
```
3. firewall issue (allow jenkins port(8080) in firewall )
4. permission issue (run jenkins with proper permissions )
