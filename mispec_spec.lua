require 'mispec'

mispec.describe('A mispec module', function(it)
    it:should('run a test', mispec.ok)

    it:should('run multiple tests', mispec.ok)

    it:should('run a test that eventually passes', function()
        local a = 0
        mispec.eventually(function()
            a = a + 1
            mispec.ok(a == 3)
        end)
    end)

    it:should('run a test that has several eventuallys', function()
        mispec.eventually(function() mispec.ok(math.random(10) < 7) end)
        mispec.eventually(function() mispec.ok(math.random(10) < 6) end)
    end)

    it:should('run a test that has several eventuallys in the correct order', function()
        local b = ''
        mispec.eventually(function() b = b .. 'a' mispec.ok(mispec.eq(#b % 2, 0)) end)
        mispec.eventually(function() b = b .. 'b' mispec.ok(mispec.eq(#b % 2, 0)) end)
        mispec.eventually(function() b = b .. 'c' mispec.ok(mispec.eq(#b % 2, 0)) end)

        mispec.eventually(function() mispec.ok(b == 'aabbcc') end)
    end)

    it:should('run a test with andThen function to chain logic', function()
        local c = ''
        mispec.eventually(function() c = c .. 'a' mispec.ok(mispec.eq(#c % 3, 0)) end)
        mispec.andThen(function() c = c .. 'once' end)
        mispec.andThen(function() mispec.ok(c == 'aaaonce') end)
    end)

    it:should('run a test that just fails', function() mispec.ok(mispec.eq(1, -1)) end)

    it:should('increase the count of failed test if one fails', function()
        mispec.ok(mispec.failed == 1)
    end)

    it:should('fail if andThen are nested', function()
        mispec.andThen(function() mispec.andThen(mispec.ok) end)
    end)

    it:should('fail if eventually are nested', function()
        mispec.eventually(function() mispec.eventually(mispec.ok) end)
    end)

    it:should('skip a test', function()
        return mispec.skip('skipped by user')
    end)
end)

print("It is expected to have: failed:3, skipped:1, total:11")
mispec.run()
