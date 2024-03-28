provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "wazuh_server" {
    ami = "ami-080e1f13689e07408"
    instance_type = "t2.medium"
    availability_zone = "us-east-1c"
    key_name = "easter-terraform-aws-key"
    
    network_interface {
        device_index = 0 #meaning the 'web-server-nic' will be the 1st one(kinda like the primary NIC)
        network_interface_id = aws_network_interface.web-server-nic.id #have to specify the id of the NIC
    }

    tags = {
        Name = "wazuh_server&index"
    }

}

resource "aws_instance" "wazuh_client" {
    ami = "ami-080e1f13689e07408"
    instance_type = "t2.micro"
    availability_zone = "us-east-1c"
    #key_name = "easter-terraform-aws-key"
    
    network_interface {
        device_index = 0 #meaning the 'web-server-nic' will be the 1st one(kinda like the primary NIC)
        network_interface_id = aws_network_interface.web-client-nic.id #have to specify the id of the NIC
    }

    tags = {
        Name = "wazuh_client"
    }

}

resource "aws_ebs_volume" "wazuh_vol_server1" {
  availability_zone = "us-east-1c"
  size              = 30
  type              = "gp2"

  tags = {
    Name = "wazuh_vol_server1"
  }
}

resource "aws_volume_attachment" "wazuh_volinst_assoc" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.wazuh_vol_server1.id
  instance_id = aws_instance.wazuh_server.id
}

resource "aws_ebs_volume" "wazuh_vol_client1" {
  availability_zone = "us-east-1c"
  size              = 30
  type              = "gp2"

  tags = {
    Name = "wazuh_vol_client1"
  }
}

resource "aws_volume_attachment" "wazuh_volinst_assoc" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.wazuh_vol_client1.id
  instance_id = aws_instance.wazuh_client.id
}

resource "aws_vpc" "wazuh_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "wazuh_vpc"
    }
}

resource "aws_subnet" "wazuh_subnet" {
    cidr_block = "10.0.0.0/24"
    vpc_id    = aws_vpc.wazuh_vpc.id
    availability_zone = "us-east-1c"
    tags = {
        Name = "wazuh_subnet"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.wazuh_vpc.id

    tags = {
        Name = "wazuh_gateway"
    }
}

# # Default route to the internet
resource "aws_route_table" "wazuh-routing-table" {
    vpc_id = aws_vpc.wazuh_vpc.id

    #default ipv4 route, so all traffic goes through here
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
    #default ipv6 route, so all traffic goes through here
    route {
        ipv6_cidr_block  = "::/0"
        gateway_id       = aws_internet_gateway.gw.id
    }

    tags = {
        Name = "wazuh-routing-table"
    }
}

# # Association of route table & subnet
resource "aws_route_table_association" "wazuh-association" {
    subnet_id = aws_subnet.wazuh_subnet.id
    route_table_id = aws_route_table.wazuh-routing-table.id
}

resource "aws_security_group" "allow-home-traffic" {
    name = "allow-home-traffic"
    description = "my wazuh security group"
    vpc_id = aws_vpc.wazuh_vpc.id #association to the vpc

    ingress {
        description = "HTTPS"
        from_port = 443 # only ingress traffic to port 443 is allowed
        to_port = 443   # I could use from_port = 443, to_port = 500 to allow traffic from ports 443 to 500
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # every ip can access the https server | i could specify the rfc1918 blocks as well or my cidr_block in the vpc
    }

    ingress {
        description = "HTTP"
        from_port = 80 # only ingress traffic to port 80 is allowed
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = 22 # only ingress traffic to port 22 is allowed
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" # == any protocol | So putting '0' on the ports doesn't matter, as every port is allowed anyways
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow HTTP(S) and SSH"
    }
}

resource "aws_network_interface" "web-server-nic" {
    subnet_id = aws_subnet.wazuh_subnet.id
    private_ips = ["10.0.0.50"]
    security_groups = [aws_security_group.allow-home-traffic.id]
}

resource "aws_eip" "wazuh-server-eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.0.50" #has to be the same as in the aws_network_interface
  depends_on = [aws_internet_gateway.gw] #here we reference the whole object and not just the ID

  tags = {
    Name = "wazuh-server-eip"
  }
}

resource "aws_network_interface" "web-client-nic" {
    subnet_id = aws_subnet.wazuh_subnet.id
    private_ips = ["10.0.0.51"]
    security_groups = [aws_security_group.allow-home-traffic.id]
}

resource "aws_eip" "wazuh-client-eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-client-nic.id
  associate_with_private_ip = "10.0.0.51" #has to be the same as in the aws_network_interface
  depends_on = [aws_internet_gateway.gw] #here we reference the whole object and not just the ID

  tags = {
    Name = "wazuh-client-eip"
  }
}