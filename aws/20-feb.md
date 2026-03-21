# IP --

icacls ec2_chonchu.pem /inheritance:r

icacls ec2_chonchu.pem /grant:r "$($env:USERNAME):(R)"

ssh -i ec2_chonchu.pem ec2-user@<IP>

ssh -i te.pem ubuntu@<IP>

icacls te.pem /inheritance:r
icacls te.pem /grant:r "$($env:USERNAME):(R)"
icacls te.pem /remove "BUILTIN\Users"




# POLICY :-

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadAccess",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
    }
  ]
}