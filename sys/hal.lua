--@EXT lib
local aex_int = sys.get_internal_table()
local hal = {}
aex_int.hal = hal

local boot_kind = aex_int.boot.kind

if boot_kind == 'net_rh_emu' then
    hal.hdd = {
        file_read = function(id, path)
            return rh:FileRead(id, path)
        end,
        file_exists = function(id, path)
            return rh:FileExists(id, path)
        end,
        file_write = function(id, path, data)
            return rh:FileWrite(id, path, data)
        end,
        file_list = function(id, path)
            local list = rh:FileList(id, path)
            local ret = {}

            for k, v in pairs(string.split(list, '\n')) do
                v = string.split(v, '\r')
                if not v[1] or not v[2] then goto xcontinue end

                ret[#ret + 1] = {
                    name = v[1],
                    type = v[2],
                }
                ::xcontinue::
            end
            return ret
        end,
        file_delete = function(id, path)
            return rh:FileDelete(id, path)
        end,
        dir_create = function(id, path)
            return rh:DirectoryCreate(id, path)
        end,
        get_all_ids = function()
            return {0}
        end,
    }
    hal.core = {
        reset = function()
            rh:Reset()
        end,
        beep = function(freq, len)
            rh:Beep(freq, len)
        end,
    }
end