resource "aws_instance" "bastion" {
  ami                         = "ami-00be8970e4c841b29"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.ecs-public-subnet1.id
  availability_zone           = "us-west-2a"
  instance_type               = "t4g.nano"
  depends_on = [
    aws_security_group.koel-sg
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }
  key_name  = "awsbastion"
  user_data = <<EOF
#!/bin/bash
cd /tmp
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
  EOF
  tags = {
    Name = "bastion"
  }
  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}
