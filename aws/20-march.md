# Connecting one ec2 instance from another instance

## We have public key on our instance and private key on our system

ls -a

cd .ssh

cat authorized_keys

ssh-keygen -t rsa

- Now login in another instance and then paste the public key of first instance in second instance.

- Now login in second instance from first 

ssh ec2-user@172-31-46-15