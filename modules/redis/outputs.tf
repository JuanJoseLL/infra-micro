output "id" {
  description = "The ID of the Redis instance."
  value       = azurerm_redis_cache.redis.id
}

output "hostname" {
  description = "The hostname of the Redis instance."
  value       = azurerm_redis_cache.redis.hostname
}

output "ssl_port" {
  description = "The SSL port the Redis instance is listening on."
  value       = azurerm_redis_cache.redis.ssl_port
}

output "port" {
  description = "The non-SSL port the Redis instance is listening on."
  value       = azurerm_redis_cache.redis.port
}

output "primary_access_key" {
  description = "The primary access key for the Redis instance."
  value       = azurerm_redis_cache.redis.primary_access_key
  sensitive   = true
}

output "name" {
  value = azurerm_redis_cache.redis.name
}