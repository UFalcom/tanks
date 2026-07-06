-- server.lua (Tanks PvP Server - CC:Tweaked)
local PROTOCOL = "tanks_pvp_v1"

local modem = peripheral.find("modem")
if not modem then 
    error("Modem not found! Attach a modem and activate it.") 
end
rednet.open(peripheral.getName(modem))
rednet.host(PROTOCOL, "game_server")

local gameConfig = {
    width = 24, 
    height = 12,
    maxPlayers = 8, 
    steelWalls = 15, -- Неразрушаемые стены (X)
    brickWalls = 30  -- Разрушаемые стены (#)
}

local board = {}
local players = {} -- id = {name, x, y, dir, hp, score, colorIndex, dead, respawnTick}
local bullets = {} -- {x, y, dx, dy, ownerId}
local gameStarted = false

-- Генерация карты с границами
local function initBoard()
    board = {}
    for y = 1, gameConfig.height do
        board[y] = {}
        for x = 1, gameConfig.width do
            if y == 1 or y == gameConfig.height or x == 1 or x == gameConfig.width then
                board[y][x] = "X" 
            else
                board[y][x] = "."
            end
        end
    end

  
    for i = 1, gameConfig.steelWalls do
        local x = math.random(2, gameConfig.width - 1)
        local y = math.random(2, gameConfig.height - 1)
        board[y][x] = "X"
    end

   
    for i = 1, gameConfig.brickWalls do
        local x = math.random(2, gameConfig.width - 1)
        local y = math.random(2, gameConfig.height - 1)
        if board[y][x] == "." then
            board[y][x] = "#"
        end
    end
end

local function broadcastState()
    local state = {
        width = gameConfig.width,
        height = gameConfig.height,
        board = board, 
        players = players, 
        bullets = bullets,
        started = gameStarted
    }
    rednet.broadcast(state, PROTOCOL)
end


local function findSafeSpawn()
    local x, y
    local attempts = 0
    repeat
        x = math.random(2, gameConfig.width - 1)
        y = math.random(2, gameConfig.height - 1)
        attempts = attempts + 1
        local cellFree = (board[y][x] == ".")
        if cellFree then
            for _, p in pairs(players) do
                if not p.dead and p.x == x and p.y == y then
                    cellFree = false
                    break
                end
            end
        end
    until cellFree or attempts > 100
    return x, y
end


local function updatePhysics()
    local nextBullets = {}
    for _, b in ipairs(bullets) do
        local nx = b.x + b.dx
        local ny = b.y + b.dy
        local hit = false

        if nx < 1 or nx > gameConfig.width or ny < 1 or ny > gameConfig.height then
            hit = true
        else
            local cell = board[ny][nx]
            if cell == "X" then
                hit = true
            elseif cell == "#" then
                board[ny][nx] = "." -- Снаряд уничтожил кирпич!
                hit = true
            else
               
                for pid, p in pairs(players) do
                    if not p.dead and p.x == nx and p.y == ny then
                        hit = true
                        p.hp = p.hp - 1
                        if p.hp <= 0 then
                            p.dead = true
                            p.respawnTick = 30 -- Возрождение через 3 секунды (30 тиков по 100мс)
                            -- Начисление очка стрелявшему
                            if players[b.ownerId] then
                                players[b.ownerId].score = players[b.ownerId].score + 1
                            end
                        end
                        break
                    end
                end
            end
        end

        if not hit then
            b.x = nx
            b.y = ny
            table.insert(nextBullets, b)
        end
    end
    bullets = nextBullets

   
    for pid, p in pairs(players) do
        if p.dead then
            p.respawnTick = p.respawnTick - 1
            if p.respawnTick <= 0 then
                p.dead = false
                p.hp = 3
                p.x, p.y = findSafeSpawn()
            end
        end
    end
end

initBoard()
print("Tanks PvP Server started. Ready for battle!")


parallel.waitForAny(
   
    function()
        while true do
            local id, msg = rednet.receive(PROTOCOL)
            if type(msg) == "table" then
                if msg.type == "join" then
                    local playerCount = 0
                    for _ in pairs(players) do playerCount = playerCount + 1 end

                    if not players[id] and playerCount < gameConfig.maxPlayers then
                        local px, py = findSafeSpawn()
                        players[id] = {
                            name = msg.name,
                            x = px,
                            y = py,
                            dir = "^",
                            hp = 3,
                            score = 0,
                            colorIndex = (playerCount % 8) + 1,
                            dead = false,
                            respawnTick = 0
                        }
                        print("Player '" .. msg.name .. "' connected (ID: " .. id .. ")")
                        broadcastState()
                    end

                elseif msg.type == "start" then
                    if not gameStarted then
                        gameStarted = true
                        bullets = {}
                        for pid, p in pairs(players) do
                            p.hp = 3
                            p.score = 0
                            p.dead = false
                            p.x, p.y = findSafeSpawn()
                        end
                        print("The match has started!")
                    end
                    broadcastState()

                elseif msg.type == "move" and gameStarted then
                    local p = players[id]
                    if p and not p.dead then
                        local nx, ny = p.x, p.y
                        local newDir = p.dir
                        if msg.dir == "up" then ny = ny - 1; newDir = "^"
                        elseif msg.dir == "down" then ny = ny + 1; newDir = "v"
                        elseif msg.dir == "left" then nx = nx - 1; newDir = "<"
                        elseif msg.dir == "right" then nx = nx + 1; newDir = ">"
                        end

                        p.dir = newDir

                        
                        if nx >= 1 and nx <= gameConfig.width and ny >= 1 and ny <= gameConfig.height then
                            local cell = board[ny][nx]
                            local canMove = (cell == ".")
                            if canMove then
                                for opid, op in pairs(players) do
                                    if opid ~= id and not op.dead and op.x == nx and op.y == ny then
                                        canMove = false
                                        break
                                    end
                                end
                            end

                            if canMove then
                                p.x, p.y = nx, ny
                            end
                        end
                        broadcastState()
                    end

                elseif msg.type == "shoot" and gameStarted then
                    local p = players[id]
                    if p and not p.dead then
                        local now = os.epoch("utc")
                        -- Кулдаун стрельбы 400мс
                        if not p.lastShoot or (now - p.lastShoot) > 400 then
                            p.lastShoot = now
                            local dx, dy = 0, 0
                            if p.dir == "^" then dy = -1
                            elseif p.dir == "v" then dy = 1
                            elseif p.dir == "<" then dx = -1
                            elseif p.dir == ">" then dx = 1
                            end
                            table.insert(bullets, {
                                x = p.x,
                                y = p.y,
                                dx = dx,
                                dy = dy,
                                ownerId = id
                            })
                        end
                    end
                end
            end
        end
    end,

  
    function()
        while true do
            os.sleep(0.1)
            if gameStarted then
                updatePhysics()
                broadcastState()
            end
        end
    end
)
