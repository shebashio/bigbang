variable "vm_size" {
  type        = string
  description = "Whether to use 'standard' m5a.4xlarge or 'big' t3a.2xlarge"
  default     = "standard"
  validation {
    error_message = "Invalid VM size"
    condition = contains([
      "standard",
      "big"
    ], var.vm_size)
  }
}

locals {
  vm_size_map = {
    standard = {
      instance_type = "t3a.2xlarge"
      spot_price    = "0.35"
    }
    big = {
      instance_type = "m5a.4xlarge"
      spot_price    = "0.69"
    }
  }
}

variable "use_private_ip" {
  description = "Use private IP for security group and k3d cluster. Incompatible with `attach_secondary_ip`"
  type        = bool
  default     = false
}

variable "attach_secondary_ip" {
  description = "Create secondary public IP. Incompatible with `use_private_ip`"
  type        = bool
  default     = false
}

