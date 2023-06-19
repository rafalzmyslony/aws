resource "aws_instance" "db_todo" {
    instance_type = "t2.micro"
    #availability_zone = "eu-central-1a"
    # r7g.medium  1 vcpu 4 ram   t2.micro, t2.large 2cpu 8 gb ram
    depends_on = [aws_subnet.public]
    ami = "ami-04e601abe3e1a910f"
    key_name      = "raf"
    vpc_security_group_ids = [
        aws_security_group.todo_app.id
    ]
    subnet_id = aws_subnet.public.id
    tags = {
        Name = "db_todo"
    }
        user_data = <<EOF
#!/bin/bash
apt-get -y update
apt -y install postgresql-14
cd /tmp # /tmp because is accesible also by postgres user otherwise error "Could not change directory to /home/root."
useradd -m -s /bin/bash todo_app_user
sudo -u postgres psql -c "CREATE ROLE todo_app_user with PASSWORD '123456';"
sudo -u postgres psql -c "CREATE DATABASE todo_app;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE my_app_db TO todo_app_user;"


EOF
}