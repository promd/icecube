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
ver    = "0.0.6"

------ NO CONFIGURATION BELOW ----------

-- switch off LED
ws2812.writergb(led, string.char(0, 0, 0))
ws2812.writergb(led, string.char(0, 0, 0))

-- Function to gather information and send a message
function sendMessage(event)
    print("[PROG] SendMessage("..event..") started")
    -- get Temperature and Hunidity
    status,temp,humi,temp_decimial,humi_decimial = dht.read(dhtpin)
    tmr.delay(40)
    
    if( status == dht.OK ) then
        print("temp:"..temp)
        print("humi:"..humi)
    elseif( status == dht.ERROR_CHECKSUM ) then
        print( "DHT Checksum error." )
    elseif( status == dht.ERROR_TIMEOUT ) then
        print( "DHT Time out." )
    end

    po_string = '{ "temp": "'..temp..'", "voltage": "'..adc.readvdd33()..'", "humidity": "'..humi..'", "event" : "'..event..'", "version" : "'..ver..'" }'
    post_length = string.len(po_string)
    
    msg = "POST /cubes/"..cube.." HTTP/1.1\r\nHost: "..server.."\r\n"
    .."Connection: keep-alive\r\nkeep-alive: 1\r\nPragma: no-cache\r\n"
    .."Cache-Control: no-cache\r\nContent-Type: application/json"
    .."\r\nContent-Length: "..post_length.."\r\nAccept: */*\r\n\r\n"
    ..po_string

    print("[WiFi] Waking up")
    wifi.sleeptype(wifi.NONE_SLEEP)
    tmr.delay(200)

    print("[PORT] create connection")
    conn=net.createConnection(net.TCP, false)

    conn:on("connection", function(conn, pl)
        print("[PORT] Connected - Sending Message")
        print(po_string)
        conn:send(msg)
    end)
    conn:on("disconnection", function(conn, pl) 
        print("[WiFi] Putting WiFi at sleep")
        conn = nil
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
wifi.sta.eventMonReg(wifi.STA_CONNECTING, function() print("[WiFi] STATION_CONNECTING") end)
wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function() print("[WiFi] STATION_WRONG_PASSWORD") end)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function() print("[WiFi] STATION_NO_AP_FOUND") end)
wifi.sta.eventMonReg(wifi.STA_FAIL, function() print("[WiFi] STATION_CONNECT_FAIL") end)
wifi.sta.eventMonReg(wifi.STA_GOTIP, function() 
    print("[WiFi] STATION_GOT_IP : "..wifi.sta.getip()) 
    ws2812.writergb(led, string.char(0, 0, 0))
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

-- init PIR (our Trigger - keep at the end)
pir_proc = 0
print("[PIR] starting event monitoring") 
gpio.mode(pir, gpio.OUTPUT)
gpio.write(pir, gpio.LOW)
gpio.mode(pir,gpio.INT)
gpio.trig(pir,"both",function(ev)
    tmr.delay(150)
    conf = gpio.read(pir)
    if pir_proc == 0 then
        pir_proc = 1
        print("--- MOTION DETECTED ("..ev.."-"..conf..") ---")
        if (conf == 1) then
            -- pir changed to "busy"
            ws2812.writergb(led, string.char(0, 100, 0))
            sendMessage("occupied")
        else
            -- pir changed to "idle"
            ws2812.writergb(led, string.char(100, 0, 0))
            sendMessage("free")
        end
        pir_proc = 0
    end
end)

-- init MAG (our 2nd Trigger - keep at the end)
blo_proc = 0
print("[MAG] starting event monitoring") 
gpio.mode(mag, gpio.OUTPUT)
gpio.write(mag, gpio.LOW)
gpio.mode(mag,gpio.INT)
gpio.trig(mag,"up",function()
    if blo_proc == 0 then
        blo_proc = 1
        print("--- Room Blocked ---")
        sendMessage("blocked")
        ws2812.writergb(led, string.char(100, 100, 0))
        tmr.alarm(1, 300000, 0, function() 
            print("Room Free after block") 
            ws2812.writergb(led, string.char(100, 0, 0))
            sendMessage("free")
        end )
        blo_proc = 0
    end
end)
