provider "aws" {
  region = "us-east-2"  
}

resource "aws_vpc" "setup_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "setup-vpc"
  }
}

resource "aws_internet_gateway" "setup_igw" {
  vpc_id = aws_vpc.setup_vpc.id
  tags = {
    Name = "setup-internet-gateway"
  }
}

resource "aws_route_table" "setup_route_table" {
  vpc_id = aws_vpc.setup_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.setup_igw.id
  }

  tags = {
    Name = "setup-route-table"
  }
}

resource "aws_route_table_association" "setup_route_table_assoc" {
  subnet_id      = aws_subnet.setup_public_subnet.id
  route_table_id = aws_route_table.setup_route_table.id
}

resource "aws_subnet" "setup_public_subnet" {
  vpc_id                  = aws_vpc.setup_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"  
  tags = {
    Name = "setup-public-subnet"
  }
}

resource "aws_security_group" "setup_sg" {
  vpc_id = aws_vpc.setup_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to all for SSH
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to all for HTTP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = {
    Name = "setup-security-group"
  }
}

resource "aws_key_pair" "setup_key_pair" {
  key_name   = "setup-key-pair"
  public_key = file("./keys/Public_Key")
}

data "aws_ami" "setup_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's AWS Account ID

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-*"]
  }
}

resource "aws_instance" "setup_ec2_instance" {
  ami           = data.aws_ami.setup_ubuntu.id
  instance_type = "t2.micro"               # Change to your desired instance type

  subnet_id                  = aws_subnet.setup_public_subnet.id
  security_groups            = [aws_security_group.setup_sg.id]
  associate_public_ip_address = true

  key_name = aws_key_pair.setup_key_pair.key_name

  user_data = file("./scripts/userdata.sh")

  tags = {
    Name = "setup-ec2-instance"
  }
}

output "setup_ec2_public_ip" {
  value = aws_instance.setup_ec2_instance.public_ip
  description = "The public IP address of the EC2 instance"
}