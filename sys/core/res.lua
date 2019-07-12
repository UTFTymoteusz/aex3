--@EXT sys
-- res.sys: Common result codes
local aex_int = sys.get_internal_table()
aex_int.result = {
    success = 0,
    doing_this_would_make_the_system_unstable_error = -0x1001,
    user_already_exists_error = -0xA001,
    access_denied_error = -0xA002,
    invalid_device_error = -0xD001,
    no_such_device_error = -0xD002,
    already_mounted_error = -0xD003,
    no_media_inserted_error = -0xD004,
    no_such_file_or_directory = -0xFD01,
    resource_or_device_busy_error = -0xFD02,
    is_a_directory_error = -0xFD03,
    is_a_file_error = -0xFD04,
    directory_not_empty_error = -0xFD05,
}