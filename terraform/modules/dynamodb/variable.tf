variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "partition_key_name" {
  description = "Partition key name"
  type        = string
  default     = "short_url"
}

variable "partition_key_type" {
  description = "Partition key type"
  type        = string
  default     = "S"
}

variable "tags" {
  description = "Tags for the DynamoDB table"
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "url-shortener"
  }
}
