resource "aws_instance" "vm_ansible_env" {
    instance_type = "t2.large"
    #availability_zone = "eu-central-1a"
    # r7g.medium  1 vcpu 4 ram   t2.micro, t2.large 2cpu 8 gb ram
    depends_on = [aws_subnet.private]
    ami = "ami-0557a15b87f6559cf"
    key_name      = "raf"
    vpc_security_group_ids = [
        aws_security_group.awx.id
    ]
    subnet_id = aws_subnet.public.id
    associate_public_ip_address = true
    tags = {
        Name = "vm_ansible_env"
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
apt-get -y update
apt -y install ansible
apt -y install net-tools
apt -y install python3-pip
apt -y install python3.10-venv
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
dpkg -i minikube_latest_amd64.deb
apt -y install podman
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
chmod 777 /kustomize
mv /kustomize /home/ubuntu
cat > /home/ubuntu/kustomization.yaml << EOL
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
  #   Find the latest tag here: https://github.com/ansible/awx-operator/releases
resources:
- github.com/ansible/awx-operator/config/default?ref=2.0.0
  # Set the image tags to match the git version from above
images:
- name: quay.io/ansible/awx-operator
  newTag: latest
# Specify a custom namespace in which to install AWX
namespace: awx
EOL
cat > /home/ubuntu/kustomization2.yaml << EOL
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
  #   Find the latest tag here: https://github.com/ansible/awx-operator/releases
resources:
- github.com/ansible/awx-operator/config/default?ref=2.0.0
- awx-demo.yaml
  # Set the image tags to match the git version from above
images:
- name: quay.io/ansible/awx-operator
  newTag: latest
# Specify a custom namespace in which to install AWX
namespace: awx
EOL
cat > /home/ubuntu/awx-demo.yaml << EOL
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
EOL
chmod 777 /home/ubuntu/kustomization.yaml
mkdir /home/ubuntu/files
chmod 777 /home/ubuntu/files
chmod 777 /home/ubuntu/kustomization2.yaml

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
resource "aws_security_group" "awx" {
  depends_on = [aws_vpc.main]
  vpc_id = "${aws_vpc.main.id}"
  name_prefix = "awx"
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
