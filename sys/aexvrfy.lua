if not sys.sec_user_exists('root') then
    local ip, cp
    io.writeln('Setting the password for root')
    while true do
        io.write('Password: ')
        ip = io.readln()
        io.writeln()
        io.write('Confirm: ')
        cp = io.readln()
        io.writeln()

        if ip == cp then break end
        io.writeln("Passwords didn't match")
    end
    sys.sec_add_user('root', ip)
end
if not sys.get_hostname() then
    io.writeln('Please set the hostname of this computer:')
    io.write('Hostname: ')
    sys.set_hostname(io.readln(true))
    io.writeln()
    io.writeln('The hostname can be changed later on')
end

io.writeln('Resetting...')
sleep(1250)
sys.reset()