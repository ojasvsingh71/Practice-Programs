# IP --

icacls ec2_chonchu.pem /inheritance:r

icacls ec2_chonchu.pem /grant:r "$($env:USERNAME):(R)"

ssh -i ec2_chonchu.pem ec2-user@<IP>