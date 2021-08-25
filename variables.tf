variable "node_location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "node_address_space" {
  default = ["10.8.0.0/16"]
}

variable "node_address_prefix" {
  default = ["10.8.1.0/24"]
}

variable "Environment" {
  type = string
}

variable "node_count" {
  type = number
}

variable "vm_username" {
  description = "Enter admin username to SSH into Linux VMs"
}

variable "vm_password" {
  description = "Enter admin password to SSH into VMs"
}