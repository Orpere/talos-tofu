output "record_names" {
  description = "List of DNS A record names created"
  value       = keys(var.records)
}
