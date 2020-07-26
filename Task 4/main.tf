provider "aws" {
     region = "ap-south-1"
     profile = "default"
 }

resource "aws_vpc" "vpcshnd" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "my-vpc"
  }
} 

resource "aws_subnet" "sub_1a" {
  vpc_id     = aws_vpc.vpcshnd.id
  availability_zone= "ap-south-1a"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch ="true"

  tags = {
    Name = "mylab-1a"
  }
}

resource "aws_subnet" "sub_1b" {
  vpc_id     = aws_vpc.vpcshnd.id
  cidr_block = "192.168.1.0/24"
  availability_zone= "ap-south-1b"

  tags = {
    Name = "mylab-1b"
  }
}


resource "aws_internet_gateway" "myinternetGW" {
  vpc_id = aws_vpc.vpcshnd.id
   
   tags = {
      Name = "myinternetGW"
   }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpcshnd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myinternetGW.id
  }

  tags = {
    Name = "myroute_table"
  }
}

resource "aws_route_table_association" "route_ta" {
    subnet_id      = aws_subnet.sub_1a.id
    route_table_id = aws_route_table.rt.id
}


//nat gateway

resource "aws_eip" "shnd_eip" {
  depends_on = [ aws_internet_gateway.myinternetGW ]
  vpc      = true
}


resource "aws_nat_gateway" "shnd_ng" {
  allocation_id = "${aws_eip.shnd_eip.id}"
  subnet_id     = "${aws_subnet.sub_1a.id}"
   depends_on = [ aws_internet_gateway.myinternetGW ]

  tags = {
    Name = "shnd_ng"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.vpcshnd.id}"

  route {
    cidr_block = "0.0.0.0/24"
    gateway_id = "${aws_nat_gateway.shnd_ng.id}"
  }

 tags = {
    Name = "r"
  }
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sub_1b.id
  route_table_id = aws_route_table.r.id
  depends_on = [aws_route_table.r]
}


resource "aws_security_group" "wpSG"{
   name            = "wp_SG"
   description     = " Allows 22 and http"
   vpc_id          = aws_vpc.vpcshnd.id
 
    ingress {
        description = "FOR_HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }

   ingress {
        description = "FOR_SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]

    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks =["0.0.0.0/0"]
        }
    
        tags = {
        Name = "allow_SSH_HTTP"
   }
}

resource "aws_security_group" "mysqlSG"{
   name            = "sql_SG"
   description     = " Allows SSH_HTTP_MYSQL"
   vpc_id          = aws_vpc.vpcshnd.id
 
    

   ingress {
        description = "FOR_SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }
    

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks =["0.0.0.0/0"]
        }
    
      tags = {
        Name = "allow_MYSQL"
   }
}

resource "aws_instance" "instance_wp" {
   ami          = "ami-7e257211"
   instance_type= "t2.micro"
   key_name     = "Mainkey"
   vpc_security_group_ids = [aws_security_group.wpSG.id]
   subnet_id    = aws_subnet.sub_1a.id
   
      tags ={
          Name = "Wordpress"
     }
}


resource "aws_instance" "instance_mysql" {
   ami          = "ami-08706cb5f68222d09"
   instance_type= "t2.micro"
   key_name     = "Mainkey"
   vpc_security_group_ids = [aws_security_group.mysqlSG.id]
   subnet_id    = aws_subnet.sub_1b.id
   
      tags ={
          Name = "Mysql"
     }
}

