--@EXT sys
local aex_int = sys.get_internal_table()

local syshook = {}
aex_int.syshook = syshook

local hook_table = {}

function syshook.add(name, local_name, func)
    aex_int.assertType(name, 'string')
    aex_int.assertType(local_name, 'string')
    aex_int.assertType(func, 'function')

    if not hook_table[name] then
        hook_table[name] = {}
    end
    hook_table[name][local_name] = func
end
function syshook.remove(name, local_name)
    aex_int.assertType(name, 'string')
    aex_int.assertType(local_name, 'string')

    if not hook_table[name] then
        return
    end
    hook_table[name][local_name] = nil
end
function syshook.invoke(name, ...)
    if not hook_table[name] then
        return
    end
    for _, func in pairs(hook_table[name]) do
        func(...);
    end
end