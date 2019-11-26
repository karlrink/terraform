

variable "key_pair_name" {
  default = "test-sspr SSH Keys"
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
  default     = "test-sspr"
}

variable "security_group_name" {
  default     = "test-sspr-security-group"
}

variable "vpc_name" {
  default     = "test-sspr-vpc"
}



