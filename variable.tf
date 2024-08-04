variable "private_key" {
  type = string
  description = "This is private key"
  default = "./keys/aws_key"
}

variable "public_key" {
  type = string
  description = "This is public key"
  default = "./keys/aws_key.pub"
}

variable "instance_minion_count" {
  type = number
  description = "Indicate how many minions are present"
  default = 3
}