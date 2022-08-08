# Work with NETWORK via terraform

A terraform module for making NETWORK.


## Usage
----------------------
Import the module and retrieve with ```terraform get``` or ```terraform get --update```. Adding a module resource to your template, e.g. `main.tf`:

```
#
# MAINTAINER Vitaliy Natarov "vitaliy.natarov@yahoo.com"
#

terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.1.0"
    }
  }
}

provider "azurerm" {
  # The AzureRM Provider supports authenticating using via the Azure CLI, a Managed Identity
  # and a Service Principal. More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure

  # The features block allows changing the behaviour of the Azure Provider, more
  # information can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
  features {}

  // subscription_id = ""
  // tenant_id       = ""
}

module "base_resource_group" {
  source = "../../modules/base"

  enable_resource_group   = true
  resource_group_name     = "res-group"
  resource_group_location = "West Europe"

  tags = tomap({
    "Environment"   = "test",
    "Createdby"     = "Vitaliy Natarov",
    "Orchestration" = "Terraform"
  })
}

module "network_sg" {
  source = "../../modules/network"

  // Enable Network SG
  enable_network_security_group              = true
  network_security_group_name                = "my-sg"
  network_security_group_location            = module.base_resource_group.resource_group_location
  network_security_group_resource_group_name = module.base_resource_group.resource_group_name

  network_security_group_security_rule = [
    {
      name      = "test123"
      protocol  = "Tcp"
      access    = "Allow"
      priority  = 100
      direction = "Inbound"


      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]


  tags = tomap({
    "Environment"   = "test",
    "Createdby"     = "Vitaliy Natarov",
    "Orchestration" = "Terraform"
  })

  depends_on = [
    module.base_resource_group
  ]
}

module "virtual_network" {
  source = "../../modules/network"

  // Enable virtual network
  enable_virtual_network              = true
  virtual_network_name                = "my-virtual-network"
  virtual_network_location            = module.base_resource_group.resource_group_location
  virtual_network_resource_group_name = module.base_resource_group.resource_group_name

  virtual_network_dns_servers   = []
  virtual_network_address_space = ["10.0.0.0/16"]
  virtual_network_subnet = [
    {
      # name           = 
      address_prefix = "10.0.1.0/24"
      security_group = module.network_sg.network_security_group_id
    },
    {
      address_prefix = "10.0.2.0/24"
    },
    {
      name           = "temp"
      address_prefix = "10.0.3.0/24"
    }
  ]

  tags = tomap({
    "Environment"   = "test",
    "Createdby"     = "Vitaliy Natarov",
    "Orchestration" = "Terraform"
  })

  depends_on = [
    module.base_resource_group,
    module.network_sg
  ]
}

module "subnet" {
  source = "../../modules/network"

  // Enable subnet
  enable_subnet               = true
  subnet_name                 = "my-subnet"
  subnet_resource_group_name  = module.base_resource_group.resource_group_name
  subnet_virtual_network_name = module.virtual_network.virtual_network_id
  subnet_address_prefixes     = ["10.0.4.0/24"]

  tags = tomap({
    "Environment"   = "test",
    "Createdby"     = "Vitaliy Natarov",
    "Orchestration" = "Terraform"
  })

  depends_on = [
    module.base_resource_group,
    module.virtual_network
  ]
}

module "public_ip" {
  source = "../../modules/network"

  // Enable Network SG
  enable_public_ip              = true
  public_ip_name                = "my-public-ip"
  public_ip_location            = module.base_resource_group.resource_group_location
  public_ip_resource_group_name = module.base_resource_group.resource_group_name
  public_ip_allocation_method   = "Static"

  public_ip_ip_version = "IPv4"
  public_ip_sku        = null
  public_ip_sku_tier   = null

  public_ip_ip_tags = tomap({
    "Environment"   = "test",
    "Createdby"     = "Vitaliy Natarov",
    "Orchestration" = "Terraform"
  })

  tags = tomap({
    "Environment"   = "test",
    "Createdby"     = "Vitaliy Natarov",
    "Orchestration" = "Terraform"
  })

  depends_on = [
    module.base_resource_group
  ]
}

module "bastion_host" {
  source = "../../modules/network"

  // Enable bastion host
  enable_bastion_host              = true
  bastion_host_name                = "my-public-ip"
  bastion_host_location            = module.base_resource_group.resource_group_location
  bastion_host_resource_group_name = module.base_resource_group.resource_group_name

  bastion_host_ip_configuration = {
    name                 = "configuration"
    subnet_id            = module.subnet.subnet_id
    public_ip_address_id = module.public_ip.public_ip_id
  }

  bastion_host_sku         = null
  bastion_host_scale_units = null

  tags = tomap({
    "Environment"   = "test",
    "Createdby"     = "Vitaliy Natarov",
    "Orchestration" = "Terraform"
  })

  depends_on = [
    module.base_resource_group,
    module.public_ip
  ]
}
```

