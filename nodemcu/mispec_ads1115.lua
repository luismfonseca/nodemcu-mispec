require 'mispec'

--[[
-- the following requires 2 ads devices and optionally one mcp4725
-- ads1015 - ADDR_GND
-- ads1115 - ADDR_VDD
-- mcp4725 - {A1=1}
-- both AIN0 connected to OUT of mcp
-- both AIN3 connected to 1/2 VDD (2x10k resistors)
-- both alert pins connected to GPIO 3
]]--

describe('The ads1115 module', function(it)

    -- pre-tests
    ok(_G['i2c'] ~= nil, 'i2c is missing')
    ok(_G['ads1115'] ~= nil, 'module not loaded')

    it:should("read in continuous mode, 1 device", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(0, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_6_144V, ads1115.DR_3300SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS)
        local volt, volt_dec, raw = adc1:read()
        ok(volt ~= nil, "missing volt")
        ok(volt_dec ~= nil, "missing volt_dec")
        ok(raw ~= nil, "missing raw")
    end)

    it:should("handle 2 devices", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(0, ads1115.ADDR_GND)
        local adc2 = ads1115.ads1115(0, ads1115.ADDR_VDD)
        adc1:setting(ads1115.GAIN_6_144V, ads1115.DR_3300SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS)
        adc2:setting(ads1115.GAIN_6_144V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS)
        local volt1, volt_dec1, raw1 = adc1:read()
        ok(volt1 ~= nil, "missing volt")
        ok(volt_dec1 ~= nil, "missing volt_dec")
        ok(raw1 ~= nil, "missing raw")
        local volt2, volt_dec2, raw2 = adc2:read()
        ok(volt1 ~= nil, "missing volt")
        ok(volt_dec1 ~= nil, "missing volt_dec")
        ok(raw1 ~= nil, "missing raw")
    end)

    it:should("read in single shot mode, 1 device", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(id, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_6_144V, ads1115.DR_3300SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT)
        local called = false
        local p1, p2, p3
        adc1:startread(function(volt, volt_dec, adc)
            called = true
            p1 = volt
            p2 = volt_dec
            p3 = adc
        end)
        eventually(function()
            ok(called == true, "missing callback")
            ok(p1 ~= nil, "missing volt")
            ok(p2 ~= nil, "missing volt_dec")
            ok(p3 ~= nil, "missing raw")
        end)
    end)


    it:should("cleanup timer when deallocated", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc2 = ads1115.ads1115(id, ads1115.ADDR_VDD)
        adc2:setting(ads1115.GAIN_6_144V, ads1115.DR_8SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT)
        local called = false
        adc2:startread(function(volt, volt_dec, adc)
            called = true
        end)
        eventually(function()
            if wait then
                wait = false
                ok(false)
            end
        end, 1, 250)
        andThen(function()
            ko(called == true, "unexpected call")
        end)
        wait = true
        adc2 = nil
    end)


    it:should("read in single shot mode with hardware conversion ready", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(id, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_6_144V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT, ads1115.CONV_RDY_1)
        local called = false
        local volt, volt_dec, adc
        local function conversion_ready(level, when)
            gpio.trig(alert_pin)
            volt, volt_dec, adc = adc1:read()
            called = true
        end
        gpio.mode(alert_pin, gpio.INT)
        gpio.trig(alert_pin, "down", conversion_ready)
        adc1:startread()
        eventually(function()
            ok(called == true, "missing callback")
            ok(volt ~= nil, "missing volt")
            ok(volt_dec ~= nil, "missing volt_dec")
            ok(adc ~= nil, "missing raw")
        end)
    end)


    it:should("trigger when input value is out of range (window)", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(id, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_1_024V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS, ads1115.COMP_1CONV, -15, 100, ads1115.CMODE_WINDOW)
        local triggered = false
        local volt, volt_dec, adc
        local function comparator_trigger(level, when)
            volt, volt_dec, adc = adc1:read()
            gpio.trig(alert_pin)
            triggered = true
        end
        gpio.mode(alert_pin, gpio.INT, gpio.PULLUP)
        gpio.trig(alert_pin, "down", comparator_trigger)
    end)

    it:should("trigger when input value is out of range (window) - complete", function()
        if _G["mcp4725"] == nil then
            return error("mispec skip: mcp4725 module is missing")
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
        local volt, volt_dec, adc
        local function comparator_trigger(level, when)
            volt, volt_dec, adc = adc1:read()
            gpio.trig(alert_pin)
            triggered = true
        end
        gpio.mode(alert_pin, gpio.INT, gpio.PULLUP)
        gpio.trig(alert_pin, "down", comparator_trigger)
        eventually(function()
            if wait then
                wait = false
                ok(false)
            end
        end, 1, 250)
        andThen(function()
            ko(triggered == true, "unexpected trigger")
        end)
        andThen(function()
            mcp4725.write({A1=1, value=0}) -- trigger
        end)
        eventually(function()
            ok(triggered == true, "missing trigger")
            ok(volt ~= nil, "missing volt")
            ok(volt_dec ~= nil, "missing volt_dec")
            ok(adc ~= nil, "missing raw")
        end, 1, 250)
        wait = true
    end)

    it:should("report invalid argument", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local status, err = pcall(ads1115.ads1015, 1, ads1115.ADDR_GND)
        ko(status, "missing error")
        ok(err:find("bad argument #1", 1, true) ~= nil, "missing error message")

        status, err = pcall(ads1115.ads1015, id, ads1115.ADDR_SDA)
        ko(status, "missing error")
        ok(err:find("found no device", 1, true) ~= nil, "missing error message")

        status, err = pcall(ads1115.ads1015, id, 1)
        ko(status, "missing error")
        ok(err:find("bad argument #2", 1, true) ~= nil, "missing error message")
    end)

    it:should("report invalid argument for specific device", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc2 = ads1115.ads1015(id, ads1115.ADDR_GND)
        -- 1015 does not support 8SPS
        local status, err = pcall(adc2.setting, adc2, ads1115.GAIN_6_144V, ads1115.DR_8SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT)
        ko(status, "missing error")
        -- parameter number is off by 1
        ok(err:find("bad argument #3", 1, true) ~= nil, "missing error message")
    end)

    it:should("report invalid device state when re-initializing without reset", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc2 = ads1115.ads1015(id, ads1115.ADDR_GND)
        local status, err = pcall(adc2.setting, adc2, ads1115.GAIN_6_144V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT)
        ok(status, "setting failed")
        status, err = pcall(ads1115.ads1015, id, ads1115.ADDR_GND)
        ko(status, "missing error")
        ok(err:find("please reset device before calling this function", 1, true) ~= nil, "missing error message")
    end)

end)

mispec.run()
