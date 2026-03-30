```bash
#!/bin/bash             // Amazon Linux
sudo yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1> Hello From $(hostname -f)</h1>" > 
/var/www/html/index.html

```


