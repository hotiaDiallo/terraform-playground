# Automate AWS Infrastructure 

1- Provision an EC2 instance on AWS insfrastruture 
2- Run nginx docker container on the EC2 instance 

## Architecture 
![Image](/images/archi.png)

<br>

## Steps 

### 1 - Create our own VPC and Subnet 

It's a good practice to create new components instead of using the default ones. 

Create a resource by declaring AWS as a provider, and a resource to create a VPC and one subnet (Provider blocks inform Terraform that you intend to build infrastructure within AWS and resource block will create the resource you specified, in the case the VPC.)

```
    provider "aws" {
        region = "eu-east-1"
    }

    resource "aws_vpc" "myapp-vpc" {
        cidr_block = var.vpc_cidr_block
        tags = {
            Name = "${var.env_prefix}-vpc"
        }
    }

    resource "aws_subnet" "myapp-subnet-1" {
        vpc_id = aws_vpc.myapp-vpc.id
        cidr_block = var.subnet_1_cidr_block
        availability_zone = var.avail_zone
        tags = {
            Name = "${var.env_prefix}-subnet-1"
        }
    }

```
### 2 - Create a Route table and Internet Gateway
The route table decide where the traffic will fowarded within the VPC ; When we create a VPC, a route table is created by default. 
We are going to create a new Route table and Internet Gateway fot the project 

```
    resource "aws_route_table" "myapp-route-table" {
        vpc_id = aws_vpc.myapp-vpc.id

        # default route, mapping VPC CIDR block to "local", created implicitly and cannot be specified.
        route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.myapp-igw.id
        }

        tags = {
            Name = "${var.env_prefix}-route-table"
        }
    }

    resource "aws_internet_gateway" "myapp-igw" {
        vpc_id = aws_vpc.myapp-vpc.id
        
        tags = {
            Name = "${var.env_prefix}-internet-gateway"
        }
    }
```

After creating the Route Table, we weed to associate this Route Table with the Subnet

```
    resource "aws_route_table_association" "a-rtb-subnet" {
        subnet_id      = aws_subnet.myapp-subnet-1.id
        route_table_id = aws_route_table.myapp-route-table.id
    }
```

### 3 - Create Security Group to configure firewall rules for the EC2 instance
- Port 22 to ssh onto it 
- Port 8080 for the nginx server

```
resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

```

### 4- Create EC2 Instance
- Fetch AMI : the bast practice is to fetch the ami instead of hardcoding it 

```
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

```
- Create ssh key-pair and download .pem ﬁle
```
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}
```

- Move the file to the .ssh folder and restrict permission of the file (required set) : `chmod 400 filename`

Best practice for ssh key pair is to let terraform create one

```
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}
```
- create EC2 instance

```
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    # these arguments are optional : if not set, default value are used
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    tags = {
        Name = "${var.env_prefix}-server"
    }
}
```

### 5- Conﬁgured Terraform to install Docker and run nginx image
2 options :
- ssh onto the server and run docker 
- use user-data with a script 

```
resource "aws_instance" "myapp-server" {
    # previous options 

    user_data = <<EOF
        #!/bin/bash
        sudo yum update -y && sudo yum install -y docker
        sudo systemctl start docker 
        sudo usermod -aG docker ec2-user
        docker run -p 8080:80 nginx
    EOF
}
```
Best practice is to use a script file 

```
resource "aws_instance" "myapp-server" {
    # previous options 

    user_data = file("entry-script.sh")
}
```



