resource "aws_security_group" "mysg" {
  name = "mysg-server"
  description = "It will allow to communicate"

  tags = {
    name = "sg-1"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = "22"
  ip_protocol = "tcp"
  to_port = "22"
}

resource "aws_vpc_security_group_ingress_rule" "comm1" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = "4505"
  ip_protocol = "tcp"
  to_port = "4505"
}

resource "aws_vpc_security_group_ingress_rule" "comm2" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = "4506"
  ip_protocol = "tcp"
  to_port = "4506"
}

resource "aws_vpc_security_group_egress_rule" "comm4" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}