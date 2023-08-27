data "aws_availability_zones" "available" {
  state = "available"
}

# Main  vpc
resource "aws_vpc" "my_vpc" {
  cidr_block       = var.VPC_CIDR_BLOCk
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "${var.ENVIRONMENT}-vpc"
  }
}
#public Subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.PUBLIC_SUBNET1_CIDR_BLOCK
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = "true"
  tags = {
    Name = "${var.ENVIRONMENT}-vpc-public-subnet-1"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.PUBLIC_SUBNET2_CIDR_BLOCK
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = "true"
  tags = {
    Name = "${var.ENVIRONMENT}-vpc-public-subnet-1"
  }
}

# Route Table for public Architecture
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "${var.ENVIRONMENT}-route-table"
  }
}

# Route Table association with public subnets
resource "aws_route_table_association" "to_public_subnet1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "instance_sg" {
  name_prefix = "instance-sg-"

  # SSH rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Additional rule for port 5000
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add more rules as needed for your application
}



provider "aws" {
  region     = var.AWS_REGION
  access_key = "AKIAXVZN56GWENRNDR6D"
  secret_key = "6lfzBzPIQlCet6ZgfsvaA2YgKTkr6oDSamk5/O2R"
}

#Output Specific to Custom VPC
output "my_vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.my_vpc.id
}



output "public_subnet1_id" {
  description = "Subnet ID"
  value       = aws_subnet.public_subnet_1.id
}

resource "aws_instance" "PerumalEC2" {
  ami           = "ami-06f621d90fa29f6d0"  # Replace with your desired AMI ID
  instance_type = "t2.micro"      # Replace with your desired instance type
  key_name = "my"
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "PerumalEC2"
  }
}

resource "aws_lb" "AppLB" {
  name               = "AppLoadbalancer"
  internal           = false
  load_balancer_type = "application"
  
    subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
  ]
  

  enable_deletion_protection = false  # Remember to adjust this based on your requirements

  enable_http2 = true  # Optional: Enable HTTP/2 support

  tags = {
    Name = "App Load Balancer"
  }
}


resource "aws_autoscaling_group" "AppASG" {
  name                 = "AppAutoScaling"
  launch_configuration = aws_launch_configuration.AppLaunchConfig.name
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1

  vpc_zone_identifier = [aws_subnet.public_subnet_1.id]  # List all public subnets
}

resource "aws_launch_configuration" "AppLaunchConfig" {
  name_prefix          = "AppLaunchConfigName"
  image_id             = "ami-06f621d90fa29f6d0"  # Replace with your desired AMI ID
  instance_type       = "t2.micro"      # Replace with your desired instance type
  security_groups     = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true   # If needed, for instances in public subnet

  lifecycle {
    create_before_destroy = true
  }
}

