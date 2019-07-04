--@EXT lib
local sec = {}
function sec.getNewAssoc(user, pass)
    return sys.sec_get_new_assoc(user, pass)
end
function sec.verifyAssoc(assoc)
    return sys.sec_assoc_verify_and_user(assoc)
end
function sec.userExists(user)
    return sys.sec_user_exists(user)
end
function sec.addUser(user, pass)
    return sys.sec_add_user(user, pass)
end
return sec