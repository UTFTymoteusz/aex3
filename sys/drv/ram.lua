--@EXT drv
local sectors = {{}}
local function read(path)
    local current_sector = 1
    local split = string.split(path, '/')
    table.remove(split, 1)

    local sec
    for k, v in pairs(split) do
        if #v == 0 and k == #split then break end

        sec = sectors[current_sector]

        if not sec[v] then
            return nil
        else
            current_sector = sec[v][2]
        end
    end
    return sectors[current_sector]
end
local function write(path, data)
    local current_sector = 1
    local split = string.split(path, '/')
    table.remove(split, 1)

    local sec
    for k, v in pairs(split) do
        if #v == 0 and k == #split then break end

        sec = sectors[current_sector]

        if not sec[v] then
            current_sector = #sectors + 1

            if k == #split then sec[v] = {'file', current_sector}
            else sec[v] = {'dir', current_sector} sectors[current_sector] = {} end
        else
            if sec[v][1] ~= 'dir' and k ~= #split then return false end
            current_sector = sec[v][2]
        end
    end
    sectors[current_sector] = data
    return true
end
local function mkdir(path)
    local current_sector = 1
    local split = string.split(path, '/')
    table.remove(split, 1)

    local sec
    for k, v in pairs(split) do
        if #v == 0 and k == #split then break end

        sec = sectors[current_sector]

        if not sec[v] then
            current_sector = #sectors + 1

            sec[v] = {'dir', current_sector} sectors[current_sector] = {}
        else
            if sec[v][1] ~= 'dir' then return false end
            current_sector = sec[v][2]
        end
    end
    sectors[current_sector] = {}
    return true
end

local function getPos(path)
    local current_sector = 1
    local split = string.split(path, '/')
    table.remove(split, 1)

    local sec
    for k, v in pairs(split) do
        if #v == 0 and k == #split then break end

        sec = sectors[current_sector]

        if not sec then return false end
        if not sec[v] then
            return false
        else
            current_sector = sec[v][2]
        end
    end
    return current_sector
end

local function exists(path)
    local current_sector = getPos(path)
    return not not sectors[current_sector]
end
local function list(path)
    local current_sector = getPos(path)
    return sectors[current_sector]
end
local function delete(path)
    local current_sector = getPos(path)
end

local driver = {}

driver.full_name = 'RAM Access Driver'
driver.name = 'ramacc'
driver.type = 'storage'
driver.provider = 'Tymkboi'
driver.version  = '1.0'
driver.disallow_disable = true

function driver.load()

end
function driver.unload()

end
function driver.enable()
    sys.add_device('ram', function()
        local files = {}
        return {
            fileRead   = function(self, path)       return write(path) end,
            fileExists = function(self, path)       return exists(path) end,
            fileWrite  = function(self, path, data) return write(path, data) end,
            fileList   = function(self, path)       return list(path) end,
            fileDelete = function(self, path)       return delete(path) end,
            dirCreate  = function(self, path)       return mkdir(path) end,
        }
    end)
    sys.mark_device('ram', 'hdd')
    sys.drvmgr_claim('ram', driver)
    return true
end
function driver.disable()
    return false
end

return driver