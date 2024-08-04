data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
  owners = ["099720109477"]
}

resource "aws_key_pair" "mykey" {
    key_name = "aws-key"
    public_key = file(var.public_key)
}
resource "aws_instance" "my-instance1" {
  instance_type = "t2.micro"
  ami = data.aws_ami.ubuntu.id
  key_name = aws_key_pair.mykey.key_name
  vpc_security_group_ids = [aws_security_group.mysg.id]

  tags = {
    Name = "master"
  }

  user_data = templatefile("${path.root}/${path.module}/script/master.tftpl",
  {
  instance = "master",
  master_private_ip = "", #aws_eip.myeip_master.public_ip,
  minion-index = null
  }
  )
}

data "aws_instance" "master_instance" {
  instance_id = aws_instance.my-instance1.id
  depends_on  = [aws_instance.my-instance1]
}

output "master_private_ip" {
  value = aws_instance.my-instance1.private_ip
}

resource "aws_instance" "my-instance2" {
  count = var.instance_minion_count
  instance_type = "t2.micro"
  ami = data.aws_ami.ubuntu.id
  key_name = aws_key_pair.mykey.key_name
  vpc_security_group_ids = [aws_security_group.mysg.id]

  tags = {
    Name = "minion-${count.index+1}"
  }
  
  user_data = templatefile("${path.root}/${path.module}/script/master.tftpl",
  {
      instance = "minion",
      master_private_ip = data.aws_instance.master_instance.private_ip, #aws_eip.myeip_master.public_ip,
      minion-index = count.index + 1
  }
  )
  depends_on = [ 
    aws_instance.my-instance1 
    ]
}

# resource "aws_eip" "myeip_master" {
#   domain = "vpc"
# }

# resource "aws_eip_association" "myeip_asscociation" {
#   instance_id = aws_instance.my-instance1.id
#   allocation_id = aws_eip.myeip_master.id
# }

resource "null_resource" "wait_for_bootstrap_to_finish" {
  provisioner "local-exec" {
    command = <<-EOF
    while true; do
      if ssh -q -i ${var.private-key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.my-instance1.public_ip} [[ -f /home/ubuntu/done ]]; then
        echo "Bootstrap completed in the Master"
        break
      else
        echo "Waiting for bootstrap completion in the Master"
        sleep 5
        continue
      fi
    done
    
    %{for worker_public_ip in aws_instance.my-instance2[*].public_ip~}
      while true; do
      if ssh -q -i ${var.private-key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${worker_public_ip} [[ -f /home/ubuntu/done ]]; then
        echo "Bootstrap completed in the Minion: ${worker_public_ip}"
        break
      else
        echo "Waiting for bootstrap completion in the Minion: ${worker_public_ip}"
        sleep 5
        continue
      fi
      done
    %{endfor~}

    ssh -q -i ${var.private-key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.my-instance1.public_ip} sudo salt-key -A -y
    EOF
  }
  triggers = {
    instance_ids = join(",", concat([aws_instance.my-instance1.id], aws_instance.my-instance2[*].id))
  }
}

# resource "null_resource" "accept_keys" {
#   provisioner "local-exec" {
#     command = <<-EOF

#     ssh -q -i ${var.private-key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.my-instance1.public_ip} sudo salt-key -A -y
#     EOF
#   }
#   depends_on = [aws_instance.my-instance1, aws_instance.my-instance2]
# }
