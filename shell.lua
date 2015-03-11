local function announceTermMonitor(msgT, msgM, scale)
    term.clear()
    term.setCursorPos(1,1)
    term.write(msgT)
    term.setCursorPos(1,3)
        if peripheral.getType(positions[i]) == "monitor" then
            local mon = peripheral.wrap(positions[i])
            if mon then
                mon.setTextScale(scale)
                mon.clear()
                mon.setCursorPos(1,1)
                mon.write(msgM)
                mon.setCursorPos(1,3)
            end
        end
    end
end


announceTermMonitor("Glass Console", "", 1)
term.setCursorPos(1,2)
term.write("Shell 2015.1.01.a/turtle Alpha")
term.setCursorPos(1,4)
sleep(0.1)
shell.run("shell")