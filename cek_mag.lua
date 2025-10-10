------------------------------------------------------------
-- 🧭 Magplant Stock Scanner + Safe Pathing (Anti-Cheat)
-- by Bos Muda 🧠🔥
------------------------------------------------------------

-- ⚙️ SETTINGS
IDs =104            -- Background ID yang ada di belakang Magplant
SpeedCheck = 50    -- Delay antar scan (rekomendasi 250–300 untuk >10 Magplant)

local CurrentStock, Mags = {}, {}
local worldX, worldY = GetTile(199, 199) and 199 or 99, GetTile(199, 199) and 199 or 59



local function sign(n)
    if n > 0 then return 1 elseif n < 0 then return -1 else return 0 end
end

local function stepSize(dist)
    if dist > 50 then
        return 2
    elseif dist > 20 then
        return 1.5
    elseif dist > 10 then
        return 1
    else
        return 0.5
    end
end

local function intToString(i)
    return tostring(i):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

------------------------------------------------------------
-- 🚶 Smart Pathing Function (Anti-Cheat)
------------------------------------------------------------

local function malastpgw(x, y)
    local px = math.floor(GetLocal().pos.x / 32)
    local py = math.floor(GetLocal().pos.y / 32)
    local tol = 1
    local maxSpeed = 12

   

    local stuckCount = 0
    local maxTry = 150 -- batas supaya gak infinite loop

    while (math.abs(x - px) > tol or math.abs(y - py) > tol) and stuckCount < maxTry do
        local dx = x - px
        local dy = y - py
        local dist = math.max(math.abs(dx), math.abs(dy))
        local step = stepSize(dist)

        if math.abs(dx) > tol then px = px + sign(dx) * math.min(step, math.abs(dx)) end
        if math.abs(dy) > tol then py = py + sign(dy) * math.min(step, math.abs(dy)) end

        local minDelay = math.floor(1100 / maxSpeed)
        local delayMove
        if dist > 10 then
            delayMove = minDelay + math.random(40, 70)
        elseif dist > 5 then
            delayMove = minDelay + 50 + math.random(10, 40)
        else
            delayMove = minDelay + 50 + math.random(20, 40)
        end

        FindPath(px, py)
        Sleep(delayMove)

        local lx = math.floor(GetLocal().pos.x / 32)
        local ly = math.floor(GetLocal().pos.y / 32)
        if math.abs(lx - px) < 2 and math.abs(ly - py) < 2 then
            stuckCount = stuckCount + 1
        else
            stuckCount = 0
        end
    end

    FindPath(x, y)
end

------------------------------------------------------------
-- 📦 Hook untuk ambil stok item di Magplant
------------------------------------------------------------
AddHook("onvariant", "calculate", function(var)
    if var[0] == "OnDialogRequest" and var[1]:find("MAGPLANT 5000") then
        var[1] = var[1]:gsub("`.", "") -- hapus warna

        local Names, theIDs = var[1]:match("add_label_with_icon|small|([^|]+)|left|(%d+)|")
        local CheckStock = var[1]:match("Stock: (%d+) items.")

        if Names and theIDs and CheckStock then
            CurrentStock[theIDs] = CurrentStock[theIDs] or { name = Names, stock = 0 }
            CurrentStock[theIDs].stock = CurrentStock[theIDs].stock + tonumber(CheckStock)
        end

        return true
    end
    return false
end)

------------------------------------------------------------
-- 🔍 Cari semua Magplant di world berdasarkan Background ID
------------------------------------------------------------
local foundMag = false

for y = worldY, 0, -1 do
    for x = 0, worldX do
        local tile = GetTile(x, y)
        if tile.fg == 5638 and tile.bg == IDs then
            table.insert(Mags, { x = x, y = y })
            foundMag = true
        end
    end
end

if not foundMag then
    LogToConsole("`w[ `4ERROR `w] Tidak ada `cMagplant `wyang cocok dengan background `2" .. IDs)
    LogToConsole("`wPastikan ID background benar.")
    return
end

------------------------------------------------------------
-- ⏳ Auto adjust delay jika Magplant banyak
------------------------------------------------------------
if #Mags > 100 then
    SpeedCheck = 50
    LogToConsole("[ `4WARNING `$] `wAuto-adjust delay ke `c100ms `wuntuk stabilitas.")
end

------------------------------------------------------------
-- 🚀 Jalankan proses scanning
------------------------------------------------------------
LogToConsole("`wMenemukan `2" .. #Mags .. " `cMagplant.")
LogToConsole("[`wEstimasi durasi: `2" .. math.ceil((#Mags * (SpeedCheck * 2)) / 1000) .. " detik`$]")

for index, coord in ipairs(Mags) do
    local x, y = coord.x, coord.y

    -- Gerak ke magplant dengan path alami (anti cheat)
    malastpgw(x, y-1)
    

    -- Buka magplant (wrench)
    SendPacketRaw(false, { px = x, py = y, x = x * 32, y = y * 32, state = 32 })
    Sleep(SpeedCheck)
    SendPacketRaw(false, { type = 3, value = 32, px = x, py = y, x = x * 32, y = y * 32 })
    Sleep(SpeedCheck)

    LogToConsole(string.format("`wProgress [`2%d`w/`2%d`w] Magplant di (%d,%d) selesai discan.",
        index, #Mags, x, y))
end

------------------------------------------------------------
-- 📊 Urutkan stok item dari terbesar ke terkecil
------------------------------------------------------------
local sortedStock = {}
for id, data in pairs(CurrentStock) do
    table.insert(sortedStock, { id = id, name = data.name, stock = data.stock })
end

table.sort(sortedStock, function(a, b)
    return a.stock > b.stock
end)

------------------------------------------------------------
-- 💬 Tampilkan hasil scanning dalam dialog
------------------------------------------------------------
local dialog = {
    "add_label_with_icon|big|`wMagplant discan: `2" .. #Mags .. " |left|5638|",
    "add_label_with_icon|big|`wEstimasi waktu: `2" ..
        math.ceil(((#Mags * (SpeedCheck * 2)) / 1000) + 1) .. " detik|left|7864|",
    "add_spacer|small|",
}

for _, data in ipairs(sortedStock) do
    table.insert(dialog,
        "add_label_with_icon|small|`w[`c" .. intToString(data.stock) ..
        " `w] `7" .. data.name .. "|left|" .. data.id .. "|")
end

table.insert(dialog, "end_dialog|magplant_stock|Exit|")
SendVariantList({ [0] = "OnDialogRequest", [1] = table.concat(dialog, "\n") })

LogToConsole("`wScan selesai! Hasil ditampilkan dalam dialog.")
