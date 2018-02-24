require 'mispec'

mispec.describe('math.pow(a, b)', function(it)
    function neareq(a, b) -- comparing floats requires this
        return math.abs(a - b) <= 0.000001
    end

    it:should('return 0 if base is 0', function()
        mispec.ok(neareq(math.pow(0, 1), 0))
        mispec.ok(neareq(math.pow(0, 123), 0))
    end)

    it:should('return 1 if power to 0', function()
        mispec.ok(neareq(math.pow(0, 0), 1))
        mispec.ok(neareq(math.pow(1, 0), 1))
        mispec.ok(neareq(math.pow(123, 0), 1))
    end)

    it:should('power to even numbers', function()
        mispec.ok(neareq(math.pow(2, 2), 4))
        mispec.ok(neareq(math.pow(-2, 2), 4))
        mispec.ok(neareq(math.pow(-2, 10), 1024))
    end)

    it:should('power to odd numbers', function()
        mispec.ok(neareq(math.pow(2, 3), 8))
        mispec.ok(neareq(math.pow(-2, 3), -8))
        mispec.ok(neareq(math.pow(-0.5, 3), -0.125))
    end)

    it:should('return nan if base < 0 and exponent is fractional', function()
        local result = math.pow(-1, 0.5)
        mispec.ok(result ~= result)
    end)
end)

mispec.run()
