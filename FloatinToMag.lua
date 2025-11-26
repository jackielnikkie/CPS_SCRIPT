
local magX, magY = 8, 197
itemid = 15954

local function sign(n)
    if n > 0 then return 1 elseif n < 0 then return -1 else return 0 end
end

local function stepSize(dist)
    if dist > 20 then
        return 2
    elseif dist > 10 then
        return math.random(1, 2)
    else
        return 1
    end
end

function FP(targetX, targetY)
    local px = math.floor(GetLocal().pos.x / 32)
    local py = math.floor(GetLocal().pos.y / 32)
    local maxSpeed = 12
    local tol = 1

    while math.abs(targetX - px) > tol or math.abs(targetY - py) > tol do
        local dx, dy = targetX - px, targetY - py
        local dist = math.max(math.abs(dx), math.abs(dy))
        local step = stepSize(dist)

        if math.abs(dx) > tol then px = px + sign(dx) * math.min(step, math.abs(dx)) end
        if math.abs(dy) > tol then py = py + sign(dy) * math.min(step, math.abs(dy)) end

        local minDelay = math.floor(1000 / maxSpeed)
        local delayMove

        if dist > 20 then
            delayMove = minDelay + math.random(40, 90)
        elseif dist > 10 then
            delayMove = minDelay + 50 + math.random(20, 60)
        else
            delayMove = minDelay + 70 + math.random(10, 40)
        end

        Sleep(delayMove)
        FindPath(px, py)
    end

    FindPath(targetX, targetY)
end

function inv(id)
    for _, item in pairs(GetInventory()) do
        if item.id == id then
            return item.amount
        end
    end
    return 0
end



local function getFloat(id)
    for _, obj in pairs(GetObjectList()) do
        if obj.id == id then
            local ox, oy = math.floor(obj.pos.x / 32), math.floor(obj.pos.y / 32)
            FP(ox, oy)
            Sleep(150)

           
            if inv(id) >= 250 then
                SendPacket(2, "action|magplant_edit\nx|" .. magX .. "|\ny|" .. magY .. "|")
                Sleep(300)
                SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|" .. magX .. "|\ny|" .. magY .. "|\nbuttonClicked|additems")
                LogToConsole("Item " .. id .. " Kau cina aku jawa, succes add to magplant")
                return true -- keluar dari getFloat
            end
        end
    end
    return false -- belum penuh
end


while true do
    local done = getFloat(itemid)
    if done then
        Sleep(1000)
    else
        Sleep(300)
    end
end
