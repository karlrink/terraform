
# Cloud provider, Amazon
provider "aws" {
  region = "${var.aws_region}"
}

# SSH key access
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_pair_name}"
  public_key = "${file(var.public_key_path)}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Default security group for access
resource "aws_security_group" "default" {
  name        = "${var.security_group_name}"
  vpc_id      = "${aws_vpc.default.id}"

  tags = {
    Name = "${var.security_group_name}"
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VAULT access from anywhere
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Amazon machine image instance
resource "aws_instance" "default" {
  instance_type = "${var.instance_size}"
  ami = "${lookup(var.aws_ami, var.aws_region)}"

  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The connection will use SSH authentication.
    type = "ssh"
    user = "ec2-user"
    host = "${self.public_ip}"
    private_key = "${file(var.private_key_path)}"
  }

  tags = {
    Name = "${var.instance_name}"
  }

  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  subnet_id = "${aws_subnet.default.id}"

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y unzip",
      "curl -k https://releases.hashicorp.com/vault/1.2.3/vault_1.2.3_linux_amd64.zip >/tmp/vault_1.2.3_linux_amd64.zip",
      "unzip /tmp/vault_1.2.3_linux_amd64.zip -d /home/ec2-user/",
      "for i in 5 4;do echo $i && sleep 1;done",
      "/home/ec2-user/vault server -dev -dev-listen-address=0.0.0.0:8200 >>/home/ec2-user/vault.log 2>&1 &",
      "for i in 3 2 1;do echo $i && sleep 1;done",
      "head -50 /home/ec2-user/vault.log | grep '^Unseal Key: '",
      "head -50 /home/ec2-user/vault.log | grep '^Root Token: '",
    ]
  }
}


