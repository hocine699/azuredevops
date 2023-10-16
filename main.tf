provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RG-LZ" {
  name     = "rg-connectivity-lz-neu"
  location = "North Europe"

  tags = {
    Owner = "Hocine"
  }
}

resource "azurerm_virtual_network" "Vnet-hub" {
  name                = "lz-vnet-hub"
  address_space       = ["10.0.0.0/23"]
  location            = azurerm_resource_group.RG-LZ.location
  resource_group_name = azurerm_resource_group.RG-LZ.name
}

resource "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.RG-LZ.name
  virtual_network_name = azurerm_virtual_network.Vnet-hub.name
  address_prefixes     = ["10.0.0.0/26"]
}

resource "azurerm_public_ip" "pubip" {
  name                = "pubip"
  location            = azurerm_resource_group.RG-LZ.location
  resource_group_name = azurerm_resource_group.RG-LZ.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "lz-AzFw" {
  name                = "lz-firewall"
  location            = azurerm_resource_group.RG-LZ.location
  resource_group_name = azurerm_resource_group.RG-LZ.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "IPconf"
    subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.pubip.id
  }
}

resource "azurerm_private_dns_zone" "PrivateDNSzone" {
  name                = "test.cellenza.xyz"
  resource_group_name = azurerm_resource_group.RG-LZ.name
}

resource "azurerm_storage_account" "testing" {
  name                     = "hocinetestinglz"
  resource_group_name      = azurerm_resource_group.RG-LZ.name
  location                 = azurerm_resource_group.RG-LZ.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container-LZ" {
  name                  = "container-lz"
  storage_account_name  = azurerm_storage_account.testing.name
  container_access_type = "private"
}

resource "azurerm_network_security_group" "NSG" {
  name                = "TestSecurityGroup"
  location            = azurerm_resource_group.RG-LZ.location
  resource_group_name = azurerm_resource_group.RG-LZ.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtual-link" {
  name                  = "ZoneDNSversVirtualNetwork"
  resource_group_name   = azurerm_resource_group.RG-LZ.name
  private_dns_zone_name = azurerm_private_dns_zone.PrivateDNSzone.name
  virtual_network_id    = azurerm_virtual_network.lz-vnet-hub.id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-connectivity-lz-neu"
    storage_account_name = "hocinetestinglz"
    container_name       = "container-lz"
    key                  = "terraform.tfstate"
  }
  }

