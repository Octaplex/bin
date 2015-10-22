#!/usr/bin/lua
---

local execute, exit, getenv = os.execute, os.exit, os.getenv

---

local function die(why)
    if why then print("\27[1;31merror:\27[0m " .. why) end
    exit(1)
end

local function warn(what)
    print("\27[1;33mwarning:\27[0m " .. what)
end

---

if execute() == 0 then
    die("no shell available")
end
