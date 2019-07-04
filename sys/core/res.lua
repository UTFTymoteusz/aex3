--@EXT km
-- res.km: Common result codes
local aex_int = sys.get_internal_table()
aex_int.result = {
    success = 0,
    user_already_exists_error = -0xA001,
    access_denied_error = -0xA002,
    invalid_device_error = -0xD001,
    no_such_device_error = -0xD002,
    no_such_file_or_directory = -0xFD01,
}