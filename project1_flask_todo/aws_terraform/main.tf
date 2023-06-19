resource "aws_instance" "todo_app_server" {
    instance_type = "t2.large"
    #availability_zone = "eu-central-1a"
    # r7g.medium  1 vcpu 4 ram   t2.micro, t2.large 2cpu 8 gb ram
    depends_on = [aws_subnet.private, aws_instance.db_todo]
    ami = "ami-04e601abe3e1a910f"
    key_name      = "raf"
    vpc_security_group_ids = [
        aws_security_group.todo_app.id
    ]
    subnet_id = aws_subnet.public.id
    associate_public_ip_address = true
    tags = {
        Name = "todo_app_server"
    }
    root_block_device  {
      volume_size = 15
      volume_type = "gp2"
    }
    # https://github.com/kubernetes/minikube/releases/download/v1.18.1/minikube_1.18.1-0_amd64.deb
    # https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
    /*
    Code below will execute script, which install minikube and prepares kustiomization files to install AWX operator
    After login via ssh:
      minikube start
      alias kubectl="minikube kubectl --"
      kubectl apply -k .
      mv kustomization.yaml files/kustomization.yaml
      mv files/kustomization2.yaml kustomization.yaml
      kubectl apply -k .  --> which runs agains kustiomization.yaml but with added value
    
    More here: https://github.com/ansible/awx-operator
    */
    user_data = <<EOF
#!/bin/bash
cat > /home/ubuntu/ip_address.txt << EOL
IP address of second EC2 instance ${aws_instance.db_todo.private_ip}
EOL
apt-get -y update
apt -y install net-tools
apt -y install python3-pip
apt -y install python3.10-venv
useradd todo_app_user -m
cd /home/todo_app_user/
git clone -b testing https://github.com/rafalzmyslony/some_skills/

EOF
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
}

# subnet private - hosts in this subnet have access to internet gateway
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "private subnet"
  }
}
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public subnet"
  }
}
resource "aws_internet_gateway" "project1_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw_for_vpc"

  }
}
# routing table that makes: "0.0.0.0/0" goes to internet gateway
resource "aws_route_table" "project1_public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project1_igw.id
  }
}
resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.project1_public_rt.id
  subnet_id = aws_subnet.public.id
}
# creates local routing within VPC for hosts in private subnet
resource "aws_route_table" "project1_private_rt" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.project1_private_rt.id
  subnet_id = aws_subnet.private.id
}
resource "aws_security_group" "todo_app" {
  depends_on = [aws_vpc.main]
  vpc_id = "${aws_vpc.main.id}"
  name_prefix = "todo_app"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 7080
    to_port = 7080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 7080
    to_port = 7080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