## Module Input Variables
----------------------
- `name` - Name to be used on all resources as prefix (`default = this`)
- `environment` - Environment for service (`default = test`)
- `tags` - Add additional tags (`default = {}`)
- `enable_network_security_group` - Enable network security group usage (`default = False`)
- `network_security_group_name` - Specifies the name of the network security group. Changing this forces a new resource to be created. (`default = ""`)
- `network_security_group_resource_group_name` - (Required) The name of the resource group in which to create the network security group. Changing this forces a new resource to be created. (`default = null`)
- `network_security_group_location` - (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. (`default = null`)
- `network_security_group_security_rule` - (Optional) List of objects representing security rules (`default = []`)
- `network_security_group_timeouts` - Set timeouts for network security group (`default = {}`)
- `enable_network_security_rule` - Enable network security rule usage (`default = False`)
- `network_security_rule_name` - The name of the security rule. This needs to be unique across all Rules in the Network Security Group. Changing this forces a new resource to be created. (`default = ""`)
- `network_security_rule_resource_group_name` - (Required) The name of the resource group in which to create the Network Security Rule. Changing this forces a new resource to be created. (`default = null`)
- `network_security_rule_network_security_group_name` - The name of the Network Security Group that we want to attach the rule to. Changing this forces a new resource to be created. (`default = ""`)
- `network_security_rule_protocol` - (Required) Network protocol this rule applies to. Possible values include Tcp, Udp, Icmp, Esp, Ah or * (which matches all). (`default = null`)
- `network_security_rule_access` - (Required) Specifies whether network traffic is allowed or denied. Possible values are Allow and Deny. (`default = null`)
- `network_security_rule_priority` - (Required) Specifies the priority of the rule. The value can be between 100 and 4096. The priority number must be unique for each rule in the collection. The lower the priority number, the higher the priority of the rule. (`default = null`)
- `network_security_rule_direction` - (Required) The direction specifies if rule will be evaluated on incoming or outgoing traffic. Possible values are Inbound and Outbound. (`default = null`)
- `network_security_rule_description` - (Optional) A description for this rule. Restricted to 140 characters. (`default = null`)
- `network_security_rule_source_port_range` - (Optional) Source Port or Range. Integer or range between 0 and 65535 or * to match any. This is required if source_port_ranges is not specified. (`default = null`)
- `network_security_rule_source_port_ranges` - (Optional) List of source ports or port ranges. This is required if source_port_range is not specified. (`default = null`)
- `network_security_rule_destination_port_range` - (Optional) Destination Port or Range. Integer or range between 0 and 65535 or * to match any. This is required if destination_port_ranges is not specified. (`default = null`)
- `network_security_rule_destination_port_ranges` - (Optional) List of destination ports or port ranges. This is required if destination_port_range is not specified. (`default = null`)
- `network_security_rule_source_address_prefix` - (Optional) CIDR or source IP range or * to match any IP. Tags such as ‘VirtualNetwork’, ‘AzureLoadBalancer’ and ‘Internet’ can also be used. This is required if source_address_prefixes is not specified. (`default = null`)
- `network_security_rule_source_address_prefixes` - (Optional) List of source address prefixes. Tags may not be used. This is required if source_address_prefix is not specified. (`default = null`)
- `network_security_rule_source_application_security_group_ids` - (Optional) A List of source Application Security Group IDs (`default = null`)
- `network_security_rule_destination_address_prefix` - (Optional) CIDR or destination IP range or * to match any IP. Tags such as ‘VirtualNetwork’, ‘AzureLoadBalancer’ and ‘Internet’ can also be used. Besides, it also supports all available Service Tags like ‘Sql.WestEurope‘, ‘Storage.EastUS‘, etc. You can list the available service tags with the CLI: shell az network list-service-tags --location westcentralus. For further information please see Azure CLI - az network list-service-tags. This is required if destination_address_prefixes is not specified. (`default = null`)
- `network_security_rule_destination_address_prefixes` - (Optional) List of destination address prefixes. Tags may not be used. This is required if destination_address_prefix is not specified. (`default = null`)
- `network_security_rule_destination_application_security_group_ids` - (Optional) A List of destination Application Security Group IDs (`default = null`)
- `network_security_rule_timeouts` - Set timeouts for network security rule (`default = {}`)
- `enable_network_security_rule_stacks` - Enable network security rules with multiple blocks (`default = False`)
- `network_security_rule_stacks` - Set rules properties (`default = []`)
- `network_security_rule_stacks_timeouts` - Set timeouts for network security rule stacks (`default = {}`)
- `enable_virtual_network` - Enable virtual network usage (`default = False`)
- `virtual_network_name` - The name of the virtual network. Changing this forces a new resource to be created. (`default = ""`)
- `virtual_network_resource_group_name` - (Required) The name of the resource group in which to create the virtual network. (`default = null`)
- `virtual_network_location` - (Required) The location/region where the virtual network is created. Changing this forces a new resource to be created. (`default = null`)
- `virtual_network_address_space` - (Required) The address space that is used the virtual network. You can supply more than one address space. (`default = null`)
- `virtual_network_bgp_community` - (Optional) The BGP community attribute in format <as-number>:<community-value>. (`default = null`)
- `virtual_network_dns_servers` - (Optional) List of IP addresses of DNS servers (`default = null`)
- `virtual_network_edge_zone` - (Optional) Specifies the Edge Zone within the Azure Region where this Virtual Network should exist. Changing this forces a new Virtual Network to be created. (`default = null`)
- `virtual_network_flow_timeout_in_minutes` - (Optional) The flow timeout in minutes for the Virtual Network, which is used to enable connection tracking for intra-VM flows. Possible values are between 4 and 30 minutes. (`default = null`)
- `virtual_network_subnet` - (Optional) Can be specified multiple times to define multiple subnets. (`default = []`)
- `virtual_network_ddos_protection_plan` - (Optional) A ddos_protection_plan block (`default = {}`)
- `virtual_network_timeouts` - Set timeouts for virtual network (`default = {}`)
- `enable_public_ip` - Enable public ip usage (`default = False`)
- `public_ip_name` - Specifies the name of the Public IP. Changing this forces a new Public IP to be created. (`default = ""`)
- `public_ip_resource_group_name` - (Required) The name of the Resource Group where this Public IP should exist. Changing this forces a new Public IP to be created. (`default = null`)
- `public_ip_location` - (Required) Specifies the supported Azure location where the Public IP should exist. Changing this forces a new resource to be created. (`default = null`)
- `public_ip_allocation_method` - (Required) Defines the allocation method for this IP address. Possible values are Static or Dynamic (`default = null`)
- `public_ip_zones` - (Optional) A collection containing the availability zone to allocate the Public IP in. (`default = null`)
- `public_ip_domain_name_label` - (Optional) Label for the Domain Name. Will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system. (`default = null`)
- `public_ip_edge_zone` - (Optional) Specifies the Edge Zone within the Azure Region where this Public IP should exist. Changing this forces a new Public IP to be created. (`default = null`)
- `public_ip_idle_timeout_in_minutes` - (Optional) Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes. (`default = null`)
- `public_ip_ip_tags` - (Optional) A mapping of IP tags to assign to the public IP. (`default = null`)
- `public_ip_ip_version` - (Optional) The IP Version to use, IPv6 or IPv4. (`default = null`)
- `public_ip_public_ip_prefix_id` - (Optional) If specified then public IP address allocated will be provided from the public IP prefix resource. (`default = null`)
- `public_ip_reverse_fqdn` -  (Optional) A fully qualified domain name that resolves to this public IP address. If the reverseFqdn is specified, then a PTR DNS record is created pointing from the IP address in the in-addr.arpa domain to the reverse FQDN. (`default = null`)
- `public_ip_sku` - (Optional) The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic. (`default = null`)
- `public_ip_sku_tier` - (Optional) The SKU Tier that should be used for the Public IP. Possible values are Regional and Global. Defaults to Regional. (`default = null`)
- `public_ip_timeouts` - Set timeouts for public ip (`default = {}`)
- `enable_subnet` - Enable subnet usage (`default = False`)
- `subnet_name` - The name of the subnet. Changing this forces a new resource to be created. (`default = ""`)
- `subnet_resource_group_name` - (Required) The name of the resource group in which to create the subnet. Changing this forces a new resource to be created. (`default = null`)
- `subnet_virtual_network_name` - The name of the virtual network to which to attach the subnet. Changing this forces a new resource to be created. (`default = ""`)
- `subnet_address_prefixes` - (Required) The address prefixes to use for the subnet. (`default = null`)
- `subnet_enforce_private_link_endpoint_network_policies` - (Optional) Enable or Disable network policies for the private link endpoint on the subnet. Setting this to true will Disable the policy and setting this to false will Enable the policy. Default value is false. (`default = null`)
- `subnet_enforce_private_link_service_network_policies` - (Optional) Enable or Disable network policies for the private link service on the subnet. Setting this to true will Disable the policy and setting this to false will Enable the policy. Default value is false. (`default = null`)
- `subnet_service_endpoints` - (Optional) The list of Service endpoints to associate with the subnet. Possible values include: Microsoft.AzureActiveDirectory, Microsoft.AzureCosmosDB, Microsoft.ContainerRegistry, Microsoft.EventHub, Microsoft.KeyVault, Microsoft.ServiceBus, Microsoft.Sql, Microsoft.Storage and Microsoft.Web. (`default = null`)
- `subnet_service_endpoint_policy_ids` - (Optional) The list of IDs of Service Endpoint Policies to associate with the subnet. (`default = null`)
- `subnet_delegation` - (Optional) One or more delegation blocks (`default = []`)
- `subnet_timeouts` - Set timeouts for subnet (`default = {}`)
- `enable_bastion_host` - Enable bastion host usage (`default = False`)
- `bastion_host_name` - Specifies the name of the Bastion Host. Changing this forces a new resource to be created. (`default = ""`)
- `bastion_host_resource_group_name` - (Required) The name of the resource group in which to create the Bastion Host. (`default = null`)
- `bastion_host_location` - (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Review Azure Bastion Host FAQ for supported locations. (`default = null`)
- `bastion_host_copy_paste_enabled` - (Optional) Is Copy/Paste feature enabled for the Bastion Host. Defaults to true. (`default = null`)
- `bastion_host_file_copy_enabled` - (Optional) Is File Copy feature enabled for the Bastion Host. Defaults to false. (`default = null`)
- `bastion_host_sku` - (Optional) The SKU of the Bastion Host. Accepted values are Basic and Standard. Defaults to Basic (`default = null`)
- `bastion_host_ip_connect_enabled` - (Optional) Is IP Connect feature enabled for the Bastion Host. Defaults to false. (`default = null`)
- `bastion_host_scale_units` - (Optional) The number of scale units with which to provision the Bastion Host. Possible values are between 2 and 50. Defaults to 2 (`default = null`)
- `bastion_host_shareable_link_enabled` - (Optional) Is Shareable Link feature enabled for the Bastion Host. Defaults to false. (`default = null`)
- `bastion_host_tunneling_enabled` - (Optional) Is Tunneling feature enabled for the Bastion Host. Defaults to false. (`default = null`)
- `bastion_host_ip_configuration` - (Required) A ip_configuration block (`default = {}`)
- `bastion_host_timeouts` - Set timeouts for bastion host (`default = {}`)
- `enable_private_link_service` - Enable private link service usage (`default = False`)
- `private_link_service_name` - Specifies the name of this Private Link Service. Changing this forces a new resource to be created. (`default = ""`)
- `private_link_service_resource_group_name` - (Required) The name of the Resource Group where the Private Link Service should exist. Changing this forces a new resource to be created. (`default = null`)
- `private_link_service_location` - (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. (`default = null`)
- `private_link_service_load_balancer_frontend_ip_configuration_ids` - (Required) A list of Frontend IP Configuration IDs from a Standard Load Balancer, where traffic from the Private Link Service should be routed. You can use Load Balancer Rules to direct this traffic to appropriate backend pools where your applications are running. (`default = null`)
- `private_link_service_nat_ip_configuration` - (Required) One or more (up to 8) nat_ip_configuration block (`default = []`)
- `private_link_service_auto_approval_subscription_ids` - (Optional) A list of Subscription UUID/GUID's that will be automatically be able to use this Private Link Service. (`default = null`)
- `private_link_service_enable_proxy_protocol` - (Optional) Should the Private Link Service support the Proxy Protocol? Defaults to false. (`default = null`)
- `private_link_service_fqdns` - (Optional) List of FQDNs allowed for the Private Link Service. (`default = null`)
- `private_link_service_visibility_subscription_ids` - (Optional) A list of Subscription UUID/GUID's that will be able to see this Private Link Service. (`default = null`)
- `private_link_service_timeouts` - Set timeouts for private link service (`default = {}`)
- `enable_private_endpoint` - Enable private endpoint usage (`default = False`)
- `private_endpoint_name` - Specifies the Name of the Private Endpoint. Changing this forces a new resource to be created. (`default = ""`)
- `private_endpoint_resource_group_name` - (Required) Specifies the Name of the Resource Group within which the Private Endpoint should exist. Changing this forces a new resource to be created. (`default = null`)
- `private_endpoint_location` - (Required) The supported Azure location where the resource exists. Changing this forces a new resource to be created. (`default = null`)
- `private_endpoint_subnet_id` - (Required) The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new resource to be created. (`default = null`)
- `private_endpoint_private_dns_zone_group` - (Optional) A private_dns_zone_group block  (`default = {}`)
- `private_endpoint_private_service_connection` - (Required) A private_service_connection block (`default = {}`)
- `private_endpoint_timeouts` - Set timeouts for private endpoint (`default = {}`)

## Module Output Variables
----------------------
- `network_security_group_id` - The ID of the Network Security Group.
- `network_security_group_name` - The name of the Network Security Group.
- `network_security_rule_id` - The ID of the Network Security Rule.
- `network_security_rule_stacks_id` - The IDs of the Network Security Rules.
- `virtual_network_id` - The virtual NetworkConfiguration ID.
- `virtual_network_name` - The name of the virtual network.
- `virtual_network_resource_group_name` - The name of the resource group in which to create the virtual network.
- `virtual_network_location` - The location/region where the virtual network is created.
- `virtual_network_address_space` - The list of address spaces used by the virtual network.
- `virtual_network_guid` - The GUID of the virtual network.
- `virtual_network_subnet` - One or more subnet blocks.
- `public_ip_id` - The ID of this Public IP.
- `public_ip_ip_address` - The IP address value that was allocated.
- `public_ip_fqdn` - Fully qualified domain name of the A DNS record associated with the public IP. domain_name_label must be specified to get the fqdn. This is the concatenation of the domain_name_label and the regionalized DNS zone
- `subnet_id` - The subnet ID.
- `subnet_name` - The name of the subnet.
- `subnet_resource_group_name` - The name of the resource group in which the subnet is created in.
- `subnet_virtual_network_name` - The name of the virtual network in which the subnet is created in
- `subnet_address_prefixes` - The address prefixes for the subnet
- `bastion_host_id` - The ID of the Bastion Host.
- `bastion_host_dns_name` - The FQDN for the Bastion Host.
- `private_link_service_id` - The ID of the private link service.
- `private_link_service_alias` - A globally unique DNS Name for your Private Link Service. You can use this alias to request a connection to your Private Link Service.
- `private_endpoint_id` - The ID of the Private Endpoint.
- `private_endpoint_network_interface` - The ID of the Private Endpoint (network interface).
- `private_endpoint_private_dns_zone_group` - The ID of the Private Endpoint (private dns zone group).
- `private_endpoint_custom_dns_configs` - The ID of the Private Endpoint (custom dns configs).
- `private_endpoint_private_dns_zone_configs` - The ID of the Private Endpoint (private dns zone configs).
- `private_endpoint_private_service_connection` - The ID of the Private Endpoint (private service connection).


## Authors

Created and maintained by [Vitaliy Natarov](https://github.com/SebastianUA). An email: [vitaliy.natarov@yahoo.com](vitaliy.natarov@yahoo.com).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/SebastianUA/terraform/blob/master/LICENSE) for full details.
