provider "aws" {
  region = "ap-south-1"  # Choose the appropriate region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"  # Choose the appropriate AZ
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"  # Choose the appropriate AZ
}

resource "aws_security_group" "public_sg" {
  name_prefix = "public-sg-"

  // Inbound rule to allow incoming SSH and HTTP traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance_1" {
  ami           = "ami-06f621d90fa29f6d0"  # Specify a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.public_sg.id]
  key_name      = "my" 
}



resource "aws_instance" "ec2_instance_2" {
  ami           = "ami-06f621d90fa29f6d0"  # Specify a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_2.id
  security_groups = [aws_security_group.public_sg.id]
  key_name      = "my"  # Replace with your actual key pair name
}
resource "aws_security_group" "elb_sg" {
  name_prefix = "elb-sg-"

  // Inbound rule to allow incoming HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "my_lc" {
  name_prefix   = "my-lc-"
  image_id      = "ami-06f621d90fa29f6d0"  # Specify a valid AMI ID
  instance_type = "t2.micro"
  security_groups = [aws_security_group.public_sg.name]
}

resource "aws_autoscaling_group" "my_asg" {
  name_prefix           = "my-asg-"
  launch_configuration = aws_launch_configuration.my_lc.name
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.my_elb.name]
  vpc_zone_identifier  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_elb" "my_elb" {
  name               = "my-elb"
  security_groups   = [aws_security_group.elb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

