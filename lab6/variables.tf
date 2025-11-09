variable "location" {
  type        = string
  default     = "swedencentral"
}

variable subscription_id {
    type = string
    default = "bc1a0270-6de3-4984-9e04-aec67432b9ef"
}


variable "admin_username" {
  default = "localadmin"
}

variable "admin_password" {
  description = "Password for the VMs"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  default = "Standard_B1s"
}