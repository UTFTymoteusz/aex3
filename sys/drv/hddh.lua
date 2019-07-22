--@EXT drv
info = {
    full_name = 'HDD Hub Driver',
    name = 'hddh',
    type = 'hub',
    provider = 'Tymkboi',
    version  = '1.1',
    disallow_disable = true,
}

local aex_int = sys.get_internal_table()
local hal  = aex_int.hal
local boot = aex_int.boot

local fd_open  = hal.hdd.fd_open
local fd_read  = hal.hdd.fd_read
local fd_write = hal.hdd.fd_write
local fd_seek  = hal.hdd.fd_seek
local fd_flush = hal.hdd.fd_flush
local fd_close = hal.hdd.fd_close

local file_read   = hal.hdd.file_read
local file_exists = hal.hdd.file_exists
local file_write  = hal.hdd.file_write
local file_list   = hal.hdd.file_list
local file_delete = hal.hdd.file_delete
local dir_create  = hal.hdd.dir_create
local file_size   = hal.hdd.file_size
local file_type   = hal.hdd.file_type

local devid = 0

local function enable_internal()

    for _, id in pairs(hal.hdd.get_all_ids()) do

        if id == boot.drive_id then
            boot.drive_name = '/dev/hdd' .. devid
        end
        sys.add_device('hdd' .. devid, {
            fd_open = function(self, path, mode) 
                return fd_open(id, path, mode)
            end,
            fd_read = function(self, fd, len)
                return fd_read(id, fd, len)
            end,
            fd_write = function(self, fd, str)
                return fd_write(id, fd, str)
            end,
            fd_seek = function(self, fd, op, offset)
                return fd_seek(id, fd, op, offset)
            end,
            fd_flush = function(self, fd)
                return fd_flush(id, fd)
            end,
            fd_close = function(self, fd)
                return fd_close(id, fd)
            end,

            fileExists = function(self, path) return file_exists(id, path) end,
            fileList   = function(self, path) return file_list(id,   path) end,
            fileDelete = function(self, path) return file_delete(id, path) end,
            dirCreate  = function(self, path) return dir_create(id,  path) end,
            fileSize   = function(self, path) return file_size(id,   path) end,
            fileType   = function(self, path) return file_type(id,   path) end,
        }, 'storage', 'hdd')

        devid = devid + 1
        ::xcont::
    end
end

function load()

end
function unload()

end
function enable()
    enable_internal()
    return true
end
function disable()
    return false
end

return driver