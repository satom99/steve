local array = redis.call("ZRANGEBYSCORE", KEYS[1], 0, KEYS[2], "limit", 0, ARGV[2])

for _,job in ipairs(array) do
  local hash = string.format("steve:jobs:%s", job)
  local keys = redis.call("HKEYS", hash)

  redis.call("ZREM", KEYS[1], job)
  redis.hdel(keys)
end

return #array
