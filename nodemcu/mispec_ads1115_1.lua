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

    it:should("read in continuous mode, 1 device", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(0, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_6_144V, ads1115.DR_3300SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS)
        local volt, volt_dec, raw, sign = adc1:read()
        mispec.ok(volt ~= nil, "missing volt")
        mispec.ok(raw ~= nil, "missing raw")
        if mispec.float_build then
            mispec.ok(volt_dec == nil, "volt_dec not nil")
            mispec.ok(sign == nil, "sing not nil")
        else
            mispec.ok(volt_dec ~= nil, "volt_dec is nil")
            mispec.ok(sign ~= nil, "sing is nil")
        end

    end)

    it:should("handle 2 devices", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(0, ads1115.ADDR_GND)
        local adc2 = ads1115.ads1115(0, ads1115.ADDR_VDD)
        adc1:setting(ads1115.GAIN_6_144V, ads1115.DR_3300SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS)
        adc2:setting(ads1115.GAIN_6_144V, ads1115.DR_128SPS, ads1115.DIFF_0_3, ads1115.CONTINUOUS)
        local volt1, volt_dec1, raw1, sign1 = adc1:read()
        mispec.ok(volt1 ~= nil, "missing volt")
        mispec.ok(raw1 ~= nil, "missing raw")
        if mispec.float_build then
            mispec.ok(volt_dec1 == nil, "volt_dec not nil")
            mispec.ok(sign1 == nil, "sing not nil")
        else
            mispec.ok(volt_dec1 ~= nil, "volt_dec is nil")
            mispec.ok(sign1 ~= nil, "sing is nil")
        end
        local volt2, volt_dec2, raw2, sign2 = adc2:read()
        mispec.ok(volt2 ~= nil, "missing volt")
        mispec.ok(raw2 ~= nil, "missing raw")
        if mispec.float_build then
            mispec.ok(volt_dec2 == nil, "volt_dec not nil")
            mispec.ok(sign2 == nil, "sing not nil")
        else
            mispec.ok(volt_dec2 ~= nil, "volt_dec is nil")
            mispec.ok(sign2 ~= nil, "sing is nil")
        end
    end)

    it:should("read in single shot mode, 1 device", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc1 = ads1115.ads1015(id, ads1115.ADDR_GND)
        adc1:setting(ads1115.GAIN_6_144V, ads1115.DR_3300SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT)
        local called = false
        local p1, p2, p3, p4
        adc1:startread(function(volt, volt_dec, adc, sign)
            called = true
            p1 = volt
            p2 = volt_dec
            p3 = adc
            p4 = sign
        end)
        mispec.eventually(function()
            mispec.ok(called == true, "missing callback")
            mispec.ok(p1 ~= nil, "missing volt")
            mispec.ok(p3 ~= nil, "missing raw")
            if mispec.float_build then
                mispec.ok(p2 == nil, "volt_dec not nil")
                mispec.ok(p4 == nil, "sing not nil")
            else
                mispec.ok(p2 ~= nil, "volt_dec is nil")
                mispec.ok(p4 ~= nil, "sing is nil")
            end
        end)
    end)

    it:should("cleanup timer when deallocated", function()
        local id, scl, sda, alert_pin = 0, 1, 2, 3
        i2c.setup(id, sda, scl, i2c.SLOW)
        ads1115.reset()
        local adc2 = ads1115.ads1115(id, ads1115.ADDR_VDD)
        adc2:setting(ads1115.GAIN_6_144V, ads1115.DR_8SPS, ads1115.DIFF_0_3, ads1115.SINGLE_SHOT)
        local called = false
        adc2:startread(function(volt, volt_dec, adc, sign)
            called = true
        end)
        local wait = true
        mispec.eventually(function()
            if wait then
                wait = false
                mispec.ok(false)
            end
        end, 1, 250)
        mispec.andThen(function()
            mispec.ko(called == true, "unexpected call")
        end)
        adc2 = nil
    end)


end)

mispec.run()
