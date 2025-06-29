output "record_names" {
  description = "List of DNS A record names created"
  value       = keys(var.records)
}


output "dns_a_records" {
  description = "DNS A records created"
  value = {
    for name, record in dns_a_record_set.records :
    name => record.addresses
  }
}