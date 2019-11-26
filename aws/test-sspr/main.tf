
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
    from_port   = 8080
    to_port     = 8080
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

  provisioner "file" {
    source      = "./files/sspr-4.4.zip"
    destination = "/tmp/sspr-4.4.zip"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y unzip",
      "unzip /tmp/sspr-4.4.zip -d /home/ec2-user/",
      "sudo yum install -y java-11-openjdk",
      "curl -k https://www-us.apache.org/dist/tomcat/tomcat-9/v9.0.29/bin/apache-tomcat-9.0.29.zip >/home/ec2-user/apache-tomcat-9.0.29.zip",
      "for i in 5 4;do echo $i && sleep 1;done",
      "unzip /home/ec2-user/apache-tomcat-9.0.29.zip -d /home/ec2-user/",
      "chmod +x /home/ec2-user/apache-tomcat-9.0.29/bin/startup.sh",
      "chmod +x /home/ec2-user/apache-tomcat-9.0.29/bin/catalina.sh",
      "cp /home/ec2-user/sspr.war /home/ec2-user/apache-tomcat-9.0.29/webapps/",
      "for i in 8 7 6 5 4 3 2 1;do echo $i && sleep 1;done",
      "SSPR_APPLICATIONPATH=/home/ec2-user /home/ec2-user/apache-tomcat-9.0.29/bin/startup.sh",
    ]
  }
}


