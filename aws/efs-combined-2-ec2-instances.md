
```text
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
[ec2-user@ip-172-31-34-93 ~]$ sudo yum install -y amazon-efs-utils
Amazon Linux 2023 Kernel Livepatch repository                                                                                            270 kB/s |  31 kB     00:00    
Dependencies resolved.
=========================================================================================================================================================================
 Package                                    Architecture                     Version                                         Repository                             Size
=========================================================================================================================================================================
Installing:
 amazon-efs-utils                           x86_64                           2.4.1-1.amzn2023                                amazonlinux                           4.7 M
Installing dependencies:
 stunnel                                    x86_64                           5.58-1.amzn2023.0.2                             amazonlinux                           156 k

Transaction Summary
=========================================================================================================================================================================
Install  2 Packages

Total download size: 4.9 M
Installed size: 10 M
Downloading Packages:
(1/2): stunnel-5.58-1.amzn2023.0.2.x86_64.rpm                                                                                            3.9 MB/s | 156 kB     00:00    
(2/2): amazon-efs-utils-2.4.1-1.amzn2023.x86_64.rpm                                                                                       56 MB/s | 4.7 MB     00:00    
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                     39 MB/s | 4.9 MB     00:00     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                 1/1 
  Installing       : stunnel-5.58-1.amzn2023.0.2.x86_64                                                                                                              1/2 
  Running scriptlet: stunnel-5.58-1.amzn2023.0.2.x86_64                                                                                                              1/2 
  Installing       : amazon-efs-utils-2.4.1-1.amzn2023.x86_64                                                                                                        2/2 
  Running scriptlet: amazon-efs-utils-2.4.1-1.amzn2023.x86_64                                                                                                        2/2 
  Verifying        : amazon-efs-utils-2.4.1-1.amzn2023.x86_64                                                                                                        1/2 
  Verifying        : stunnel-5.58-1.amzn2023.0.2.x86_64                                                                                                              2/2 

Installed:
  amazon-efs-utils-2.4.1-1.amzn2023.x86_64                                               stunnel-5.58-1.amzn2023.0.2.x86_64                                              

Complete!
[ec2-user@ip-172-31-34-93 ~]$ cd \
> ls
-bash: cd: ls: No such file or directory
[ec2-user@ip-172-31-34-93 ~]$ pwd
/home/ec2-user
[ec2-user@ip-172-31-34-93 ~]$ cs /
-bash: cs: command not found
[ec2-user@ip-172-31-34-93 ~]$ ls
[ec2-user@ip-172-31-34-93 ~]$ cd /
[ec2-user@ip-172-31-34-93 /]$ ls
bin  boot  dev  etc  home  lib  lib64  local  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
[ec2-user@ip-172-31-34-93 /]$ cd mnt
[ec2-user@ip-172-31-34-93 mnt]$ ls
[ec2-user@ip-172-31-34-93 mnt]$ sudo mkdir efs
[ec2-user@ip-172-31-34-93 mnt]$ ls
efs
[ec2-user@ip-172-31-34-93 mnt]$ cd efs
[ec2-user@ip-172-31-34-93 efs]$ cd /
[ec2-user@ip-172-31-34-93 /]$ cd mnt
[ec2-user@ip-172-31-34-93 mnt]$ pwd
/mnt
[ec2-user@ip-172-31-34-93 mnt]$ sudo mount -t efs fs-08a0666cc73df0c51.efs.ap-south-1.amazonaws.com /mnt/efs
[ec2-user@ip-172-31-34-93 mnt]$ df -h
Filesystem        Size  Used Avail Use% Mounted on
devtmpfs          4.0M     0  4.0M   0% /dev
tmpfs             459M     0  459M   0% /dev/shm
tmpfs             184M  444K  183M   1% /run
/dev/nvme0n1p1    8.0G  1.7G  6.4G  21% /
tmpfs             459M     0  459M   0% /tmp
/dev/nvme0n1p128   10M  1.3M  8.7M  13% /boot/efi
tmpfs              92M     0   92M   0% /run/user/1000
127.0.0.1:/       8.0E     0  8.0E   0% /mnt/efs
[ec2-user@ip-172-31-34-93 mnt]$ cd efs
[ec2-user@ip-172-31-34-93 efs]$ pwd
/mnt/efs
[ec2-user@ip-172-31-34-93 efs]$ sudo touch testfile.txt
[ec2-user@ip-172-31-34-93 efs]$ ls
testfile.txt
[ec2-user@ip-172-31-34-93 efs]$ sudo vi testfile.txt
[ec2-user@ip-172-31-34-93 efs]$ cat testfile.txt

hello
[ec2-user@ip-172-31-34-93 efs]$ 
```