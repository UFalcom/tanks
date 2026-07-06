-- (Launcher, Updater & Self-Installer)
-- ASCII/English Only to avoid encoding issues in CC: Tweaked

local LAUNCHER_PASTE = "install.lua"
local SERVER_PASTE = "server.lua"
local CLIENT_PASTE = "client.lua"

local LAUNCHER_FILE = "tanks.lua"
local SERVER_FILE = "server_tanks.lua"
local CLIENT_FILE = "client_tanks.lua"


local function downloadFile(pasteId, filename)
    if not http then
        term.setTextColor(colors.red)
        print("Error: HTTP API is disabled in computer config!")
        return false
    end

    term.setTextColor(colors.yellow)
    print("Downloading " .. filename .. "...")
    
    local url = "https://raw.githubusercontent.com/UFalcom/tanks/refs/heads/main/gameside/" .. pasteId
    local response, err = http.get(url)
    
    if not response then
        term.setTextColor(colors.red)
        print("Failed to download " .. filename)
        print("Error: " .. tostring(err))
        return false
    end
    
    local file = fs.open(filename, "w")
    file.write(response.readAll())
    file.close()
    response.close()
    
    term.setTextColor(colors.green)
    print("Successfully saved " .. filename)
    return true
end


local function checkSelfInstallation()
    if not fs.exists(LAUNCHER_FILE) then
        term.setTextColor(colors.cyan)
        print("Launcher is not installed locally.")
        print("Installing shortcut as '" .. LAUNCHER_FILE .. "'...")
        local success = downloadFile(LAUNCHER_PASTE, LAUNCHER_FILE)
        if success then
            term.setTextColor(colors.green)
            print("Successfully installed! Now you can run it using: plunder")
            sleep(1.5)
        else
            term.setTextColor(colors.red)
            print("Warning: Could not create 'plunder' shortcut.")
            sleep(2)
        end
    end
end

local function verifyFiles()
    local missing = false
    if not fs.exists(SERVER_FILE) then
        print(SERVER_FILE .. " is missing.")
        missing = true
    end
    if not fs.exists(CLIENT_FILE) then
        print(CLIENT_FILE .. " is missing.")
        missing = true
    end

    if missing then
        term.setTextColor(colors.cyan)
        print("\nRequired game files are missing. Starting download...")
        local ok1 = downloadFile(SERVER_PASTE, SERVER_FILE)
        local ok2 = downloadFile(CLIENT_PASTE, CLIENT_FILE)
        if ok1 and ok2 then
            term.setTextColor(colors.green)
            print("All files downloaded successfully!")
            sleep(1.5)
        else
            term.setTextColor(colors.red)
            print("Download failed. Check internet connection.")
            print("Press any key to return to menu...")
            os.pullEvent("key")
        end
    end
end

local function drawMenu()
    term.clear()
    term.setCursorPos(1, 1)
    
    term.setTextColor(colors.cyan)
    print("=================================")
    print("     PIXEL TANKS LAUNCHER      ")
    print("=================================")
    term.setTextColor(colors.white)
    print("\nChoose what to run:")
    
    term.setTextColor(colors.lime)
    print("[1] Run CLIENT (Play Game)")
    
    term.setTextColor(colors.orange)
    print("[2] Run SERVER (Host Game)")
    
    term.setTextColor(colors.yellow)
    print("[3] Force Update (Re-download All)")
    
    term.setTextColor(colors.red)
    print("[4] Exit")
    
    term.setTextColor(colors.gray)
    print("---------------------------------")
    term.setTextColor(colors.white)
    write("Enter your choice (1-4): ")
end


checkSelfInstallation()


while true do
    
    verifyFiles()
    
    drawMenu()
    
    local event, char = os.pullEvent("char")
    
    if char == "1" then
        if fs.exists(CLIENT_FILE) then
            term.clear()
            term.setCursorPos(1,1)
            shell.run(CLIENT_FILE)
        else
            term.setTextColor(colors.red)
            print("\nError: Client file not found!")
            sleep(2)
        end
        
    elseif char == "2" then
        if fs.exists(SERVER_FILE) then
            term.clear()
            term.setCursorPos(1,1)
            shell.run(SERVER_FILE)
        else
            term.setTextColor(colors.red)
            print("\nError: Server file not found!")
            sleep(2)
        end
        
    elseif char == "3" then
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.cyan)
        print("Forcing redownload of all files...")
        downloadFile(LAUNCHER_PASTE, LAUNCHER_FILE)
        downloadFile(SERVER_PASTE, SERVER_FILE)
        downloadFile(CLIENT_PASTE, CLIENT_FILE)
        sleep(2)
        
    elseif char == "4" then
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.white)
        print("Goodbye!")
        break
    end
end
