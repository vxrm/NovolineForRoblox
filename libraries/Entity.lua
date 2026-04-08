local EntityLib = {}

local Players = game:GetService('Players')

EntityLib.char = Players.LocalPlayer.Character


if EntityLib.char and EntityLib.char.PrimaryPart then
   EntityLib.root = EntityLib.char.PrimaryPart 
end

task.spawn(function()
    repeat
        task.wait()
        pcall(function()
            EntityLib.char = Players.LocalPlayer.Character
            EntityLib.root = EntityLib.char.PrimaryPart
        end)
    until false
end)

EntityLib.isAlive = function(Plr: Player)
    local s, r = pcall(function()
        return Plr.Character.Humanoid.Health > 0
    end)

    return s and r or false
end

EntityLib.getNearestEntity = function(Range: number)
    local Dist, User = math.huge, nil

    for i,v in Players:GetPlayers() do
        if v == Players.LocalPlayer or v.Team == Players.LocalPlayer.Team then continue end
        if not EntityLib.isAlive(v) then continue end

        local Distance = Players.LocalPlayer:DistanceFromCharacter(v.Character.PrimaryPart.Position)

        if Distance <= Range and Distance < Dist then
            Dist = Distance
            User = v
        end
    end

    return User
end

return EntityLib