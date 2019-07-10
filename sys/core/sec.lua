--@EXT sys
local aex_int = sys.get_internal_table()
aex_int.sec = {
    accounts = {},
}
local sec = aex_int.sec

local crypto = require('crypto')
local proc_assocs = {}

local function sha256_salt(thing)
    thing = '%12' .. thing .. crypto.sha256(thing) .. 'd2#c' .. thing .. 'avx*&%'

    sleep(100)

    return crypto.sha256(thing)
end
local function getAndVerify()
    local pid = sys.get_running_pid()
    if not proc_assocs[pid] then proc_assocs[pid] = {} end

    return proc_assocs[pid]
end
local function randomize()
    local s1, res = 0, ''
    for i = 1, 128 do
        s1 = math.random()

        if s1 >= 0 and s1 <= 0.333 then        res = res .. string.char(math.random(48, 57))
        elseif s1 > 0.333 and s1 <= 0.666 then res = res .. string.char(math.random(65, 90))
        else res = res .. string.char(math.random(97, 122)) end
    end
    return res
end

function sys.sec_user_exists(name)
    aex_int.assertType(name, 'string')
    return not not sec.accounts[name]
end
function sys.sec_add_user(name, password)
    aex_int.assertType(name,     'string')
    aex_int.assertType(password, 'string', true)

    if sec.accounts[name] then
        return nil, aex_int.result.user_already_exists_error
    end
    local password = password
    if password == '' then password = nil end
    if password then
        password = sha256_salt(password)
    end
    sec.accounts[name] = {
        pass = password,
    }
    sec.save()
    sys.fs_mkdir('/home/' .. name)
end
function sys.sec_get_new_assoc(user, pass)
    local assocs = getAndVerify()
    local new
    while true do
        new = randomize()
        if not assocs[new] then break end
    end
    assocs[new] = {
        user = user,
        pass = pass,
    }
    return {
        id = new,
        setUser = function(self, user)
            assocs[new].user = user
        end,
        setPass = function(self, pass)
            assocs[new].pass = pass
        end,
        discard = function(self)
            assocs[new] = {}
        end
    }
end
function sys.sec_assoc_verify_and_user(id_or_assoc)
    local id
    if type(id_or_assoc) == 'string' then
        id = id_or_assoc
    elseif type(id_or_assoc) == 'table' then
        id = id_or_assoc.id
    else error('sys.sec_assoc_verify: Invalid argument', 3) end

    local assocs = getAndVerify()
    if not assocs[id] then return false end

    local assoc = assocs[id]
    local acc   = sec.accounts[assoc.user]

    if acc then
        if acc.pass == sha256_salt(assoc.pass) then return true, assoc.user end
    end
    sleep(400)
    return false
end

local function sec_init()
    local fd = sys.fs_open('/cfg/passwd', 'r')
    if not fd then return end

    local s = string.split(fd:read('*a'), '\n')
    for _, v in pairs(s) do
        v = string.trim(v)
        if #v == 0 then goto xcontinue end

        v = string.split(v, ';')

        local pass = v[2]
        if pass == 'NP' then pass = nil end

        sec.accounts[ v[1] ] = {pass = pass}
        ::xcontinue::
    end
    fd:close()
end
local function sec_save()
    local fd = sys.fs_open('/cfg/passwd', 'w')
    for k, v in pairs(sec.accounts) do
        fd:write(k)
        fd:write(';')

        if v.pass then fd:write(v.pass)
        else fd:write('NP') end

        fd:write(';\n')
    end
    fd:flush()
    fd:close()
end
sec.init = sec_init
sec.save = sec_save