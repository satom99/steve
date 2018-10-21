local array = redis.call("LRANGE", KEYS[1], 0, -1)

for _,job in ipairs(array) do
  local hash = string.format("steve:jobs:%s", job)
  local desination = string.format("steve:%s:queued", values[1])

  redis.call("ZREM", KEYS[1], job)
  redis.call("HINCRBY", hash, "retry", -1)
  redis.call("LPUSH", desination, job)
end

return #array
