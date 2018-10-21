local array = redis.call("ZRANGEBYSCORE", KEYS[1], 0, KEYS[2], "limit", 0, ARGV[2])

for i,job in ipairs(array) do
  local hash = string.format("steve:jobs:%s", job)
  local values = redis.call("HMGET", hash, "queue", "content")
  local desination = string.format("steve:%s:running:%s", values[1], KEYS[3])

  redis.call("ZREM", KEYS[1], job)
  redis.call("HINCRBY", hash, "retry", 1)
  redis.call("LPUSH", desination, job)

  array[i] = values[2]
end

return array
