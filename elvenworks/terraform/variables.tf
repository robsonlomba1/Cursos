variable "region" {
  default =  "us-east-2"
  }

variable "name_security_group_web" {
  default = "robson-project-web"
}

variable "name_robson-project-db" {
  default = "robson-project-db"
}

variable "name_robson-project-sessoes" {
  default = "robson-project-sessoes"
}

variable "name_robson-project-alb" {
  default = "robson-project-alb"
}

variable "vpc_id" {
  default = "vpc-04b0e6cbb6efbafa3"
}

variable "ami_aws_instance" {
  default = "ami-02f3416038bdb17fb"
}

variable "type_aws_instance" {
  default = "t3.micro"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-2a","us-east-2b"]
}

variable "subnet_id_aws_instance" {
  type    = list(string)
  default = ["subnet-06a2288581eb2a944","subnet-0fa9d811cd009de14"]
  #us-east-2a e 2b
}

variable "key_aws_instance" {
  default = "robsonlomba-projects"
}
