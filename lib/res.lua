--@EXT lib
-- res.lib: Translates result codes to human-readable strings

local res = {}
local translations = {
    [0x0000] = 'Success',
    [-0xA001] = 'User already exists',
    [-0xA002] = 'Access denied',
    [-0xD001] = 'Invalid device',
    [-0xD002] = 'No such device',
    [-0xD003] = 'Device already mounted',
    [-0xFD01] = 'No such file or directory',
}
res.translations = translations

function res.translate(code)
    if not res.translations[code] then
        return 'Invalid result code'
    end
    return res.translations[code]
end
return res