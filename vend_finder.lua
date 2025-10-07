SendPacket(2, "action|input\n|text|`2 Hai SC dari Deepous")
Sleep(3000)

local vendList = {}
local searchQuery = ""
local filterTermurah = false
local itemsPerPage = 30


local function ScanVendings()
    vendList = {}
    for _, tile in pairs(GetTiles()) do
        if tile.fg == 9268 and tile.extra then
            local itemID = tonumber(tile.extra.lastupdate or 0)
            local price = tonumber(tile.extra.owner or 0)
            if itemID > 0 and price > 0 then
                local info = GetItemInfo(itemID)
                local name = info and info.name or "Unknown"
                table.insert(vendList, {
                    x = tile.x,
                    y = tile.y,
                    itemID = itemID,
                    name = name,
                    price = price
                })
            end
        end
    end

    if filterTermurah then
        table.sort(vendList, function(a,b) return a.price < b.price end)
    end
end


local function sign(n)
    if n > 0 then return 1 elseif n < 0 then return -1 else return 0 end
end

local function stepSize(dist)
    if dist > 10 then return 3
    elseif dist > 5 then return math.random(1,2)
    else return 1
    end
end


local function malastpgw(x, y)
    local px = math.floor(GetLocal().pos.x / 32)
    local py = math.floor(GetLocal().pos.y / 32)
    local tol = 1
    local maxSpeed = 12

    while math.abs(x - px) > tol or math.abs(y - py) > tol do
        local dx = x - px
        local dy = y - py
        local dist = math.max(math.abs(dx), math.abs(dy))
        local step = stepSize(dist)

        if math.abs(dx) > tol then px = px + sign(dx) * math.min(step, math.abs(dx)) end
        if math.abs(dy) > tol then py = py + sign(dy) * math.min(step, math.abs(dy)) end

        local minDelay = math.floor(1100 / maxSpeed)
        local delayMove
        if dist > 10 then
            delayMove = minDelay + math.random(40,70)
        elseif dist > 5 then
            delayMove = minDelay + 50 + math.random(10,40)
        else
            delayMove = minDelay + 70 + math.random(15,40)
        end

        FindPath(px, py)
        Sleep(delayMove)
    end

    FindPath(x, y)
    SendPacket(2, "action|input\n|text|`3Sampai di target vending : `2"..x..","..y.." #deepous need paha")
end


AddHook('OnDraw', 'BothaxVendGUI', function()
    if ImGui.Begin("Vend Finder #deepous kurang mik susu") then
        ImGui.Text("Filter item:")
        ImGui.SameLine()
        local changed, newText = ImGui.InputText("##filter", searchQuery or "", 100)
        if changed then searchQuery = newText end

        ImGui.SameLine()
        if ImGui.Button("Mencari janda") then ScanVendings() end

        ImGui.SameLine()
        _, filterTermurah = ImGui.Checkbox("Tebak Fungsi", filterTermurah)

        ImGui.Separator()
        ImGui.TextColored(ImVec4(0.9,0.9,0.9,1), "Ini Listnya ya ajgggg")
        ImGui.Separator()

        if ImGui.BeginTable("VendingTable",5) then
            ImGui.TableSetupColumn("Posisi")
            ImGui.TableSetupColumn("ID")
            ImGui.TableSetupColumn("Nama")
            ImGui.TableSetupColumn("Harga")
            ImGui.TableSetupColumn("Teleport")
            ImGui.TableHeadersRow()

            local shown = 0
            for _, v in ipairs(vendList) do
                if shown >= itemsPerPage then break end

                local match = false
                if searchQuery == "" then
                    match = true
                else
                    local lowerName = string.lower(v.name or "")
                    local lowerQuery = string.lower(searchQuery)
                    match = string.find(lowerName, lowerQuery, 1, true)
                        or string.find(tostring(v.itemID), lowerQuery, 1, true)
                end

                if match then
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0)
                    ImGui.Text(string.format("%d,%d", v.x, v.y))

                    ImGui.TableSetColumnIndex(1)
                    ImGui.Text(tostring(v.itemID))

                    ImGui.TableSetColumnIndex(2)
                    ImGui.Text(v.name)

                    ImGui.TableSetColumnIndex(3)
                    ImGui.Text(tostring(v.price).." WL")

                    ImGui.TableSetColumnIndex(4)
                    if ImGui.Button("TP##"..v.x.."_"..v.y) then
                        SendPacket(2, "action|input\n|text|`3Mulai TP ke : `2"..v.x..","..v.y.. " #deepous suka paha")
                        RunThread(malastpgw, v.x, v.y)
                    end

                    shown = shown + 1
                end
            end
            ImGui.EndTable()
        end
        ImGui.End()
    end
end)
