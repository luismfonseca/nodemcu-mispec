require 'mispec'

describe('A mispec module', function(it)
    it:should('run a test', ok)

    it:should('run multiple tests', ok)

    it:should('run a test that eventually passes', function()
        local a = 0
        eventually(function()
            a = a + 1
            ok(a == 3)
        end)
    end)

    it:should('run a test that has several eventuallys', function()
        eventually(function() ok(math.random(10) < 7) end)
        eventually(function() ok(math.random(10) < 6) end)
    end)

    it:should('run a test that has several eventuallys in the correct order', function()
        local t = ''
        eventually(function() t = t .. 'a' ok(#t % 2 == 0) end)
        eventually(function() t = t .. 'b' ok(#t % 2 == 0) end)
        eventually(function() t = t .. 'c' ok(#t % 2 == 0) end)
        eventually(function() ok(t == 'aabbcc') end)
    end)

    it:should('run a test that just fails', ko)
end)

mispec.run()
