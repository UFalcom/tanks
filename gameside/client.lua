-- client.lua (Tanks PvP Client - CC:Tweaked)
local PROTOCOL = "tanks_pvp_v1"
local modem = peripheral.find("modem")
if not modem then 
    error("Modem not found! Connect and activate your modem.") 
end
rednet.open(peripheral.getName(modem))

print("Searching for Arena Server...")
local serverID = rednet.lookup(PROTOCOL, "game_server")
if not serverID then 
    error("Server not found! Ensure server is running.") 
end

term.clear()
term.setCursorPos(1, 1)
write("Enter your Pilot Name: ")
local name = read()
if name == "" then name = "Tanker_" .. os.getComputerID() end

local myID = os.getComputerID()
rednet.send(serverID, {type = "join", name = name}, PROTOCOL)

-- Collor
local function getPlayerColor(colorIndex)
    local colorsList = {
        colors.lime,      -- 1
        colors.cyan,      -- 2
        colors.magenta,   -- 3
        colors.orange,    -- 4
        colors.yellow,    -- 5
        colors.red,       -- 6
        colors.lightBlue, -- 7
        colors.purple     -- 8
    }
    return colorsList[colorIndex] or colors.white
end


local function draw(state)
    if not state then return end
    term.clear()
    
    
    local renderGrid = {}
    for y = 1, state.height do
        renderGrid[y] = {}
        for x = 1, state.width do
            local cell = state.board[y][x]
            local char = "."
            local col = colors.gray
            if cell == "X" then
                char = "X"
                col = colors.lightGray
            elseif cell == "#" then
                char = "#"
                col = colors.red
            end
            renderGrid[y][x] = {char = char, color = col}
        end
    end

   
    for _, b in ipairs(state.bullets) do
        if b.y >= 1 and b.y <= state.height and b.x >= 1 and b.x <= state.width then
            renderGrid[b.y][b.x] = {char = "o", color = colors.yellow}
        end
    end

   
    for pid, p in pairs(state.players) do
        if not p.dead then
            renderGrid[p.y][p.x] = {char = p.dir, color = getPlayerColor(p.colorIndex)}
        end
    end

 
    term.setCursorPos(1, 1)
    term.setTextColor(colors.white)
    write("TANKS PVP | ")
    local me = state.players[myID]
    if me then
        term.setTextColor(getPlayerColor(me.colorIndex))
        write(me.name)
        term.setTextColor(colors.white)
        write(" | HP: ")
        if me.dead then
            term.setTextColor(colors.red)
            write("DEAD")
        else
            term.setTextColor(colors.green)
            write(string.rep("I", me.hp))
        end
    end

  
    for y = 1, state.height do
        term.setCursorPos(1, y + 1)
        for x = 1, state.width do
            local cell = renderGrid[y][x]
            term.setTextColor(cell.color)
            write(cell.char .. " ") 
        end
    end

    
    local statsY = state.height + 3
    term.setCursorPos(1, statsY)
    term.setTextColor(colors.yellow)
    write("--- LEADERBOARD ---")
    
    local line = statsY + 1
    local count = 0
    for _, p in pairs(state.players) do
        term.setCursorPos((count % 2) * 25 + 1, line)
        term.setTextColor(getPlayerColor(p.colorIndex))
        local status = p.dead and "DEAD" or ("HP:" .. string.rep("I", p.hp))
        write(string.format("%s: %d Kills (%s)", p.name:sub(1, 8), p.score, status))
        count = count + 1
        if count % 2 == 0 then
            line = line + 1
        end
    end
    
    
    term.setCursorPos(1, line + 1)
    if not state.started then
        term.setTextColor(colors.yellow)
        print("Press ENTER to START the game!")
    else
        term.setTextColor(colors.gray)
        print("W/A/S/D to Move/Aim | SPACE to Shoot")
    end
end


parallel.waitForAny(
 
    function()
        while true do
            local _, key = os.pullEvent("key")
            if key == keys.w then rednet.send(serverID, {type="move", dir="up"}, PROTOCOL)
            elseif key == keys.s then rednet.send(serverID, {type="move", dir="down"}, PROTOCOL)
            elseif key == keys.a then rednet.send(serverID, {type="move", dir="left"}, PROTOCOL)
            elseif key == keys.d then rednet.send(serverID, {type="move", dir="right"}, PROTOCOL)
            elseif key == keys.space then rednet.send(serverID, {type="shoot"}, PROTOCOL)
            elseif key == keys.enter then rednet.send(serverID, {type="start"}, PROTOCOL)
            end
        end
    end,
   
    function()
        while true do
            local id, msg = rednet.receive(PROTOCOL)
            if id == serverID then
                draw(msg)
            end
        end
    end
)
