local tbl = {}
local currentIndex = 0

local rewindSpeed = 0.5

local rewindPos = Vector(0,0,0)

function Spawn()
    thisEntity:SetContextThink("TriangleTest", TriangleTest, 0)
end

function TriangleTest()
    
    if currentIndex < 100 and GetPhysVelocity(thisEntity).x > Vector(0,0,0).x then
        
        tbl[currentIndex] = thisEntity:GetAbsOrigin()
        
        currentIndex = currentIndex + 1
    elseif GetPhysVelocity(thisEntity).x > Vector(0,0,0).x then
        --currentIndex = 0
    end

    --print("current index: ", currentIndex)
    --print("vector: ", tbl[currentIndex-1])
    print(thisEntity:GetName())

    return 0.5
end

function Rewind()
    thisEntity:SetContextThink("ThinkRewind", ThinkRewind, 0)
    thisEntity:StopThink("TriangleTest")
    thisEntity:SetMass(0)
    
    
end

function ThinkRewind()
    --thisEntity:DisableMotion()
    
    if currentIndex > 2 then
        rewindPos = tbl[currentIndex-2]
        
        thisEntity:SetOrigin(rewindPos)
        currentIndex = currentIndex - 1
    elseif currentIndex == 2 then
        thisEntity:StopThink("ThinkRewind")
        thisEntity:SetContextThink("TriangleTest", TriangleTest, 0)
    end

    print (rewindPos)

    return rewindSpeed
end