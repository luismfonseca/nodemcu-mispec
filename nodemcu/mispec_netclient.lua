require 'mispec'

describe('The net module (client)', function(it)

    -- pre-tests
    ok(_G['net'] ~= nil, 'module not loaded')
    ok(wifi.getmode() ~= 0, 'not in station mode')
    ok(wifi.sta.getip() ~= nil, 'not connected to router')

    it:should('create connection', function()
        net.createConnection(net.TCP, 0)
        net.createConnection(net.TCP, 1)
        --net.createConnection(net.UDP, 0)
        --net.createConnection(net.UPD, 1)
    end)

    it:should('resolve dns', function()
        local resolvedIp = nil
        local sk = net.createConnection(net.TCP, 0)
        sk:dns('www.example.com', function(_, ip) resolvedIp = ip end)

        eventually(function() ok(resolvedIp ~= nil) end)
    end)

    it:should('connect to remote host via TCP', function()
        local connected = false
        local sk = net.createConnection(net.TCP, 0)
        sk:on('connection', function(_, c) connected = true end)
        sk:connect(80, "8.8.8.8")

        eventually(function() ok(eq(connected, true)) end)

        andThen(function() sk:close() end)
    end)

    it:should('communicate to remote host via TCP', function()
        local connected = false
        local sent = false
        local received = nil
        local sk = net.createConnection(net.TCP, 0)
        sk:on('connection', function(_, c) connected = true end)
        sk:connect(80, "www.example.com")

        eventually(function() ok(eq(connected, true)) end)

        andThen(function()
            -- configure events
            sk:on('sent', function() sent = true end)
            sk:on('receive', function(_, data) received = data end)

            -- send message
            sk:send('GET / HTTP/1.1\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n')
        end)

        eventually(function() ok(eq(sent, true)) end)
        eventually(function() ok(received ~= nil) end)

        andThen(function() sk:close() sk = nil end)
    end)

    it:should('communicate to remote host via TCP with TLS', function()
        local connected = false
        local sent = false
        local received = nil
        local sk = net.createConnection(net.TCP, 1)
        sk:on('connection', function(_, c) connected = true end)
        sk:connect(443, 'www.example.com')

        eventually(function() ok(eq(connected, true)) end, 10, 1000)

        andThen(function()
            -- configure events
            sk:on('sent', function() sent = true end)
            sk:on('receive', function(_, data) received = data end)

            -- send message
            sk:send('GET / HTTP/1.1\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n')
        end)

        eventually(function() ok(eq(sent, true)) end)
        eventually(function() ok(received ~= nil) end)

        andThen(function() sk:close() sk = nil end)
    end)

end)

mispec.run()
