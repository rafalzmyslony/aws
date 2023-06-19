output "ID_IGW"{
    description = "ID of IGW"
    value = aws_internet_gateway.project1_igw.id
}
output "IP_EC2"{
    description = "IP of EC2"
    value = aws_instance.vm_ansible_env.public_ip
}
output "IP_EC2_DB"{
    description = "IP of EC2 - db_todo"
    value = aws_instance.db_todo.private_ip
}
