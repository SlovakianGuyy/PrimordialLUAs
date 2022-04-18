--> CHANGE ME
local notification_library_name = "notifications" -- ../scripts/include/(notification name)
local chat_library_name = "chat" -- ../scripts/include/(chat print name)

--> Libraries
local nstat, notifications = pcall(function () return require(notification_library_name) end)
local cstat, chat = pcall(function () return require(chat_library_name) end)

--> ffi funcs.
local set_clipboard = function (text) ffi.cast("void(__thiscall*)(void*, const char*, int)", memory.get_vfunc(memory.create_interface("vgui2.dll", "VGUI_System010"), 9))(ffi.cast("void*",0), text, #text) end

--> UI
local ui = {

    logsEnable = menu.add_checkbox("Global", "Enable", true),
    logsType = menu.add_multi_selection("Global", "Log", {"hit", "shot", "spread", "resolver", "prediction error", "ping", "occlusion", "extrapolation", "other"}),
    logsTo = menu.add_multi_selection("Global", "To", {"Event", "Notification", "Chat (local)", "Chat (all)"}),
    logsNotifyMiss = menu.add_text("Global", "Library ".. notification_library_name .. " is missing."),
    logsChatMiss = menu.add_text("Global", "Library '" .. chat_library_name .. "' is missing."),
    logsChatAll = menu.add_text("Global", "Chat(all) works only for misses to prevent spam."),
    logsSeparator = menu.add_separator("Global"),
    logsCopy = menu.add_checkbox("Global", "Auto copy miss message"),
    logsNotifySpeed = menu.add_slider("Global", "Notification speed", 0, 10, 1, 0, "s"),
    logsChatColor = menu.add_selection("Global", "Chat color", {"Default", "white", "green", "red", "yellow", "blue", "purple", "lightred", "orange"})
}

ui.logsNotifyMiss:set_visible(false)
ui.logsChatMiss:set_visible(false)

--> Func. for checking lists
function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

--> Variables
local data = {

    hitgroupName = {"Generic", "Head", "Chest", "Stomach", "Left arm", "Right arm", "Left leg", "Right leg", "Neck", "Gear"},
    missReason = Set {"spread", "spread (missed safe)", "resolver", "prediction error", "ping (local death)", "ping (target death)", "occlusion", "extrapolation"},
    Loaded = false
}

--> Paint Callback
local function on_paint()

    if(ui.logsTo:get("Notification")) then ui.logsNotifySpeed:set_visible(true)
    else ui.logsNotifySpeed:set_visible(false)  end

    if(ui.logsTo:get("Chat (local)")) then ui.logsChatColor:set_visible(true)
    else ui.logsChatColor:set_visible(false) end

    if(ui.logsTo:get("Chat (all)")) then ui.logsChatAll:set_visible(true)
    else ui.logsChatAll:set_visible(false) end

    if(ui.logsNotifySpeed:get() == 0) then ui.logsNotifySpeed:set(4) end 
    if(ui.logsChatColor:get() == 1) then ui.logsChatColor:set(8) end

    if not data.Loaded then

        if not nstat and string.find(notifications, "module '".. notification_library_name .. "' not found: unknown module, make sure the file is in primordial/scripts/include") then

            ui.logsTo:set_items({ui.logsTo:get_item_name(1), "Notifications - missing library", ui.logsTo:get_item_name(3), ui.logsTo:get_item_name(4)})
            ui.logsNotifyMiss:set_visible(true)
        end
        
        if not cstat and string.find(chat, "module '".. chat_library_name .. "' not found: unknown module, make sure the file is in primordial/scripts/include") then
        
            ui.logsTo:set_items({ui.logsTo:get_item_name(1), ui.logsTo:get_item_name(2), "Chat (local) - missing library", ui.logsTo:get_item_name(4)})
            ui.logsChatMiss:set_visible(true)
        end

        data.Loaded = true
    end
end

--> Aimbot Hit Callback
local function on_aimbot_hit(hit)

    if not ui.logsEnable:get() then return end
    if(ui.logsType:get("Hit")) then

        local safechat, safe = hit.aim_safepoint
        local color = ui.logsChatColor:get_item_name(ui.logsChatColor:get())
        if(safechat) then safechat = " [{"..color.."}safe{white}]" safe = " [safe]" else safechat = "" safe = "" end

        local message = "Hit " .. hit.player:get_name() .. "'s " .. data.hitgroupName[hit.aim_hitgroup + 1] .. " [hc:".. hit.aim_hitchance .."] [dmg:" .. hit.aim_damage .. "] [bt:" .. hit.backtrack_ticks .. "]".. safe
        local chatmsg = "{"..color.."}>> {white} Hit {"..color.."}" .. hit.player:get_name() .. "{white}'s {"..color.."}" .. data.hitgroupName[hit.aim_hitgroup + 1] .. " {white} for {"..color.."}" .. hit.aim_damage .. "{white}dmg [hc:{"..color.."}".. hit.aim_hitchance .."{white}] [bt:{"..color.."}" .. hit.backtrack_ticks .. "{white}]".. safechat

        if(ui.logsTo:get("Event")) then client.log_screen(">> " .. message) end
        if(ui.logsTo:get("Notification")) then notifications:add_notification(">> Hit " .. hit.player:get_name() .. " in " .. data.hitgroupName[hit.aim_hitgroup + 1], message, ui.logsNotifySpeed:get()) end
        if(ui.logsTo:get("Chat (local)")) then chat.print(chatmsg) end
        if(ui.logsTo:get("Chat (all)")) then chat.print(chatmsg) end
    end
end

--> Aimbot Shot Callback
local function on_aimbot_shoot(shot)
    if not ui.logsEnable:get() then return end
    if(ui.logsType:get("Shot")) then

        local safechat, safe = shot.safepoint
        local color = ui.logsChatColor:get_item_name(ui.logsChatColor:get())
        if(safechat) then safechat = " [{"..color.."}safe{white}]" safe = " [safe]" else safechat = "" safe = "" end

        local message = "Shot at " .. shot.player:get_name() .. "'s " .. data.hitgroupName[shot.hitgroup + 1] .. " [hc:".. shot.hitchance .."] [dmg:" .. shot.damage .. "] [bt:" .. shot.backtrack_ticks .. "]".. safe
        local chatmsg = "{"..color.."}>> {white} Shot at {"..color.."}" .. shot.player:get_name() .. "{white}'s {"..color.."}" .. data.hitgroupName[shot.hitgroup + 1] .. "{white} [hc:{"..color.."}".. shot.hitchance .."{white}] [dmg:{"..color.."}" .. shot.damage .. "{white}] [bt:{"..color.."}" .. shot.backtrack_ticks .. "{white}]".. safechat

        if(ui.logsTo:get("Event")) then client.log_screen(">> " .. message) end
        if(ui.logsTo:get("Notification")) then notifications:add_notification(">> Shot at " .. shoot.player:get_name() .. " in " .. data.hitgroupName[shot.hitgroup + 1], message, ui.logsNotifySpeed:get()) end
        if(ui.logsTo:get("Chat (local)")) then chat.print(chatmsg) end
        if(ui.logsTo:get("Chat (all)")) then engine.execute_cmd("say " .. chatmsg) end
    end
end

--> Aimbot Miss Callback
local function on_aimbot_miss(miss)

    if not ui.logsEnable:get() then return end

    local reason = miss.reason_string
    local safechat, safe = miss.aim_safepoint
    local color = ui.logsChatColor:get_item_name(ui.logsChatColor:get())
    if(safechat) then safechat = " [{"..color.."}safe{white}]" safe = " [safe]" else safechat = "" safe = "" end

    if(reason == "ping (local death)") then reason = "death" end
    if(reason == "ping (target death)") then reason = "target death" end

    local message = "Aimbot missed " .. miss.player:get_name() .. "'s " .. data.hitgroupName[miss.aim_hitgroup + 1] .. " [hc:".. miss.aim_hitchance .."] [dmg:" .. miss.aim_damage .. "] [bt:" .. miss.backtrack_ticks .. "]".. safe .." due to [".. reason .. "]"
    local chatmsg = "{"..color.."}>> {white} Missed {"..color.."}" .. miss.player:get_name() .. "{white}'s {"..color.."}" .. data.hitgroupName[miss.aim_hitgroup + 1] .. " {white}[hc:{"..color.."}".. miss.aim_hitchance .."{white}] [dmg:{"..color.."}" .. miss.aim_damage .. "{white}] [bt:{"..color.."}" .. miss.backtrack_ticks .. "{white}]".. safechat .." due to [{"..color.."}".. reason .. "{white}]"
    
    if(ui.logsType:get(miss.reason_string) or ui.logsType:get("other") and not data.missReason[miss.reason_string] or
        ui.logsType:get("spread") and miss.reason_string == "spread (missed safe)" or
        ui.logsType:get("ping") and miss.reason_string == "ping (local death)" or
        ui.logsType:get("ping") and miss.reason_string == "ping (target death)") then 

        if(ui.logsCopy:get()) then 
            local msg = string.gsub(message, "Aimbot m", ">> M")
            set_clipboard(msg) 
        end

        if(ui.logsTo:get("Event")) then client.log_screen(">> " .. message) end
        if(ui.logsTo:get("Notification")) then notifications:add_notification(">> Missed shot due to " .. reason, message, ui.logsNotifySpeed:get()) end
        if(ui.logsTo:get("Chat (local)")) then chat.print(chatmsg) end
        if(ui.logsTo:get("Chat (all)")) then 
            local msg = string.gsub(message, "Aimbot m", ">> M")
            engine.execute_cmd("say " .. msg) 
        end
    end
end

--> Functions for callbacks
callbacks.add(e_callbacks.PAINT, on_paint)
callbacks.add(e_callbacks.AIMBOT_HIT, on_aimbot_hit)
callbacks.add(e_callbacks.AIMBOT_SHOOT, on_aimbot_shoot)
callbacks.add(e_callbacks.AIMBOT_MISS, on_aimbot_miss)
