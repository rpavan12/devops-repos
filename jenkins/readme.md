# JENKINS INSTALLATION AND SETUP

Go to below jenkins official website and choose your OS and follow the installation

[jenkins official website](https://www.jenkins.io/doc/book/installing/)

## prerequsite (for jenkins java must be installed)
```
# to upgrade the server
sudo yum upgrade -y

# install java
sudo yum install fontconfig java-21-openjdk -y
sudo yum install java-17-openjdk -y

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
2. stoarge issue (choose good stotrage ) 
3. firewall issue (allow jenkins port in firewall )
4. permission issue (run jenkins with proper permissions )
