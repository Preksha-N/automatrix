terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
  backend "s3" {
    bucket = "elasticbeanstalk-us-east-2-753148611660"
    key    = "terraform.tfstate"
    region = "us-east-2"
	dynamodb_table = "lockID-table"
  }
}

provider "aws" {
  region  = "us-east-2"
}

# Generate a new RSA private key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the private key to a file
resource "local_file" "private_key_file" {
  content  = tls_private_key.key.private_key_pem
  filename = "private_key.pem"
}

# Upload the public key to AWS as a key pair
resource "aws_key_pair" "new_key" {
  key_name   = "prek-key"
  public_key = tls_private_key.key.public_key_openssh
}


# Create an EC2 instance and associate the key pair
resource "aws_instance" "app_server" {
  ami           = "ami-0e9838a60927b7876"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.new_key.key_name
  vpc_security_group_ids = [aws_security_group.fedora.id]
  associate_public_ip_address = true
  tags = {
    Name = "ExampleFedoraInstance"
  }
}

resource "aws_eip" "fedora-eip" {
  instance = aws_instance.app_server.id
  vpc      = true
}

# Create an EBS volume with KMS encryption
resource "aws_ebs_volume" "example" {
  availability_zone = aws_instance.app_server.availability_zone
  size              = 10 
  encrypted         = true
  kms_key_id        = "arn:aws:kms:us-east-2:753148611660:key/663a1209-447f-4031-880e-4fcd1bcfb5a4"
}

# Attach the EBS volume to the EC2 instance
resource "aws_volume_attachment" "example" {
  device_name = "/dev/sdf"  
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.app_server.id
}

