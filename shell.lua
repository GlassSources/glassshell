--[[
  File:      OS - GlassShell
  Purpose:   The supported and better of TurtleShell Beta 0.3.0.
  Author:    da404lewzer
  Project:   http://turtlescripts.com/project/gjdgyz
  License:   Creative Commons Attribution-ShareAlike 3.0 Unported License.
             http://creativecommons.org/licenses/by-sa/3.0/
]]

local tArgs = { ... }
local version = "1.05"
local betaMsg = "BETA"
local beta = false
local screenSaverTimeout = 10
local key = "" --used for dev
local w, h = 1, 1
local mon, mon2
local menus = {}
local positions = {"top", "bottom", "left", "right", "front", "back"}
local tmpOffset = {"init", "init", "init", "init", "init", "init"}
local customFooterStr = ""
local ss_app = "ss_matrix"
local lastVersion = "" --for tracking updates

local colorList = {}
colorList[1] = {menuText=colors.white,
                menuTextBG=colors.black,
                menuTextHighlight=colors.black,
                menuTextBGHighlight=colors.white,
                pageTitleText=colors.black,
                pageTitleBG=colors.white,
                notifyBarText=colors.black,
                notifyBarBG=colors.white,
                footerText=colors.white,
                footerTextBG=colors.black,}
colorList[2] = {menuText=colors.lightGray,
                menuTextBG=colors.black,
                menuTextHighlight=colors.white,
                menuTextBGHighlight=colors.orange,
                pageTitleText=colors.lime,
                pageTitleBG=colors.black,
                notifyBarText=colors.white,
                notifyBarBG=colors.blue,
                footerText=colors.yellow,
                footerTextBG=colors.black,}
local mainMenuFooter = {
    --{'cmd_market',   'M> TurtleMarket', keys.m, ''},
    {'cmd_exit',     'C> Console', keys.c, ''},
    --{'cmd_ss',     'L> Lock Screen', keys.l},
    --{'cmd_update',   'U> Update OS', keys.u, ''},
    {'cmd_reboot',   'R> Restart', keys.r, ''},
    {'cmd_shutdown', 'S> Shutdown', keys.s, ''}
}
local subMenuFooter = {
    {'mainmenu',     'R> Return to Main Menu', keys.r, ''}
}
local currentMenu = {}
local currentMenuName, currentMenuID

local function array_concat(a1,a2)
    local t = {}
    ii=0
    for i = 1,#a1 do
        ii=ii+1
        t[ii] = a1[i]
    end
    for i = 1,#a2 do
        ii=ii+1
        t[ii] = a2[i]
    end
    return t
end

local fontScale = 1
function cleanUp()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    for i=1, #positions do
        if peripheral.getType(positions[i]) == "monitor" then
            local mon = peripheral.wrap(positions[i])
            if mon then
                mon.setBackgroundColor(colors.black)
                mon.setTextColor(colors.white)
                mon.setTextScale(1)
                mon.clear()
                mon.setCursorPos(1,1)
            end
        end
    end
