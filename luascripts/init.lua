-- SOS pin. pull up to delete init.lua
sos = 4 --GPIO 2

-- Emergency break: delete init.lua to have clean start !
gpio.mode(sos, gpio.OUTPUT)
gpio.write(sos, gpio.LOW)
gpio.mode(sos,gpio.INT)
gpio.trig(sos,"up",function()
    print("--- EMERGENCY BREAK ACTIVATED ---")
    file.remove("init.lua")
end)

dofile("init_prod.lua")
