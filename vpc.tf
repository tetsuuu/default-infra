resource "aws_vpc" "default-vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags {
    Name    = "${var.region}-default-vpc"
    Service = "default"
    Country = "jp"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = "${aws_vpc.default-vpc.id}"
  cidr_block              = "192.168.${count.index}.0/24"
  availability_zone       = "${element(var.availability_zone, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name    = "${var.region}-default-public-${count.index}"
    Service = "default"
    Country = "jp"
  }
}

resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = "${aws_vpc.default-vpc.id}"
  cidr_block              = "192.168.${count.index + 2}.0/24"
  availability_zone       = "${element(var.availability_zone, count.index)}"
  map_public_ip_on_launch = false

  tags {
    Name    = "${var.region}-default-private-${count.index}"
    Service = "default"
    Country = "jp"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.default-vpc.id}"

  tags {
    Name    = "${var.region}-default-igw"
    Service = "default"
    Country = "jp"
  }
}

resource "aws_eip" "public" {
  count = 2
  vpc   = true
}

resource "aws_nat_gateway" "public" {
  count         = 2
  allocation_id = "${element(aws_eip.public.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
}

resource "aws_route_table" "default-route" {
  vpc_id = "${aws_vpc.default-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Service = "default"
    Name    = "${var.region}-default-route"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default-vpc.id}"

  tags {
    Service = "default"
    Name    = "${var.region}-default-route-public"
    Country = "jp"
  }
}

resource "aws_route" "public" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = "${aws_vpc.default-vpc.id}"

  tags {
    Service = "default"
    Name    = "${var.region}-default-route-private-${count.index}"
    Country = "jp"
  }
}

resource "aws_route" "private" {
  count          = 2
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.public.*.id, count.index)}"
}

resource "aws_route_table_association" "public" {
  count          = 2
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count          = 2
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
}

resource "aws_subnet" "private_privatelink_extend" {
  count                   = "${length(var.availability_zone_privatelink_extend)}"
  vpc_id                  = "${aws_vpc.default-vpc.id}"
  cidr_block              = "192.168.${255 - length(var.availability_zone_privatelink_extend) + count.index}.0/24"
  availability_zone       = "${element(var.availability_zone_privatelink_extend, count.index)}"
  map_public_ip_on_launch = false

  tags {
    Name    = "${var.region}-default-private-privatelink-extend-${count.index}"
    Service = "default"
    Country = "jp"
  }
}

resource "aws_route_table" "private_privatelink_extend" {
  count  = "${length(var.availability_zone_privatelink_extend)}"
  vpc_id = "${aws_vpc.default-vpc.id}"

  tags {
    Service = "default"
    Name    = "${var.region}-default-route-private-privatelink-extend-${count.index}"
    Country = "GL"
  }
}

resource "aws_route" "private_privatelink_extend" {
  count          = "${length(var.availability_zone_privatelink_extend)}"
  route_table_id = "${element(aws_route_table.private_privatelink_extend.*.id, count.index)}"

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.public.*.id, count.index%length(var.availability_zone_privatelink_extend))}"
}

resource "aws_route_table_association" "private_privatelink_extend" {
  count          = "${length(var.availability_zone_privatelink_extend)}"
  route_table_id = "${element(aws_route_table.private_privatelink_extend.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.private_privatelink_extend.*.id, count.index)}"
}

resource "aws_flow_log" "vpc-flow-log" {
  depends_on           = ["aws_cloudwatch_log_group.vpc-flow-log-group", "aws_iam_role_policy_attachment.put-vpc-flow-log-policy-attach"]
  log_destination_type = "cloud-watch-logs"
  log_destination      = "${aws_cloudwatch_log_group.vpc-flow-log-group.arn}"
  iam_role_arn         = "${aws_iam_role.vpc-flow-log-role.arn}"
  vpc_id               = "${aws_vpc.default-vpc.id}"
  traffic_type         = "ALL"
}

resource "aws_cloudwatch_log_group" "vpc-flow-log-group" {
  name = "${var.region}-default-vpc-flow-log"
}

resource "aws_iam_role" "vpc-flow-log-role" {
  name = "${var.region}-default-vpc-flow-log-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "put-vpc-flow-log-policy" {
  name = "${var.region}-default-vpc-flow-log-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "put-vpc-flow-log-policy-attach" {
  depends_on = ["aws_iam_role.vpc-flow-log-role", "aws_iam_policy.put-vpc-flow-log-policy"]
  role       = "${aws_iam_role.vpc-flow-log-role.name}"
  policy_arn = "${aws_iam_policy.put-vpc-flow-log-policy.arn}"
}
