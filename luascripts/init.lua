-- SOS pin. pull up to delete init.lua
sos = 4 --GPIO 2
-- LED pin
led = 1 --GPIO 5
-- DHT11 pin
dhtpin = 6 --GPIO 12
-- PIR pin
pir = 5 --GPIO 14
-- Magnetic sensor
mag = 7 --GPIO 13

-- Wifi and server Details
ssid   = "ic"
pwd    = "innovationcave"

-- iceCube network settings
cube   = "proto1"
server = "192.168.90.1"
port   = 3000
-- version of this script
ver    = "0.0.3"

------ NO CONFIGURATION BELOW ----------

-- switch off LED
ws2812.writergb(led, string.char(0, 0, 0))

-- Function to gather information and send a message
function sendMessage(event)
    print("[PROG] SendMessage("..event..") started")
    -- get voltage in mV (internal ADC pin!)
    volt = adc.readvdd33()
    
    -- get Temperature and Hunidity
    status,temp,humi,temp_decimial,humi_decimial = dht.read(dhtpin)
    
    if( status == dht.OK ) then
        print("volt:"..volt)
        print("temp:"..temp)
        print("humi:"..humi)
    elseif( status == dht.ERROR_CHECKSUM ) then
        print( "DHT Checksum error." )
    elseif( status == dht.ERROR_TIMEOUT ) then
        print( "DHT Time out." )
    end

    --msg = "GET /api/cubes/"..cube.."?temp="..temp.."&voltage="..volt.."&humidity="..humi.." HTTP/1.1\r\nHost: "..server.."\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"

    po_string = '{ "temp": "'..temp..'", "voltage": "'..volt..'", "humidity": "'..humi..'", "event" : "'..event..'", "version" : "'..ver..'" }'
    post_length = string.len(po_string)
    
    msg = "POST /cubes/"..cube.." HTTP/1.1\r\nHost: "..server.."\r\n"
    .."Connection: keep-alive\r\nkeep-alive: 1\r\nPragma: no-cache\r\n"
    .."Cache-Control: no-cache\r\nContent-Type: application/json"
    .."\r\nContent-Length: "..post_length.."\r\nAccept: */*\r\n\r\n"
    ..po_string


    print("[WiFi] Waking up")
    wifi.sleeptype(wifi.NONE_SLEEP)

    print("[PORT] create connection")
    conn=net.createConnection(net.TCP, false)

    conn:on("connection", function(conn, pl)
        print("[PORT] Connected - Sending Message")
        print(msg)
        conn:send(msg)
    end)
    conn:on("disconnection", function(conn, pl) 
        print("[WiFi] Putting WiFi at sleep")
        conn = nil
        ws2812.writergb(led, string.char(0, 0, 100))
        wifi.sleeptype(wifi.MODEM_SLEEP)
    end)
    conn:on("receive", function(conn, pl) 
        print("[PORT] Receiving Data")
        print(pl) 
        conn:close()
    end)
    conn:on("sent", function(conn, pl) 
        print("[PORT] data sent")
    end)
    conn:on("reconnection", function(conn, pl) 
        print("[PORT] reconnected")
        print(pl)         
    end)

    print("[PORT] Connecting")
    conn:connect(port,server)
    
end

--register WiFi callbacks
wifi.sta.eventMonReg(wifi.STA_IDLE, function() print("[WiFi] STATION_IDLE") end)
wifi.sta.eventMonReg(wifi.STA_CONNECTING, function() 
    print("[WiFi] STATION_CONNECTING") 
    r = 0
    dir = 1
    tmr.alarm(0, 10, 1, function() 
        if dir == 1  then r = r+1
        else r = r-1 end
        if r == 100 then dir = 0
        elseif r == 0 then dir = 1
        end 
        ws2812.writergb(led, string.char(r, 0, 0))
    end)    
end)
wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function() print("[WiFi] STATION_WRONG_PASSWORD") end)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function() print("[WiFi] STATION_NO_AP_FOUND") end)
wifi.sta.eventMonReg(wifi.STA_FAIL, function() print("[WiFi] STATION_CONNECT_FAIL") end)
wifi.sta.eventMonReg(wifi.STA_GOTIP, function() 
    print("[WiFi] STATION_GOT_IP : "..wifi.sta.getip()) 
    tmr.stop(0)
    ws2812.writergb(led, string.char(0, 100, 0))
    sendMessage("startup")
end)

-- init Wifi
print("[WiFi] initialize WiFi") 
wifi.setmode(wifi.STATION)
print("[WiFi] starting event monitoring") 
wifi.sta.eventMonStart()
wifi.sleeptype(wifi.NONE_SLEEP)
wifi.sta.config(ssid,pwd)

-- init scheduled update
tmr.alarm(0, 1000 * 60 * 10, 1, function() 
    sendMessage("scheduled")
end)

-- Emergency break: delete init.lua to have clean start !
gpio.mode(sos, gpio.OUTPUT)
gpio.write(sos, gpio.LOW)
gpio.mode(sos,gpio.INT)
gpio.trig(sos,"up",function()
    print("--- EMERGENCY BREAK ACTIVATED ---")
    --tmr.stop(0)
    file.remove("init.lua")
end)

-- init PIR (our Trigger - keep at the end)
print("[PIR] starting event monitoring") 
gpio.mode(pir, gpio.OUTPUT)
gpio.write(pir, gpio.LOW)
gpio.mode(pir,gpio.INT)
gpio.trig(pir,"up",function()
    print("--- MOTION DETECTED ---")
    sendMessage("motion")
end)

-- init MAG (our 2nd Trigger - keep at the end)
print("[MAG] starting event monitoring") 
gpio.mode(mag, gpio.OUTPUT)
gpio.write(mag, gpio.LOW)
gpio.mode(mag,gpio.INT)
gpio.trig(mag,"up",function()
    print("--- DOOR OPEN ---")
    sendMessage("door")
end)
