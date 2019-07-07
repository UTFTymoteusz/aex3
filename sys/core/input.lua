--@EXT km
local aex_int = sys.get_internal_table()
aex_int.input = {
    dev = {},
}
local tty = aex_int.boot.tty
local log = aex_int.log

local input_keys      = nil
local input_keys_raw  = nil
local input_keys_pres = {}
local input_cur_keys  = {}
local input_last_key  = nil
local input_key_start_t = 0

local kn = nil

local function resolveKeys()
    kn = {}

    for _, v in pairs(input_cur_keys) do
        if v < 154 or v > 251 then table.add(kn, {v}) end
    end
    if #kn == 0 then return end
    
    if input_keys_pres[158] then
        for k, v in pairs(kn) do

            if v >= 97 and v <= 122 then kn[k] = v - 96
            elseif v >= 65 and v <= 90 then kn[k] = v - 64 end
        end
        input_keys = kn
        return
    end 
    input_keys = kn
end

function sys.input_add_device(name)
    if not name then error('sys.add_input_device: Missing arguments') end

    tty.writeln(log.device() .. 'Added input device ' .. name)
    aex_int.input.dev[name] = true

    return {
        keyPress = function(self, key)
            if type(key) ~= 'number' then error(':keyPress requires a number, not a string') end

            if key >= 17 and key <= 20 then key = key + 235
            elseif key == 127 then key = 8 end

            input_key_start_t = timer.systime() + 1

            input_last_key = key
            table.add(input_cur_keys, {key})

            input_keys_pres[key] = true
        end,
        keyRelease = function(self, key)
            if type(key) ~= 'number' then error(':keyRelease requires a number, not a string') end

            if key >= 17 and key <= 20 then key = key + 235
            elseif key == 127 then key = 8 end

            if key == input_last_key then
                input_last_key = nil
            end
            input_keys_pres[key] = nil
        end,
    }
end
function sys.input_get_keys()
    return input_keys
end
function sys.input_get_keys_raw()
    return input_keys_raw
end

local systime = 0
sys.thread_create(function()
    while true do
        waitOne()

        if #input_cur_keys ~= 0 then
            input_keys_raw = table.copy(input_cur_keys)

            resolveKeys()
            table.empty(input_cur_keys)

            goto xcontinue
        end
        if input_last_key then 
            systime = timer.systime()
            if systime > input_key_start_t and (input_last_key < 154 or input_last_key > 251) then
                input_key_start_t = systime + 0.05

                input_keys_raw = {input_last_key}
                input_keys     = {input_last_key}
                
                goto xcontinue
            end
        end
        input_keys = nil
        input_keys_raw = nil
        ::xcontinue::
    end
end)