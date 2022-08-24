local M = {}

---Same as Object.assign() in JavaScript
M.assign = function(...)
  local n = select("#", ...)
  if n == 0 then
    return nil
  end
  local res = select(1, ...)
  for i = 2, n do
    local t = select(i, ...)
    for k, v in pairs(t) do
      res[k] = v
    end
  end
  return res
end

return M
