local base = "https://raw.githubusercontent.com/vxrm/NovolineForRoblox/refs/heads/Main/"

if isfile('Novoline/core.lua') then
    loadfile('Novoline/core.lua')()
    return
end

local function getDownload(file)
    file = file:gsub('Novoline/', '')

    local suc, ret = pcall(function()
        return game:HttpGet(base .. file)
    end)

    return suc and ret or 'print("Failed to get ' .. file..'")'
end

local function downloadFile(file)
    file = 'Novoline/' .. file

    if not isfile(file) then
        writefile(file, getDownload(file))
    end

    repeat task.wait() until isfile(file)

    return readfile(file)
end

local function debugDownloadSuccess(file)
    local File = downloadFile(file)

    if isfile('Novoline/' .. file) then
        print('[Novoline]: Successfully downloaded', file)
    else
        print('[Novoline]: Failed to download', file)
    end

    return File
end

for i,v in {'Novoline', 'Novoline/games', 'Novoline/configs', 'Novoline/assets', 'Novoline/guis', 'Novoline/libraries'} do
    if not isfolder(v) then
        makefolder(v)
    end
end

local files = {'chosenui.txt', 'games/BedFight.lua', 'games/Universal.lua', 'guis/Novoline.lua''}

do
    for i,v in files do
        if not isfile('Novoline/'..v) then
            downloadFile(v)
        end
    end
end

return loadstring(downloadFile('core.lua'))()
