data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = var.item_tag
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = var.item_tag
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = var.item_tag
  }
}

resource "aws_subnet" "subnet_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true

  tags = {
    Name = var.item_tag
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.item_tag
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.item_tag
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  name        = "module11-web-sg"
  description = "Web security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = var.item_tag
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_egress" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "db_sg" {
  name        = "module11-db-sg"
  description = "DB security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = var.item_tag
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_mysql" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.web_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "template_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_a.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/install-env.sh")

  tags = {
    Name = var.item_tag
  }
}

resource "aws_ami_from_instance" "template_ami" {
  name               = var.ami_name
  source_instance_id = aws_instance.template_instance.id

  tags = {
    Name = var.item_tag_template
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "module11-lt-"
  image_id      = aws_ami_from_instance.template_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.item_tag
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name             = "module11-asg"
  min_size         = 2
  max_size         = 2
  desired_capacity = 2
  vpc_zone_identifier = [
    aws_subnet.subnet_b.id,
    aws_subnet.subnet_c.id
  ]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.item_tag
    propagate_at_launch = true
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_username_secret" {
  name                    = "module11-db-username"
  recovery_window_in_days = 0

  tags = {
    Name = var.item_tag
  }
}

resource "aws_secretsmanager_secret_version" "db_username_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_username_secret.id
  secret_string = var.db_username
}

resource "aws_secretsmanager_secret" "db_password_secret" {
  name                    = "module11-db-password"
  recovery_window_in_days = 0

  tags = {
    Name = var.item_tag
  }
}

resource "aws_secretsmanager_secret_version" "db_password_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = random_password.db_password.result
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "module11-db-subnet-group"
  subnet_ids = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id,
    aws_subnet.subnet_c.id
  ]

  tags = {
    Name = var.item_tag
  }
}

resource "aws_db_instance" "db" {
  identifier             = "module11-db-instance"
  allocated_storage      = 20
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = var.item_tag
  }
}

resource "aws_db_snapshot" "db_snapshot" {
  db_instance_identifier = aws_db_instance.db.identifier
  db_snapshot_identifier = var.db_snapshot_identifier

  tags = {
    Name = var.item_tag_template
  }

  depends_on = [aws_db_instance.db]
}
