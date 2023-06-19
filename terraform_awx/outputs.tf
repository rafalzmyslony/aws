output "ID_IGW"{
    description = "ID of IGW"
    value = aws_internet_gateway.project1_igw.id
}
output "ID_EC2"{
    description = "ID of EC2"
    value = aws_instance.vm_ansible_env.public_ip
}
