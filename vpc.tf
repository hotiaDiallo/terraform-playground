provider "aws" {
    region = "eu-west-3"
}

variable vpc_cidr_block {}
variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}

data "aws_availability_zones" "available" {}


module "myapp-vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "3.18.0"

    name = "myapp-vpc"
    cidr = var.vpc_cidr_block

    #azs = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
    private_subnets = var.private_subnet_cidr_blocks
    public_subnets = var.public_subnet_cidr_blocks
    azs = data.aws_availability_zones.available.names 


    enable_nat_gateway = true # only for transparency (enable by default)
    # All private subnets will route their internet traffic through the single NAT
    single_nat_gateway = true
    enable_dns_hostnames = true

    tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    }

    public_subnet_tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
        "kubernetes.io/role/elb" = 1 
    }

    private_subnet_tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
        "kubernetes.io/role/internal-elb" = 1 
    }
}