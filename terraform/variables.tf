# Global variables

variable "location" {
  description = "The Azure Region in which the resources should exist"
  default     = "eastus2"
}

# Builder variables

variable "builder_resource_group_name" {
  description = "The name of the resouce groupe used by packer"
  default     = "tmp-resource-group"
}

variable "builder_image_name" {
  description = "Image name provisioned by packer"
  default     = "ubuntu-neoway-image"
}

# tmp variables

variable "prefix" {
  description = "The Prefix used for all resources"
  default     = "tmp"
}

variable "tmp_env" {
  description = "Default name for builder environment"
  default     = "tmp"
}

variable "tmp_resource_group_name" {
  description = "The name of the resouce groupe used by tmp"
  default     = "tmp-resource-group"
}

variable "tmp_vnet" {
  description = "Address for tmp vnet"
  default     = "10.181.0.0/16"
}

variable "tmp_subnet" {
  description = "Address for tmp subnet"
  default     = "10.181.1.0/24"
}

variable "tmp_nic_name" {
  description = "Nic tmp name"
  default     = "tmp-nic"
}

variable "tmp_vm_name" {
  description = "tmp vm name"
  default     = "tmp-vm"
}

variable "tmp_user" {
  description = "user for tmp vm"
  default     = "tmp"
}

variable "tmp_vm_size" {
  description = "Azure vm size"
  default     = "Standard_A0"
}

variable "vhd_url" {
  description = "VHD url created by packer"
  default     = ""
}

variable "image_publisher" {
  description = ""
  default = "Canonical"
}

variable "image_offer" {
  description = ""
  default = "UbuntuServer"
}


variable "image_sku" {
  description = ""
  default = "16.04-LTS"
}

variable "image_version" {
  description = ""
  default = "latest"
}
