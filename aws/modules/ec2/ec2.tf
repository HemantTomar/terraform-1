#---------------------------------------------------
# AWS Instance
#---------------------------------------------------
resource "aws_instance" "instance" {
  count = var.enable_instance ? 1 : 0

  ami           = lookup(var.ami, var.region)
  instance_type = var.instance_type

  availability_zone = var.availability_zone
  placement_group   = var.placement_group
  tenancy           = var.tenancy

  ebs_optimized = var.ebs_optimized

  source_dest_check = var.source_dest_check
  monitoring        = var.monitoring

  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip

  ipv6_address_count = var.ipv6_address_count
  ipv6_addresses     = var.ipv6_addresses

  vpc_security_group_ids = var.vpc_security_group_ids
  security_groups        = var.security_groups
  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_name

  user_data         = var.user_data
  user_data_base64  = var.user_data_base64
  get_password_data = var.get_password_data

  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  host_id              = var.host_id
  cpu_core_count       = var.cpu_core_count
  cpu_threads_per_core = var.cpu_threads_per_core

  dynamic "ebs_block_device" {
    iterator = ebs_block_device
    for_each = var.ebs_block_device

    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = lookup(ebs_block_device.value, "device_name", null)
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
    }
  }

  dynamic "ephemeral_block_device" {
    iterator = ephemeral_block_device
    for_each = var.ephemeral_block_device

    content {
      device_name  = ephemeral_block_device.value.device_name
      virtual_name = ephemeral_block_device.value.virtual_name
    }
  }

  dynamic "root_block_device" {
    iterator = root_block_device
    for_each = var.root_block_device

    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
    }
  }

  dynamic "network_interface" {
    iterator = network_interface
    for_each = var.network_interface

    content {
      device_index          = lookup(network_interface.value, "device_index", null)
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = lookup(network_interface.value, "delete_on_termination", null)
    }
  }

  volume_tags = merge(
    {
      "Name" = var.instance_name != "" ? var.instance_name : "${lower(var.name)}-ec2-${lower(var.environment)}"
    },
    var.volume_tags
  )

  dynamic "timeouts" {
    iterator = timeouts
    for_each = var.instance_timeouts

    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  tags = merge(
    {
      Name = var.instance_name != "" ? var.instance_name : "${lower(var.name)}-ec2-${lower(var.environment)}"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = []
}
