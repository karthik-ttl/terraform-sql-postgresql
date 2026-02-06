provider "aws" {
  region = var.region
}

# -------------------------------------------------
# Ubuntu 24.04 LTS AMI (Canonical via SSM)
# -------------------------------------------------
data "aws_ssm_parameter" "ubuntu_24_04_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# -------------------------------------------------
# Fetch subnet from required VPC
# -------------------------------------------------
data "aws_subnets" "target_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# ---------------- IAM FOR SSM (EC2 LOGIN) ----------------
resource "aws_iam_role" "ssm_role" {
  name = "postgres17-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  role = aws_iam_role.ssm_role.name
}

# ---------------- SECURITY GROUP ----------------
resource "aws_security_group" "postgres_sg" {
  name   = "postgres17-public-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- EC2 INSTANCE ----------------
resource "aws_instance" "postgres" {
  ami                    = data.aws_ssm_parameter.ubuntu_24_04_ami.value
  instance_type          = "t3.small"
  subnet_id              = data.aws_subnets.target_vpc_subnets.ids[0]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]

  associate_public_ip_address = true
  user_data                   = file("userdata.sh")

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = false
  }

  tags = {
    Name = "postgres17-db"
  }
}