end
local function announceTermMonitor(msgT, msgM, scale)
    term.clear()
    term.setCursorPos(1,1)
    term.write(msgT)
    term.setCursorPos(1,3)
    for i=1, #positions do
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
cleanUp()
local function split(str, div)
    assert(type(str) == "string" and type(div) == "string", "invalid arguments")
    local o = {}
    while true do
        local pos1,pos2 = str:find(div)
        if not pos1 then
            o[#o+1] = str
            break
        end
        o[#o+1],str = str:sub(1,pos1-1),str:sub(pos2+1-pos1)
    end
    return o
end
local function getColorMode(monitor)
    if monitor.isColor() then
        return 2
    else
        return 1
    end
end
local nextAction = "" --blank for default action, menu
local menuWidth = 10
local running = true
local selected = 1
local startingRow = 4
local pages = 1
local count = #currentMenu
local itemsPerPage = math.ceil(count / pages)
local function loadMenu(mnu)
    currentMenuID = mnu
    selected = 1
    local menu = {}
    local menuHasConfig = false
    if mnu == "main" then
        currentMenuName = "Main Menu"
        n=0
        count = #menus
        if count > 9 then count = 9 end
        for i,v in ipairs(menus) do
            if n < count then
                n=n+1
                menu[n] = {"menu_"..i, n.."> "..v.name, n+1, ''}
            end
        end
        if #menu > 0 then
            menu[n+1] = {'','','',''}
        end
        currentMenu = array_concat(menu, mainMenuFooter)
    else
        n=0
        for i,v in ipairs(menus) do
            if "menu_"..i == mnu then
                currentMenuName = v.name
                count = #v.items
                for ii,vv in ipairs(v.items) do
                    if n < count then
                        n=n+1
                        if vv.config then
                            menuHasConfig = true
                        end
                        menu[n] = {"menucmd_"..i.."_"..ii, n.."> "..vv.name, n+1, vv}
                    end
                end
            end
        end
        if #menu > 0 then
            menu[n+1] = {'','','',''}
        end
        currentMenu = array_concat(menu, subMenuFooter)
    end

    -- Recalc our menu widths
    menuWidth = 1
    for i=1, #currentMenu do
        len = string.len(currentMenu[i][2])
        if currentMenu[i][4] and currentMenu[i][4].config then
            len=len+10 -- add padding for word [C]onfig
        end
        if len > menuWidth then
            menuWidth = len
        end
    end
    count = #currentMenu
    itemsPerPage = math.ceil(count / pages)
end
local showFirstTimeMessage = false
local runcount = 1
    local foundMenus = {}
    local cfg
    if fs.exists("turtleshell/os.db") then
        h = fs.open("turtleshell/os.db", "r")
        while true do
            data = h.readLine()
            if data == nil then break end
            if data == "--[[CONFIG:" then
                config = h.readAll()
                configStr = string.sub(config,1,string.len(config)-2)
                cfg=textutils.unserialize(configStr)
            end
        end
        h.close()
    else
        showFirstTimeMessage = true
    end
    if cfg then
        if cfg["runcount"] then --test
            runcount = cfg["runcount"]+1
        end
        if cfg["lastVersion"] then
            lastVersion = cfg["lastVersion"]
        end
    end
    if fs.exists("turtleshell/os.settings") then
        h = fs.open("turtleshell/os.settings", "r")
        while true do
            data = h.readLine()
            if data == nil then break end
            if data == "--[[CONFIG:" then
                config = h.readAll()
                configStr = string.sub(config,1,string.len(config)-2)
                cfg=textutils.unserialize(configStr)
            end
        end
        h.close()
    else
        showFirstTimeMessage = true
    end
    if cfg then
        if cfg["custom_footer_message"] then
            customFooterStr = cfg["custom_footer_message"]
        end
        if cfg["screensaver"] then
            ss_app = cfg["screensaver"]
        end
        if cfg["menus"] then
            menus = cfg["menus"]
        end
    end
--local function centerText(tY, tText)
    --local offX = w/2 - (string.len(tText) +1)/2
    --mon.setCursorPos(offX+1, tY)
   -- mon.write(tText)
--
local function centerTextWidth(tY, tText, tX, tW)
    local offX = tW/2 - string.len(tText)/2 + tX
    mon.setCursorPos(offX+1, tY)
    mon.write(tText)
end
local function repeatStr(tY, tText, count)
    for i=1, count do
        mon.setCursorPos(i, tY)
        mon.write(tText)
    end
end
local showingMessage = false
local messageToShow = ""
local function showMessage(msg)
    showingMessage = true
    messageToShow = msg
end
local function drawMessage()
    for i=1, h do
        repeatStr(i, "/", w)
    end
    local length = string.len(messageToShow)
    local messageToHide = "[OK]"
    local messageToHideLength = string.len(messageToHide)
    local biggestWidth = length
    if messageToHideLength > length then
        biggestWidth = messageToHideLength
    end
    local offX = w/2 - biggestWidth / 2
    local offX2 = w/2 - length / 2
    local offX3 = w/2 - messageToHideLength / 2
    local offY = h/2
    mon.setBackgroundColor(colors.white)
    mon.setTextColor(colors.black)
    mon.setCursorPos(offX-1,offY-3)
    mon.write("+"..string.rep("-",biggestWidth+2).."+")
    for i=-2, 2 do
        mon.setCursorPos(offX-1,offY+i)
        mon.write("|"..string.rep(" ",biggestWidth+2).."|")
    end
    mon.setCursorPos(offX-1,offY+3)
    mon.write("+"..string.rep("-",biggestWidth+2).."+")
    
    mon.setCursorPos(offX2+1,offY-1)
    mon.write(messageToShow)
    mon.setCursorPos(offX3+1,offY+2)
    mon.write(messageToHide)
    
    -- Ensure we are using the correct colors
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)
end
local lastKeypress = os.clock()
local function launchApp(command, args)
    if command then
        shell.run(command)
        --[[
        if args then
            shell.run(command, args)
        else
            os.run({},command)
        end
        ]]
    end
    cleanUp()
end
local timer
local function showSS()
    launchApp(ss_app)
    lastKeypress = os.clock()
    timer = os.startTimer(0.1)
end
local function doMenuAction(action, doAltAction)
    local item = currentMenu[action]
    if item[1] == "cmd_exit" then
        announceTermMonitor("Starting Console..", "Console [TERM]", 1)
        term.setCursorPos(1,2)
        term.write("To return type: exit")
        term.setCursorPos(1,4)
        sleep(0.1)
        shell.run("shell")
        lastKeypress = os.clock()
        timer = os.startTimer(0.1)
    elseif item[1] == "cmd_update" then
        announceTermMonitor("Updating OS..", "Updating OS [TERM]", 1)
        updateAllTheThings()
        sleep(2)
        os.reboot()
    elseif item[1] == "cmd_ss" then
        showSS()
        lastKeypress = os.clock()
        timer = os.startTimer(0.1)
    elseif item[1] == "cmd_reboot" then
        os.reboot()
    elseif item[1] == "cmd_shutdown" then
        os.shutdown()
    elseif item[1] == "cmd_market" then
        sleep(0.1)
        shell.run("market")
        lastKeypress = os.clock()
        timer = os.startTimer(0.1)
    elseif string.sub(item[1],1,5) == "menu_" then
        loadMenu(item[1])
    elseif string.sub(item[1],1,8) == "menucmd_" then
        if item[4].command == "" then
            showMessage("No command associated!")
        else
            if doAltAction then
                announceTermMonitor("Launching Config for "..item[4].name.."...", item[4].name.." [TERM]", 1)
                launchApp(item[4].config)
            else
                announceTermMonitor("Launching "..item[4].name.."...", item[4].name.." [TERM]", 1)
                launchApp(item[4].command)
            end
            lastKeypress = os.clock()
            timer = os.startTimer(0.1)
        end
    elseif string.sub(item[1],1,8) == "mainmenu" then
        loadMenu("main")
    else
        showMessage("TODO: Not yet implemented")
    end
end
local function lookupHotkeyAction(key)
    for i=1, #currentMenu do
        if currentMenu[i][3] == key then
            selected = i
            doMenuAction(selected)
            break
        end
    end
end
local logo = {
"      cccc                              ";
"     c0cc0c                             ";
"     cccccc     111111 1 11  111 1   111";
" cc   cccc   cc   1  1 1 1 1  1  1   1  ";
"cccc55d55d55cccc  1  1 1 11   1  1   11 ";
" cd5dd5dd5dd5dc   1  1 1 1 1  1  1   1  ";
"  d5dd5dd5dd5d    1  111 1 1  1  111 111";
"  5d55d55d55d5                          ";
"  d5dd5dd5dd5d    3333 3  3 3333 3   3  ";
"  d5dd5dd5dd5d   3     3  3 3    3   3  ";
"  5d55d55d55d5    333  3333 333  3   3  ";
"  d5dd5dd5dd5d       3 3  3 3    3   3  ";
" cc5dd5dd5dd5cc  3333  3  3 3333 333 333";
"cccc55d55d55cccc                        ";
" cc    cc    cc                         ";
}
--[[Stolen Shamelessly from nPaintPro - http://pastebin.com/4QmTuJGU]]
local function getColourOf(hex)
  local value = tonumber(hex, 16)
  if not value then return nil end
  value = math.pow(2,value)
  return value
end
local function drawPictureTable(mon, image, xinit, yinit, alpha)
    if not alpha then alpha = 1 end
	for y=1,#image do
		for x=1,#image[y] do
			mon.setCursorPos(xinit + x-1, yinit + y-1)
			local col = getColourOf(string.sub(image[y], x, x))
			if not col then col = alpha end
            if mon.isColor() then
    			mon.setBackgroundColour(col)
            else
                if string.sub(image[y], x, x) ~= " " then
        	    	mon.setBackgroundColour(colors.black)
                else
                    mon.setBackgroundColour(colors.white)
                end
            end
    		mon.write(" ")
		end
	end
end
--[[End Theft]]
local function splash(monitor)
    mon = monitor
    if mon then
        w, h = mon.getSize()
        local data = {
                "",
                "Glass",
                "SHELL",
                version,
                betaMsg
            }
        --[[if w > 7 and h > 5 then
            logo = { --legacy :(
                '',
                "##  ##  ######  ##  ##",
                "##  ##  ##  ##  ##  ##",
                "######  ##  ##  ######",
                "    ##  ##  ##      ##",
                "    ##  ######      ##",
                " B R A N D    B I O S ",
                " v"..version.." "..betaMsg
            }
            mon.setBackgroundColor(colors.white)
            mon.clear()
            drawPictureTable(mon, logo, w/2 - #logo[1]/2, h/2 - #logo/2, colours.white)
            mon.setTextColor(colors.black)
            centerText(h, "v"..version.." "..betaMsg)
        else
            local x = w/2 - string.len(data[1])/2
            local y = h/2 - #data/2
            mon.clear()
            for i=1, #data do
                centerText(y+i, data[i])
            end
        end]]
    end
end

splash(term)
for i=1, #positions do
    if peripheral.getType(positions[i]) == "monitor" then
        splash(peripheral.wrap(positions[i]))
    end
end

sleep(1.5)
--showSS()
--showMessage("Welcome to CheetOS!")
local function round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end
local function update(monitor, monID)
    mon = monitor
    if mon then
        w, h = mon.getSize()
        local dialogWidth = (menuWidth * pages) + (2 * pages)
        local dialogOffset = (w - dialogWidth)/2;
        -- Overdraw stuff
        if showingMessage then
            --drawMessage()
        else
            cMode = getColorMode(mon)
            mon.clear()
            mon.setBackgroundColor(colorList[cMode].pageTitleBG)
            mon.setTextColor(colorList[cMode].pageTitleText)
            -- Menu Header
            mon.setCursorPos(1,1)
            mon.write(string.rep(" ", w))
            --centerText(1, currentMenuName)
            mon.setBackgroundColor(colorList[cMode].notifyBarBG)
            mon.setTextColor(colorList[cMode].notifyBarText)
            mon.setCursorPos(1,2)
            mon.write(string.rep(" ", w))
            
            -- Mail Messages
            mon.setCursorPos(2,2)
            local msgs = "0 MSGS";
            mon.write(msgs)
            
            -- Time
            local time = os.time()
            timeFmt = textutils.formatTime(time, false)
            timeLen = string.len(timeFmt)
            mon.setCursorPos(w-timeLen,2)
            mon.write(timeFmt)
            

            
            mon.setBackgroundColor(colorList[cMode].menuTextBG)
            mon.setTextColor(colorList[cMode].menuText)
            
            -- Menu Separator
            --repeatStr(2, "-", w)
            
            -- Draw Menu
            local scrollY = 0
            local viewH = h - startingRow - 2
            if #currentMenu > viewH then
                local offset =  viewH / #currentMenu
                scrollY = round(offset * (selected-1))
            end
            local z = scrollY
            for p=1, pages do
                local loopMax = itemsPerPage
                if loopMax > viewH+scrollY then
                    loopMax = viewH+scrollY
                    mon.setCursorPos(w, h-4)
                    mon.write("|")
                    mon.setCursorPos(w, h-3)
                    mon.write("v")
                end
                if scrollY > 0 then
                    loopMax = viewH+scrollY
                    mon.setCursorPos(w, 4)
                    mon.write("^")
                    mon.setCursorPos(w, 5)
                    mon.write("|")
                end
                for n=1+scrollY, loopMax do
                    z=z+1
                    if z <= count then
                        local offsetY = startingRow + (n-1) - scrollY
                        local offsetX = dialogOffset + (menuWidth * (p-1)) + (2 * (p-1))
                        if offsetX < 1 then
                            offsetX = 1
                        end
                        if z == selected then
                            mon.setBackgroundColor(colorList[cMode].menuTextBGHighlight)
                            mon.setTextColor(colorList[cMode].menuTextHighlight)
                            centerTextWidth(offsetY,string.rep(" ",menuWidth + 2), offsetX, menuWidth)
                        else
                            mon.setBackgroundColor(colorList[cMode].menuTextBG)
                            mon.setTextColor(colorList[cMode].menuText)
                        end
                        if currentMenu[z][4] and currentMenu[z][4].config then
                            local width = w/2 - (menuWidth + 2) / 2
                            mon.setCursorPos(width + menuWidth - 7, offsetY)
                            mon.write("[C]onfig")
                        end
                        --centerTextWidth(offsetY, currentMenu[z][2], offsetX, menuWidth)
                        mon.setCursorPos(offsetX+1, offsetY)
                        mon.write(currentMenu[z][2])
                    end
                end
            end
        
            -- Ensure we are using the correct colors
            mon.setBackgroundColor(colorList[cMode].footerTextBG)
            mon.setTextColor(colorList[cMode].footerText)
        
            -- Menu Footer & Seperator
            repeatStr(h-1, "-", w)
            if mon == term then
                footerStr = "UP / DOWN - Pick, ENTER - Select"
                if string.len(footerStr) > w then
                    footerStr = "UP/DN/ENTER"
                end
                --centerText(h, footerStr)
            else
                if tmpOffset[monID] == "init" then
                    tmpOffset[monID] = w
                end
                tmpOffset[monID]=tmpOffset[monID]-1
                if tmpOffset[monID] < -string.len(customFooterStr) then
                    tmpOffset[monID] = w
                end 
                mon.setCursorPos(tmpOffset[monID], h)
                mon.write(customFooterStr)
            end
        end
    end
end
local function updateSM(monitor, monID)
    mon = monitor
    if mon then
        w, h = mon.getSize()
        local dialogWidth = (menuWidth * pages) + (2 * pages)
        local dialogOffset = (w - dialogWidth)/2;
        -- Overdraw stuff
        if showingMessage then
            drawMessage()
        else
            cMode = getColorMode(mon)
            mon.clear()
            mon.setBackgroundColor(colorList[cMode].notifyBarBG)
            mon.setTextColor(colorList[cMode].notifyBarText)
            -- Menu Header
            mon.setCursorPos(1,1)
            mon.write(string.rep(" ", w))
            mon.setCursorPos(1,2)
            mon.write(string.rep(" ", w))
            
            -- Time
            local time = os.time()
            --we want to manually parse am/pm
            timeFmt = textutils.formatTime(time, false)
            local len = string.len(timeFmt)
            local part = string.sub(timeFmt, len-1)
            timeFmt = string.sub(timeFmt, 1, len-3)..part
            timeLen = string.len(timeFmt)
            if w == 7 then
                mon.setCursorPos(w-timeLen+1,1)
            else
                mon.setCursorPos(w-timeLen,2)
            end
            mon.write(timeFmt)
        
            -- Mail Messages
            mon.setCursorPos(2,2)
            mon.write("0 MSGS")
        
            -- Ensure we are using the correct colors
            mon.setBackgroundColor(colorList[cMode].footerTextBG)
            mon.setTextColor(colorList[cMode].footerText)
            
            -- Menu Footer & Seperator
            if mon == term then
                footerStr = "UP / DOWN - Pick, ENTER - Select"
                if string.len(footerStr) > w then
                    footerStr = "UP/DN/ENTER"
                end
                centerText(h, footerStr)
            else
                if tmpOffset[monID] == "init" then
                    tmpOffset[monID] = w
                end
                tmpOffset[monID]=tmpOffset[monID]-1
                if tmpOffset[monID] < -string.len(customFooterStr) then
                    tmpOffset[monID] = w
                end 
                mon.setCursorPos(tmpOffset[monID], h-1)
                mon.write(customFooterStr)
            end
        end
    end
end
local function updateTemplate(monitor, monID)
    if monitor then
        local w,h = monitor.getSize()
        if w and h then
            if w > 7 and h > 5 then
                update(monitor, monID)
            else
                updateSM(monitor, monID)
            end
        end
    end
end
local function updateAll()
    updateTemplate(term, 0)
    for i=1, #positions do
        if peripheral.getType(positions[i]) == "monitor" then
            updateTemplate(peripheral.wrap(positions[i]), i)
        end
    end
end

timer = os.startTimer(0) --redefined higher up for doMenuAction
while running do
    local event, p1, p2 = os.pullEvent()
    mon = term
    if #tArgs > 0 then
      mon2 = peripheral.wrap(tArgs[1])
    end
    if event == "key" then 
        lastKeypress = os.clock()
        if showingMessage then
            showingMessage = false
        else
            if p1 == keys.up then
                selected=selected-1
                if selected < 1 then
                    selected = count
                end
                if currentMenu[selected][1] == "" then
                    selected=selected-1
                    if selected < 1 then
                        selected = count
                    end
                end
            elseif p1 == keys.down then
                selected=selected+1
                if selected > count then
                    selected = 1
                end
                if currentMenu[selected][1] == "" then
                    selected=selected+1
                    if selected > count then
                        selected = 1
                    end
                end
            elseif p1 == keys.enter or p1 == keys.space then
                doMenuAction(selected, false)
            else
                if p1 == keys.c and currentMenu[selected][4] and currentMenu[selected][4].config then
                    doMenuAction(selected, true)
                else
                    lookupHotkeyAction(p1)
                end
            end
        end
    else
    
        if running then
            if ss_app and math.floor(os.clock() - lastKeypress) > screenSaverTimeout then
                -- Run the screensaver
                showSS()
            else
                updateAll()
            end
        end
    end
    if event == "timer" and p1 == timer then
        timer = os.startTimer(0.1)
    end
end

saveSettings()
cleanUp()