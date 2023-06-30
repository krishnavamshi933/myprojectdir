# Define AWS provider
provider "aws" {
  region = "us-east-1"  # Set your desired AWS region
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# Create Subnets
resource "aws_subnet" "dev_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  # Set your desired availability zone
  tags = {
    Name = "dev-subnet"
  }
}

resource "aws_subnet" "prod_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"  # Set your desired availability zone
  tags = {
    Name = "prod-subnet"
  }
}

resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"  # Set your desired availability zone
  tags = {
    Name = "test-subnet"
  }
}

# Create Security Group for EC2 instances
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# Create Route Table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-route-table"
  }
}

# Create Route to Internet Gateway
resource "aws_route" "route_to_igw" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "dev_subnet_association" {
  subnet_id      = aws_subnet.dev_subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "prod_subnet_association" {
  subnet_id      = aws_subnet.prod_subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "test_subnet_association" {
  subnet_id      = aws_subnet.test_subnet.id
  route_table_id = aws_route_table.route_table.id
}

# Create RDS instance for PostgreSQL database
resource "aws_db_instance" "db_instance" {
  engine               = "postgres"
  instance_class       = "db.t2.micro"  # Set your desired instance type
  allocated_storage    = 20
  storage_type         = "gp2"
  identifier           = "my-database"
  name                 = "my_database"
  username             = "db_username"  # Set your desired database username
  password             = "db_password"  # Set your desired database password
  publicly_accessible = false
  multi_az             = false
  db_subnet_group_name = "default"

  tags = {
    Name = "db-instance"
  }
}

# Create EC2 instances for Django application in dev environment
resource "aws_instance" "dev_instance" {
  ami           = "ami-024e6efaf93d85776"  # Set your desired AMI ID
  instance_type = "t2.micro"  # Set your desired instance type
  key_name      = "krishnavamshi"  # Set your desired key pair name

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.dev_subnet.id

  tags = {
    Name = "dev-instance"
  }
}

# Create EC2 instances for Django application in prod environment
resource "aws_instance" "prod_instance" {
  ami           = "ami-024e6efaf93d85776"  # Set your desired AMI ID
  instance_type = "t2.micro"  # Set your desired instance type
  key_name      = "krishnavamshi"  # Set your desired key pair name

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.prod_subnet.id

  tags = {
    Name = "prod-instance"
  }
}

# Create EC2 instances for Django application in test environment
resource "aws_instance" "test_instance" {
  ami           = "ami-024e6efaf93d85776"  # Set your desired AMI ID
  instance_type = "t2.micro"  # Set your desired instance type
  key_name      = "krishnavamshi"  # Set your desired key pair name

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.test_subnet.id

  tags = {
    Name = "test-instance"
  }
}

# Create Application Load Balancer
resource "aws_lb" "alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.dev_subnet.id, aws_subnet.prod_subnet.id, aws_subnet.test_subnet.id]
}

# Create ALB Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Create ALB Target Group
resource "aws_lb_target_group" "target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
  }
}

# Register EC2 instances with the ALB Target Group
resource "aws_lb_target_group_attachment" "dev_attachment" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.dev_instance.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "prod_attachment" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.prod_instance.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "test_attachment" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.test_instance.id
  port             = 80
}
