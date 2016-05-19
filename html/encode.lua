#!/usr/bin/env lua

local arg = ...

local function encode_html(arg)
  local b = {}
  for i = 1, #arg do
    b[#b+1] = ("&#%d;"):format(arg:sub(i, i):byte())
  end
  return table.concat(b)
end
local function encode_url(arg)
  local b = {}
  for i = 1, #arg do
    b[#b+1] = ("%%%2X"):format(arg:sub(i, i):byte())
  end
  return table.concat(b)
end

-- local function encode(arg, html, url)
--   if html == nil then html = true  end
--   if url  == nil then url  = false end
--   local b = {}
--   for i = 1, #arg do
--     local c = arg:sub(i, i)
--     if url then
--       c = ("%%%2X"):format(c:byte())
--     end
--     if html then
--       for j = 1, #c do
-- 	print(c:sub(j, j))
-- 	b[#b+1] = ("&#%d;"):format(c:sub(j, j):byte())
--       end
--     else
--       b[#b+1] = c
--     end
--   end
--   return table.concat(b)
-- end

local arg_html = encode_html(arg)
local arg_url  = encode_url (arg)
local arg_both = encode_html(arg_url)
local arg_mail = ("mailto:%s"):format(arg_url)

print("plain", arg)
print("html",  arg_html)
print("url",   arg_url)
print("both",  arg_both)
print("mail",  arg_mail)
print()
print("e-mail", ('<a href="%s">%s</a>'):format(encode_html(arg_mail), arg_html))
