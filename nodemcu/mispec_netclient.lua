require 'mispec'

mispec.describe('The net module (client)', function(it)

    -- pre-tests
    mispec.ok(_G['net'] ~= nil, 'module not loaded')
    mispec.ok(wifi.getmode() ~= 0, 'not in station mode')
    mispec.ok(wifi.sta.getip() ~= nil, 'not connected to router')

    it:should('create connection', function()
        net.createConnection(net.TCP, 0)
        tls.createConnection()
    end)

    it:should('resolve dns', function()
        local resolvedIp = nil
        local sk = net.createConnection(net.TCP, 0)
        sk:dns('www.example.com', function(_, ip) resolvedIp = ip end)

        mispec.eventually(function() mispec.ok(resolvedIp ~= nil) end)
        mispec.andThen(function() sk = nil end)
    end)

    it:should('connect to remote host via TCP', function()
        local connected = false
        local sk = net.createConnection(net.TCP, 0)
        sk:on('connection', function(_, c) connected = true end)
        sk:connect(443, "8.8.8.8")

        mispec.eventually(function() mispec.ok(mispec.eq(connected, true)) end)

        mispec.andThen(function() sk:close() sk = nil end)
    end)

    it:should('communicate to remote host via TCP with TLS', function()
        local connected = false
        local sent = false
        local received = nil
        local sk = tls.createConnection()
        sk:on('connection', function(_, c) connected = true end)
        sk:connect(443, 'www.example.com')

        mispec.eventually(function() mispec.ok(mispec.eq(connected, true)) end, 10, 1000)

        mispec.andThen(function()
            -- configure events
            sk:on('sent', function() sent = true end)
            sk:on('receive', function(_, data) received = data end)

            -- send message
            sk:send('GET / HTTP/1.0\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n')
        end)

        mispec.eventually(function() mispec.ok(mispec.eq(sent, true)) end)
        mispec.eventually(function() mispec.ok(received ~= nil) end)

        mispec.andThen(function() sk:close() sk = nil end)
    end)

    it:should('communicate to remote host via TCP', function()
        local connected = false
        local sent = false
        local received = nil
        local sk = net.createConnection(net.TCP, 0)
        sk:on('connection', function(_, c) connected = true end)
        sk:connect(80, "www.example.com")

        mispec.eventually(function() mispec.ok(mispec.eq(connected, true)) end)

        mispec.andThen(function()
            -- configure events
            sk:on('sent', function() sent = true end)
            sk:on('receive', function(_, data) received = data end)

            -- send message
            sk:send('GET / HTTP/1.0\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n')
        end)

        mispec.eventually(function() mispec.ok(mispec.eq(sent, true)) end)
        mispec.eventually(function() mispec.ok(received ~= nil) end)

        mispec.andThen(function() sk:close() sk = nil end)
    end)
end)

mispec.run()
