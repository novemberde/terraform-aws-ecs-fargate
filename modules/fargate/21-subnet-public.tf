# subnet public

resource "aws_subnet" "public" {
  count = "${var.az_count}"

  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 8, 20 + count.index)}"

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  map_public_ip_on_launch = true

  tags = "${
    map(
     "Name", "tf-ecs-${var.name}-${var.stage}-public",
    )
  }"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = "${
    map(
     "Name", "tf-ecs-${var.name}-${var.stage}",
    )
  }"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_eip" "gw" {
  count      = "${var.az_count}"
  vpc        = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "gw" {
  count         = "${var.az_count}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.gw.*.id, count.index)}"
}
