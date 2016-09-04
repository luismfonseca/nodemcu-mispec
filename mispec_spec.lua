require 'mispec'

mispec.describe('A mispec module', function(it)
    it:should('run a test', ok)

    it:should('run multiple tests', ok)

    it:should('run a test that eventually passes', function()
        a = 0
        eventually(function()
            a = a + 1
            ok(a == 3)
        end)
    end)

    it:should('run a test that has several eventuallys', function()
        eventually(function()
            ok(math.random(10) < 7)
            eventually(function() ok(math.random(10) < 7) end)
        end)
    end)

    it:should('fail', function() ok(eq(1, 2)) end)
end
):evaluate()
