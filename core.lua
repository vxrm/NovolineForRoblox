local Gui

repeat task.wait() until isfile('Novoline/chosenui.txt')
Gui = readfile('Novoline/chosenui.txt')

if shared.GuiLibrary then
    shared.GuiLibrary.Uninject(false)
	task.wait(0.5) -- more consistent maybe I hope
end

if not shared.sent then
    shared.sent = game:GetService('Players').LocalPlayer.OnTeleport:Connect(function(teleportState, placeId, spawnName)
        queue_on_teleport([[loadfile('Novoline/core.lua')()]])
    end)
end

local GuiLibrary = loadfile('Novoline/guis/'..readfile('Novoline/chosenui.txt')..'.lua')()

local Combat = GuiLibrary:CreateWindow("Combat")
local Player = GuiLibrary:CreateWindow("Player")
local Movement = GuiLibrary:CreateWindow("Movement")
local Visuals = GuiLibrary:CreateWindow("Visuals")
local Utility = GuiLibrary:CreateWindow("Utility")
local Exploit = GuiLibrary:CreateWindow("Exploit")

Uninject = Utility:CreateModule({
	['Name'] = 'Uninject',
	['Function'] = function(callback)
        if callback then
            GuiLibrary.Uninject(Reload.Enabled)
        end
    end
})
Reload = Uninject.CreateToggle({
    ['Name'] = 'Reload'
})

ClickGui = Visuals:CreateModule({
    ['Name'] = 'ClickGui',
    ['Function'] = function(callback)
        if callback then
            GuiLibrary.Uninject(true)
        end
    end
})
ClickGui.CreatePicker({
    ['Name'] = 'Mode',
    ['Options'] = {'AutumnV1', 'Moon3'},
    ['Function'] = function(Value: string)
        writefile('AutumnV3/chosenui.txt', Value:lower())
    end
})

local Games = {
    ['BedFight'] = {71480482338212, 71657866091528},
    ['Bedwars'] = {8444591321, 8560631822, 6872274481}
}

loadfile('Novoline/games/Universal.lua')()
for gName, Tab in Games do
    for _, id in Tab do
        if game.PlaceId == id then
            loadfile('Novoline/games/'..gName..'.lua')()
            break
        end
    end
end

