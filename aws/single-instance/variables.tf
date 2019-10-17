
variable "key_pair_name" {
  default = "SSH Keys"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "aws_region" {
  default     = "us-west-1"
}

variable "aws_ami" {
  default = {
    # ami-00fc224d9834053d6, Red Hat Enterprise Linux version 8
    us-west-1 = "ami-00fc224d9834053d6"
  }
}

variable "instance_size" {
  default     = "t2.micro"
}

variable "instance_name" {
  default     = "single-instance"
}

variable "security_group_name" {
  default     = "single-instance-security-group"
}

variable "vpc_name" {
  default     = "single-instance-vpc"
}


