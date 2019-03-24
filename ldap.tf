resource "aws_instance" "ldap" {
    ami                         = "${var.ec2_ami}"
    ebs_optimized               = false
    instance_type               = "t3.micro"
    monitoring                  = false
    key_name                    = "${var.common_key}"
    subnet_id                   = "${aws_subnet.private.0.id}"
    vpc_security_group_ids      = ["${aws_security_group.ldap-ingress.id}"]
    associate_public_ip_address = false
    source_dest_check           = true
    disable_api_termination     = true

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 20
        delete_on_termination = true
    }

    /*provisioner "file" {
      source      = "ldap/ldap_schema.tpl"
      destination = "/etc/openldap/initldap.conf"
    }*/

    tags {
        "Service" = "default"
        "Name" = "${var.region}-ldap"
    }

    lifecycle {
        ignore_changes = [
            "user_data",
            "ami",
            "instance_type",
            "key_name",
            "root_block_device.0.volume_type",
            "subnet_id",
            "vpc_security_group_ids",
            "ebs_optimized"
        ]
    }
}

resource "aws_security_group" "ldap-ingress" {
    name        = "ldap-ingress"
    description = "Ldap Security Group"
    vpc_id      = "${aws_vpc.default-vpc.id}"

    ingress {
        from_port       = 389
        to_port         = 389
        protocol        = "tcp"
        cidr_blocks     = ["${aws_vpc.default-vpc.cidr_block}"]
    }


    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags {
        "Name" = "ldap-ingress"
        "Service" = "default"
    }
}
