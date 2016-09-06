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
        local b = ''
        eventually(function() b = b .. 'a' ok(eq(#b % 2, 0)) end)
        eventually(function() b = b .. 'b' ok(eq(#b % 2, 0)) end)
        eventually(function() b = b .. 'c' ok(eq(#b % 2, 0)) end)

        eventually(function() ok(b == 'aabbcc') end)
    end)

    it:should('run a test with andThen function to chain logic', function()
        local c = ''
        eventually(function() c = c .. 'a' ok(eq(#c % 3, 0)) end)
        andThen(function() c = c .. 'once' end)
        andThen(function() ok(c == 'aaaonce') end)
    end)

    it:should('run a test that just fails', ko)

    it:should('increase the count of failed test if one fails', function()
        ok(mispec.failed == 1)
    end)

    it:should('fail if andThen are nested', function()
        andThen(function() andThen(ok) end)
    end)

    it:should('fail if eventually are nested', function()
        eventually(function() eventually(ok) end)
    end)
end)

mispec.run()
