# This creates private network "box"
resource "aws_vpc" "techcorp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "techcorp-vpc"
  }
}

# Public Subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "techcorp-public-subnet-1" }
}

# Public Subnet 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "techcorp-public-subnet-2" }
}

# Private Subnet 1
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "techcorp-private-subnet-1" }
}

# Private Subnet 2
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "techcorp-private-subnet-2" }
}

# 1. The Front Door (Internet Gateway)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techcorp_vpc.id

  tags = { Name = "techcorp-igw" }
}

# 2. The GPS (Public Route Table)
# This tells traffic: "If you want to go to the internet, go through the IGW"
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "techcorp-public-rt" }
}

# 3. Connect the GPS to Public Subnet 1
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

# 4. Connect the GPS to Public Subnet 2
resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 1. We need a "Static IP" for the NAT Gateway (Elastic IP)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "techcorp-nat-eip" }
}

# 2. Create the NAT Gateway (must sit in a PUBLIC subnet)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = { Name = "techcorp-nat-gw" }

  # To ensure proper ordering, it's good to wait for the Internet Gateway
  depends_on = [aws_internet_gateway.igw]
}

# 3. Create a Private Route Table (The Private GPS)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = { Name = "techcorp-private-rt" }
}

# 4. Connect Private Subnet 1 to the Private GPS
resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

# 5. Connect Private Subnet 2 to the Private GPS
resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

# 1. Web Security Group (The Public Face)
resource "aws_security_group" "web_sg" {
  name        = "techcorp-web-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.techcorp_vpc.id

  # Allow HTTP (Port 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS (Port 443) from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Let the server talk to the internet (to download updates)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-web-sg" }
}

# 2. Database Security Group (The Vault)
resource "aws_security_group" "db_sg" {
  name        = "techcorp-db-sg"
  description = "Allow Postgres traffic from Web SG"
  vpc_id      = aws_vpc.techcorp_vpc.id

  # Allow Postgres (Port 5432) ONLY from the Web Security Group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-db-sg" }
}

# 3. Bastion Security Group (The Security Gate)
resource "aws_security_group" "bastion_sg" {
  name        = "techcorp-bastion-sg"
  description = "Allow SSH from my IP only"
  vpc_id      = aws_vpc.techcorp_vpc.id

  # Allow SSH (Port 22) ONLY from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["102.89.46.20/32"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-bastion-sg" }
}

# 4. Update Web SG to allow SSH from the Bastion
resource "aws_security_group_rule" "allow_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

# 1. Bastion Host (In Public Subnet)
resource "aws_instance" "bastion" {
  ami           = "ami-0c101f26f147fa7fd" # Amazon Linux 2 AMI for us-east-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_1.id
  key_name      = "techcorp-key" # Must match the name you created in AWS
  
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = { Name = "techcorp-bastion" }
}

# 2. Web Server 1 (In Private Subnet 1)
resource "aws_instance" "web_1" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_1.id
  key_name      = "techcorp-key"
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("user_data/web_server_setup.sh")

  tags = { Name = "techcorp-web-1" }
}

# 3. Web Server 2 (In Private Subnet 2)
resource "aws_instance" "web_2" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_2.id
  key_name      = "techcorp-key"
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("user_data/web_server_setup.sh")

  tags = { Name = "techcorp-web-2" }
}

# 4. Database Server (In Private Subnet 1)
resource "aws_instance" "db_server" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t3.small" # TechCorp requested t3.small for the DB
  subnet_id     = aws_subnet.private_1.id
  key_name      = "techcorp-key"
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  user_data              = file("user_data/db_server_setup.sh")

  tags = { Name = "techcorp-db" }
}


# 1. The Load Balancer (The Traffic Cop)
resource "aws_lb" "web_alb" {
  name               = "techcorp-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "techcorp-web-alb" }
}

# 2. The Target Group (The list of servers the cop points to)
resource "aws_lb_target_group" "web_tg" {
  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp_vpc.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

# 3. The Listener (Listening for people clicking your link)
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 4. Attach Web Server 1 to the Cop
resource "aws_lb_target_group_attachment" "web_1_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

# 5. Attach Web Server 2 to the Cop
resource "aws_lb_target_group_attachment" "web_2_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}
