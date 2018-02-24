require('mispec')

--[[
-- the following requires 2 ads devices and optionally one mcp4725
-- ads1015 - ADDR_GND
-- ads1115 - ADDR_VDD
-- mcp4725 - {A1=1}
-- both AIN0 connected to OUT of mcp
-- both AIN3 connected to 1/2 VDD (2x10k resistors)
-- both alert pins connected to GPIO 3
]]--

mispec.describe('The ads1115 module', function(it)

    -- pre-tests
    mispec.ok(_G['i2c'] ~= nil, 'i2c is missing')
    mispec.ok(_G['ads1115'] ~= nil, 'module not loaded')

    it:should("read in single shot mode with hardware conversion ready", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(id, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_6_144V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT, ads1115.CONV_RDY_1)
        local called = false
        local volt, volt_dec, adc, sign
        local function conversion_ready(level, when)
            gpio.trig(alert_pin)
            volt, volt_dec, adc, sign = adc1:read()
            called = true
        end
        gpio.mode(alert_pin, gpio.INT)
        gpio.trig(alert_pin, "down", conversion_ready)
        adc1:startread()
        mispec.eventually(function()
            mispec.ok(called == true, "missing callback")
            mispec.ok(volt ~= nil, "missing volt")
            mispec.ok(adc ~= nil, "missing raw")
            if mispec.float_build then
                mispec.ok(volt_dec == nil, "volt_dec not nil")
                mispec.ok(sign == nil, "sing not nil")
            else
                mispec.ok(volt_dec ~= nil, "volt_dec is nil")
                mispec.ok(sign ~= nil, "sing is nil")
            end
        end)
    end)

    it:should("trigger when input value is out of range (window)", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(id, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_1_024V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS, ads1115.COMP_1CONV, -15, 100, ads1115.CMODE_WINDOW)
        local triggered = false
        local volt, volt_dec, adc, sign
        local function comparator_trigger(level, when)
            volt, volt_dec, adc, sign = adc1:read()
            gpio.trig(alert_pin)
            triggered = true
        end
        gpio.mode(alert_pin, gpio.INT, gpio.PULLUP)
        gpio.trig(alert_pin, "down", comparator_trigger)
    end)


    it:should("trigger when input value is out of range (window) - complete", function()
        if _G["mcp4725"] == nil then
            return mispec.skip("mcp4725 module is missing")
        end
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        mcp4725.write({A1=1, value=2048}) -- half => ~zero for differential
        print("set output")
        local adc1 = ads1115.ads1015(id, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_1_024V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS,
                     ads1115.COMP_1CONV, -500, 500, ads1115.CMODE_WINDOW)
        local triggered = false
        local volt, volt_dec, adc, sign
        local function comparator_trigger(level, when)
            volt, volt_dec, adc, sign = adc1:read()
            gpio.trig(alert_pin)
            triggered = true
        end
        gpio.mode(alert_pin, gpio.INT, gpio.PULLUP)
        gpio.trig(alert_pin, "down", comparator_trigger)
        local wait = true
        mispec.eventually(function()
            if wait then
                wait = false
                mispec.ok(false)
            end
        end, 1, 250)
        mispec.andThen(function()
            mispec.ko(triggered == true, "unexpected trigger")
        end)
        mispec.andThen(function()
            mcp4725.write({A1=1, value=0}) -- trigger
        end)
        mispec.eventually(function()
            mispec.ok(triggered == true, "missing trigger")
            mispec.ok(volt ~= nil, "missing volt")
            mispec.ok(adc ~= nil, "missing raw")
            if mispec.float_build then
                mispec.ok(volt_dec == nil, "volt_dec not nil")
                mispec.ok(sign == nil, "sing not nil")
            else
                mispec.ok(volt_dec ~= nil, "volt_dec is nil")
                mispec.ok(sign ~= nil, "sing is nil")
            end
        end, 1, 250)
    end)

    it:should("report invalid argument", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local status, err = pcall(ads1115.ads1015, 1, ads1115.ADDR_GND)
        mispec.ko(status, "missing error")
        mispec.ok(err:find("bad argument #1", 1, true) ~= nil, "missing error message")

        status, err = pcall(ads1115.ads1015, id, ads1115.ADDR_SDA)
        mispec.ko(status, "missing error")
        mispec.ok(err:find("found no device", 1, true) ~= nil, "missing error message")

        status, err = pcall(ads1115.ads1015, id, 1)
        mispec.ko(status, "missing error")
        mispec.ok(err:find("bad argument #2", 1, true) ~= nil, "missing error message")
    end)

    it:should("report invalid argument for specific device", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc2 = ads1115.ads1015(id, ads1115.ADDR_GND)
        -- 1015 does not support 8SPS
        local status, err = pcall(adc2.setting, adc2, ads1115.GAIN_6_144V, ads1115.DR_8SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT)
        mispec.ko(status, "missing error")
        -- parameter number is off by 1
        mispec.ok(err:find("bad argument #3", 1, true) ~= nil, "missing error message")
    end)

    it:should("report invalid device state when re-initializing without reset", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc2 = ads1115.ads1015(id, ads1115.ADDR_GND)
        local status, err = pcall(adc2.setting, adc2, ads1115.GAIN_6_144V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT)
        mispec.ok(status, "setting failed")
        status, err = pcall(ads1115.ads1015, id, ads1115.ADDR_GND)
        mispec.ko(status, "missing error")
        mispec.ok(err:find("please reset device before calling this function", 1, true) ~= nil, "missing error message")
    end)

end)

mispec.run()
