-- ============================================================
--  Madoka Menu  (GTA V PS4 1.57 / CUSA00411)  -  Luma script
--  Copy to  /data/gtalua/scripts/madoka_menu.lua
--  Open the menu : hold D-pad RIGHT and press SQUARE
--  Navigate      : D-pad up/down, left/right to change values,
--                  X = select, SQUARE = type a value, CIRCLE = back
-- ============================================================

local PAD = 0
local C_DOWN, C_UP, C_LEFT, C_RIGHT = 187, 188, 189, 190
local C_ACCEPT, C_CANCEL, C_SQUARE = 201, 202, 203

-- ---------- helpers ------------------------------------------------
local function me()  return PLAYER_PED_ID() end
local function pid() return PLAYER_ID() end
local function my_vehicle()
    local ped = me()
    if IS_PED_IN_ANY_VEHICLE(ped, false) then return GET_VEHICLE_PED_IS_IN(ped, false) end
    return 0
end
local function hash(s) return GET_HASH_KEY(s) end

-- toast message drawn by the menu itself (3 s)
local toast_text, toast_frames = nil, 0
local function toast(msg) toast_text, toast_frames = msg, 180 end

-- ---------- state --------------------------------------------------
local S = {
    godmode=false, invisible=false, never_wanted=false, police_ignore=false,
    super_jump=false, fast_run=false, no_ragdoll=false, quiet=false,
    explosive_ammo=false, explosive_melee=false, infinite_ammo=false,
    wanted=0, dmg=1.0,
    veh_god=false, veh_repair=false, veh_boost=false, power=1,
    r=255, g=0, b=255,
    hour=12, freeze_time=false, weather=1, night=false, thermal=false,
    freeze_weather=false, tp_gun=false, rainbow_car=false, rainbow_neon=false, drift=false,
    outfit_slot=1, scenario=1, plate_idx=0,
}
local was_fast_run, was_quiet, was_invisible = false, false, false

-- ---------- data ---------------------------------------------------
local WEAPONS = {
    {"Pistol","WEAPON_PISTOL"},{"Combat Pistol","WEAPON_COMBATPISTOL"},{"Heavy Pistol","WEAPON_HEAVYPISTOL"},
    {"Micro SMG","WEAPON_MICROSMG"},{"Assault SMG","WEAPON_ASSAULTSMG"},{"Assault Rifle","WEAPON_ASSAULTRIFLE"},
    {"Carbine Rifle","WEAPON_CARBINERIFLE"},{"Advanced Rifle","WEAPON_ADVANCEDRIFLE"},{"Pump Shotgun","WEAPON_PUMPSHOTGUN"},
    {"Heavy Sniper","WEAPON_HEAVYSNIPER"},{"Marksman Rifle","WEAPON_MARKSMANRIFLE"},{"Minigun","WEAPON_MINIGUN"},
    {"RPG","WEAPON_RPG"},{"Grenade Launcher","WEAPON_GRENADELAUNCHER"},{"Grenade","WEAPON_GRENADE"},
    {"Sticky Bomb","WEAPON_STICKYBOMB"},{"Knife","WEAPON_KNIFE"},{"Baseball Bat","WEAPON_BAT"},
    {"Parachute","GADGET_PARACHUTE"},
}
local VEHICLES = {
    {"Adder","adder"},{"Turismo R","turismor"},{"Zentorno","zentorno"},{"T20","t20"},{"Osiris","osiris"},
    {"Comet","comet2"},{"Sultan","sultan"},{"Dominator","dominator"},{"Bati 801","bati"},{"Akuma","akuma"},
    {"Buzzard","buzzard2"},{"Lazer","lazer"},{"Hydra","hydra"},{"Cargobob","cargobob"},
    {"Rhino","rhino"},{"Insurgent","insurgent"},
}
local WEATHERS = {"EXTRASUNNY","CLEAR","CLOUDS","OVERCAST","RAIN","THUNDER","FOGGY","SMOG","SNOW","BLIZZARD","XMAS"}
local PLATE_STYLES = {"Blue on White 1","Yellow on Black","Yellow on Blue","Blue on White 2","Blue on White 3","Yankton"}
local POWER = {"x1","x2","x4","x8","x16"}
local POWER_VAL = {1.0, 10.0, 20.0, 40.0, 80.0}   -- engine power multiplier steps
local PLACES = {
    {"Los Santos Airport",-1336.0,-3044.0,14.0},{"Maze Bank Tower",-75.0,-818.0,326.0},
    {"Mount Chiliad",450.0,5566.0,800.0},{"Fort Zancudo",-2047.0,3132.0,33.0},
    {"Vinewood Sign",711.0,1198.0,348.0},{"Grove Street",118.0,-1950.0,21.0},
    {"Sandy Shores",1851.0,3683.0,34.0},{"Paleto Bay",-276.0,6226.0,31.0},
    {"Vespucci Beach",-1600.0,-1100.0,13.0},{"Del Perro Pier",-1850.0,-1230.0,13.0},
}
local HEISTS = {   -- approximate entrances
    {"Fleeca Bank (Legion Sq)",149.0,-1040.0,29.4},{"Pacific Standard Bank",235.0,214.0,106.3},
    {"Humane Labs",3540.0,3675.0,28.1},{"Union Depository",11.0,-661.0,33.4},
    {"Diamond Casino",925.0,46.0,81.1},{"Docks",1214.0,-2970.0,5.9},
    {"Bolingbroke Penitentiary",1845.0,2585.0,45.7},
}

-- ---------- actions -----------------------------------------------
local function teleport(x, y, z)
    local ped = me()
    local e = ped
    if IS_PED_IN_ANY_VEHICLE(ped, false) then e = GET_VEHICLE_PED_IS_IN(ped, false) end
    REQUEST_COLLISION_AT_COORD(x, y, z)
    SET_ENTITY_COORDS(e, x, y, z, false, false, false, true)
end
local function heal()  SET_ENTITY_HEALTH(me(), GET_ENTITY_MAX_HEALTH(me())) end
local function armor() SET_PED_ARMOUR(me(), 100) end
local function give_weapon(name) GIVE_WEAPON_TO_PED(me(), hash(name), 9999, false, true) end
local function give_all()
    for _, w in ipairs(WEAPONS) do give_weapon(w[2]) end
    toast("All weapons given")
end
local function max_ammo()
    local p = mem_alloc(8)
    if not p then return end
    if GET_CURRENT_PED_WEAPON(me(), p, true) then
        SET_PED_AMMO(me(), read_mem(p, 4), 9999, false)
    end
    mem_free(p)
end
local function set_wanted()
    SET_PLAYER_WANTED_LEVEL(pid(), S.wanted, false)
    SET_PLAYER_WANTED_LEVEL_NOW(pid(), false)
end
local function repair_vehicle()
    local v = my_vehicle()
    if v ~= 0 then SET_VEHICLE_FIXED(v); SET_VEHICLE_DIRT_LEVEL(v, 0.0) end
end
local function apply_plate_style()
    local v = my_vehicle()
    if v == 0 then toast("Not in a vehicle"); return end
    SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(v, S.plate_idx)
end
local function set_plate(text)
    local v = my_vehicle()
    if v == 0 then toast("Not in a vehicle"); return end
    SET_VEHICLE_NUMBER_PLATE_TEXT(v, text)
end
local function flip_vehicle()
    local v = my_vehicle()
    if v ~= 0 then SET_VEHICLE_ON_GROUND_PROPERLY(v, false) end
end
local function max_upgrade()
    local v = my_vehicle()
    if v == 0 then toast("Not in a vehicle"); return end
    SET_VEHICLE_MOD_KIT(v, 0)
    for t = 0, 49 do
        if t >= 17 and t <= 22 then
            TOGGLE_VEHICLE_MOD(v, t, true)
        else
            local n = GET_NUM_VEHICLE_MODS(v, t)
            if n and n > 0 then SET_VEHICLE_MOD(v, t, n - 1, false) end
        end
    end
    toast("Vehicle upgraded")
end
local function apply_color()
    local v = my_vehicle()
    if v == 0 then return end
    SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(v, S.r, S.g, S.b)
    SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(v, S.r, S.g, S.b)
end
local function apply_neon()
    local v = my_vehicle()
    if v == 0 then return end
    for i = 0, 3 do SET_VEHICLE_NEON_ENABLED(v, i, true) end
    SET_VEHICLE_NEON_COLOUR(v, S.r, S.g, S.b)
end

local spawn_model = 0
local function request_spawn(model_name)
    local h = hash(model_name)
    if IS_MODEL_A_VEHICLE(h) then spawn_model = h else toast("Invalid vehicle model") end
end
local function spawn_tick()
    if spawn_model == 0 then return end
    if HAS_MODEL_LOADED(spawn_model) then
        local ped = me()
        local c = GET_ENTITY_COORDS(ped, false)
        local veh = CREATE_VEHICLE(spawn_model, c[1], c[2], c[3], GET_ENTITY_HEADING(ped), false, false, false)
        if veh ~= 0 and DOES_ENTITY_EXIST(veh) then
            local speed = 0.0
            if IS_PED_IN_ANY_VEHICLE(ped, false) then
                local cur = GET_VEHICLE_PED_IS_IN(ped, false)
                speed = GET_ENTITY_SPEED(cur)
                -- leave the old vehicle in place; DELETE_VEHICLE takes a pointer
            end
            SET_PED_INTO_VEHICLE(ped, veh, -1)
            SET_VEHICLE_FORWARD_SPEED(veh, speed)
            SET_MODEL_AS_NO_LONGER_NEEDED(spawn_model)
            spawn_model = 0
        end
    else
        REQUEST_MODEL(spawn_model)
    end
end

local function teleport_waypoint()
    if not IS_WAYPOINT_ACTIVE() then toast("No waypoint set"); return end
    local w = GET_BLIP_INFO_ID_COORD(GET_FIRST_BLIP_INFO_ID(8))
    local zp = mem_alloc(8)
    local z = 0.0
    if zp then
        local h = 1000.0
        while h > 0.0 do
            REQUEST_COLLISION_AT_COORD(w[1], w[2], h)
            if GET_GROUND_Z_FOR_3D_COORD(w[1], w[2], h, zp, false, false) then
                z = read_float(zp); break
            end
            h = h - 50.0
        end
        mem_free(zp)
    end
    teleport(w[1], w[2], z + 1.0)
end

local function heist_loadout()
    heal(); armor(); give_all()
    S.godmode, S.never_wanted, S.infinite_ammo = true, true, true
    toast("Heist loadout ready")
end

-- ---------- outfits (cosmetic, kept for this game session) ---------
local COMPONENTS = {0,1,2,3,4,5,6,7,8,9,10,11}
local PROPS = {0,1,2,6,7}
local OUTFITS = {}
local function capture_outfit(ped)
    local o = {comp={}, prop={}}
    for _, c in ipairs(COMPONENTS) do
        o.comp[c] = {GET_PED_DRAWABLE_VARIATION(ped, c), GET_PED_TEXTURE_VARIATION(ped, c), GET_PED_PALETTE_VARIATION(ped, c)}
    end
    for _, pr in ipairs(PROPS) do
        o.prop[pr] = {GET_PED_PROP_INDEX(ped, pr), GET_PED_PROP_TEXTURE_INDEX(ped, pr)}
    end
    return o
end
local function apply_outfit(o)
    local ped = me()
    for _, c in ipairs(COMPONENTS) do
        local v = o.comp[c]
        SET_PED_COMPONENT_VARIATION(ped, c, v[1], v[2], v[3])
    end
    for _, pr in ipairs(PROPS) do
        local v = o.prop[pr]
        if v[1] >= 0 then SET_PED_PROP_INDEX(ped, pr, v[1], v[2], true) else CLEAR_PED_PROP(ped, pr) end
    end
end
local function save_outfit()
    OUTFITS[S.outfit_slot] = capture_outfit(me()); toast("Outfit saved in slot " .. S.outfit_slot)
end
local function load_outfit()
    local o = OUTFITS[S.outfit_slot]
    if not o then toast("Slot " .. S.outfit_slot .. " is empty"); return end
    apply_outfit(o); toast("Outfit loaded")
end

-- ---------- scenarios ---------------------------------------------
local SCENARIOS = {
    {"Jog","WORLD_HUMAN_JOG_STANDING"},{"Push-ups","WORLD_HUMAN_PUSH_UPS"},{"Sit-ups","WORLD_HUMAN_SIT_UPS"},
    {"Yoga","WORLD_HUMAN_YOGA"},{"Flex","WORLD_HUMAN_MUSCLE_FLEX"},{"Cheer","WORLD_HUMAN_CHEERING"},
    {"Party","WORLD_HUMAN_PARTYING"},{"Smoke","WORLD_HUMAN_SMOKING"},{"Musician","WORLD_HUMAN_MUSICIAN"},
    {"Hang Out","WORLD_HUMAN_HANG_OUT_STREET"},{"Impatient","WORLD_HUMAN_STAND_IMPATIENT"},
}
local function scenario_names()
    local t = {}
    for i, sc in ipairs(SCENARIOS) do t[i] = sc[1] end
    return t
end
local function play_scenario() TASK_START_SCENARIO_IN_PLACE(me(), SCENARIOS[S.scenario][2], 0, true) end
local function stop_scenario() CLEAR_PED_TASKS_IMMEDIATELY(me()) end

-- ---------- helpers for rainbow ----------------------------------
local hue = 0.0
local function hsv(h)
    local i = math.floor(h * 6) % 6
    local f = h * 6 - math.floor(h * 6)
    local q, t = 1 - f, f
    local r, g, b
    if i == 0 then r,g,b = 1,t,0 elseif i == 1 then r,g,b = q,1,0 elseif i == 2 then r,g,b = 0,1,t
    elseif i == 3 then r,g,b = 0,q,1 elseif i == 4 then r,g,b = t,0,1 else r,g,b = 1,0,q end
    return math.floor(r*255), math.floor(g*255), math.floor(b*255)
end

-- ---------- per-frame effects -------------------------------------
local function self_loops()
    local p, ped = pid(), me()
    SET_PLAYER_INVINCIBLE(p, S.godmode)
    if S.never_wanted then CLEAR_PLAYER_WANTED_LEVEL(p) end
    if S.super_jump then SET_SUPER_JUMP_THIS_FRAME(p) end
    if S.explosive_ammo then SET_EXPLOSIVE_AMMO_THIS_FRAME(p) end
    if S.explosive_melee then SET_EXPLOSIVE_MELEE_THIS_FRAME(p) end
    if S.infinite_ammo then SET_PED_INFINITE_AMMO_CLIP(ped, true) end
    if S.no_ragdoll then SET_PED_CAN_RAGDOLL(ped, false) end
    SET_POLICE_IGNORE_PLAYER(p, S.police_ignore)
    -- only write these when the toggle changed, so we never fight other scripts
    if S.fast_run ~= was_fast_run then
        SET_RUN_SPRINT_MULTIPLIER_FOR_PLAYER(p, S.fast_run and 1.49 or 1.0); was_fast_run = S.fast_run
    end
    if S.quiet ~= was_quiet then
        SET_PLAYER_NOISE_MULTIPLIER(p, S.quiet and 0.0 or 1.0); was_quiet = S.quiet
    end
    if S.invisible ~= was_invisible then
        SET_ENTITY_VISIBLE(ped, not S.invisible, false); was_invisible = S.invisible
    end
end
local function vehicle_loops()
    local v = my_vehicle()
    if v == 0 then return end
    if S.veh_god then
        SET_ENTITY_INVINCIBLE(v, true); SET_VEHICLE_STRONG(v, true)
        SET_VEHICLE_TYRES_CAN_BURST(v, false); SET_VEHICLE_WHEELS_CAN_BREAK(v, false)
    end
    if S.veh_repair then SET_VEHICLE_FIXED(v) end
    if S.veh_boost and IS_PLAYER_PRESSING_HORN(pid()) then SET_VEHICLE_FORWARD_SPEED(v, 60.0) end
    if S.power > 1 then SET_VEHICLE_CHEAT_POWER_INCREASE(v, POWER_VAL[S.power]) end
    SET_VEHICLE_REDUCE_GRIP(v, S.drift)
    if S.rainbow_car or S.rainbow_neon then
        hue = (hue + 0.004) % 1.0
        local r, g, b = hsv(hue)
        if S.rainbow_car then
            SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(v, r, g, b); SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(v, r, g, b)
        end
        if S.rainbow_neon then
            for i = 0, 3 do SET_VEHICLE_NEON_ENABLED(v, i, true) end
            SET_VEHICLE_NEON_COLOUR(v, r, g, b)
        end
    end
end
local tp_buf
local function teleport_gun_tick()
    if not S.tp_gun then return end
    local ped = me()
    if not IS_PED_SHOOTING(ped) then return end
    tp_buf = tp_buf or mem_alloc(24)
    if tp_buf and GET_PED_LAST_WEAPON_IMPACT_COORD(ped, tp_buf) then
        local c = read_vector3(tp_buf)
        if c and (c[1] ~= 0.0 or c[2] ~= 0.0) then teleport(c[1], c[2], c[3] + 1.0) end
    end
end
local function world_loops()
    SET_NIGHTVISION(S.night)
    SET_SEETHROUGH(S.thermal)
    if S.freeze_time then SET_CLOCK_TIME(S.hour, 0, 0) end
    if S.freeze_weather then SET_OVERRIDE_WEATHER(WEATHERS[S.weather]) end
end

-- ============================================================
--  Menu engine
-- ============================================================
local UI = {
    open=false, stack={}, sounds=true,
    banner={255,105,180,255}, body={16,16,16,200}, scroll={255,255,255,255},
    max_rows=12,
}
local keyboard_active, keyboard_cb = false, nil
local hold = {left=0, right=0}

local function snd(name)
    if UI.sounds then PLAY_SOUND_FRONTEND(-1, name, "HUD_FRONTEND_DEFAULT_SOUNDSET", true) end
end

-- items: {t="toggle",label,key} {t="action",label,fn} {t="scroll",label,key,min,max,step,fn}
--        {t="list",label,key,choices,fn} {t="sub",label,menu} {t="text",label,fn,maxlen}
--        {t="spacer",label} {t="info",label,get}
local MENUS = {}
local function T(label,key,tip) return {t="toggle",label=label,key=key,tip=tip} end
local function A(label,fn,tip)  return {t="action",label=label,fn=fn,tip=tip} end
local function SUB(label,menu)  return {t="sub",label=label,menu=menu} end
local function SCR(label,key,min,max,step,fn) return {t="scroll",label=label,key=key,min=min,max=max,step=step or 1,fn=fn} end
local function LST(label,key,choices,fn) return {t="list",label=label,key=key,choices=choices,fn=fn} end
local function SP(label) return {t="spacer",label=label} end
local function TXT(label,fn,maxlen) return {t="text",label=label,fn=fn,maxlen=maxlen or 20} end
local function INFO(label,get) return {t="info",label=label,get=get} end

MENUS.main = {title="Madoka Menu", items={
    SUB("Self Options","self"), SUB("Weapons","weapons"), SUB("Vehicle","vehicle"),
    SUB("World","world"), SUB("Teleport","teleport"), SUB("Heist Tools","heist"),
    SUB("Player List","players"), SUB("Settings","settings"),
}}
MENUS.self = {title="Self Options", items={
    T("Godmode","godmode"), T("Invisible","invisible"), T("Never Wanted","never_wanted"),
    T("Police Ignore Me","police_ignore"), T("Super Jump","super_jump"), T("Fast Run","fast_run"),
    T("No Ragdoll","no_ragdoll"), T("Quiet Steps","quiet"),
    T("Explosive Ammo","explosive_ammo"), T("Explosive Melee","explosive_melee"),
    T("Infinite Ammo","infinite_ammo"),
    T("Teleport Gun","tp_gun"),
    SUB("Outfit Manager","outfits"), SUB("Scenarios","scenarios"),
    SCR("Wanted Level","wanted",0,5,1,set_wanted),
    A("Heal",heal), A("Give Armor",armor),
    A("Clear Wanted Level",function() CLEAR_PLAYER_WANTED_LEVEL(pid()) end),
    A("Extinguish Fire",function() STOP_ENTITY_FIRE(me()) end),
}}
MENUS.weapons = {title="Weapons", build=function()
    local it = {
        A("Give All Weapons",give_all),
        A("Remove All Weapons",function() REMOVE_ALL_PED_WEAPONS(me(), true) end),
        A("Max Ammo (Current)",max_ammo),
        T("Infinite Ammo","infinite_ammo"), T("Explosive Ammo","explosive_ammo"),
        SCR("Damage Multiplier","dmg",1,10,1,function() SET_PLAYER_WEAPON_DAMAGE_MODIFIER(pid(), S.dmg + 0.0) end),
        SP("Individual Weapons"),
    }
    for _, w in ipairs(WEAPONS) do it[#it+1] = A(w[1], function() give_weapon(w[2]) end) end
    return it
end}
MENUS.spawner = {title="Vehicle Spawner", build=function()
    local it = { TXT("Custom Model", request_spawn, 20) }
    for _, v in ipairs(VEHICLES) do it[#it+1] = A(v[1], function() request_spawn(v[2]) end) end
    return it
end}
MENUS.vehicle = {title="Vehicle Options", items={
    SUB("Vehicle Spawner","spawner"),
    T("Vehicle Godmode","veh_god"), T("Auto Repair","veh_repair"), T("Horn Boost","veh_boost"),
    LST("Engine Power","power",POWER),
    A("Repair",repair_vehicle), A("Flip Upright",flip_vehicle), A("Max Upgrade",max_upgrade),
    SUB("Plates","plates"),
    T("Rainbow Car","rainbow_car"), T("Rainbow Neons","rainbow_neon"), T("Drift Mode","drift"),
    SP("Custom Color"),
    SCR("Red","r",0,255,5), SCR("Green","g",0,255,5), SCR("Blue","b",0,255,5),
    A("Apply Color",apply_color), A("Apply Neon",apply_neon),
}}
MENUS.plates = {title="License Plate", items={
    TXT("Custom Text",function(s) set_plate(string.upper(s)) end, 8),
    SCR("Style Number","plate_idx",0,30,1,apply_plate_style),
    INFO("Known name",function() return PLATE_STYLES[S.plate_idx + 1] or "(see on car)" end),
    SP("Quick Plates"),
    A("MADOKA",function() set_plate("MADOKA") end),
    A("MADOKA 1",function() set_plate("MADOKA 1") end),
    A("LOS SANTOS",function() set_plate("LOSSANTO") end),
    A("BOSS",function() set_plate("BOSS") end),
    A("Random",function()
        local chars, out = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", ""
        for _ = 1, 8 do local i = math.random(1, #chars); out = out .. chars:sub(i, i) end
        set_plate(out)
    end),
}}
MENUS.world = {title="World Options", items={
    SCR("Hour","hour",0,23,1,function() SET_CLOCK_TIME(S.hour,0,0) end),
    T("Freeze Time","freeze_time"),
    LST("Weather","weather",WEATHERS,function() SET_WEATHER_TYPE_NOW_PERSIST(WEATHERS[S.weather]) end),
    T("Freeze Weather","freeze_weather"),
    A("Clear Weather Override",function() CLEAR_OVERRIDE_WEATHER(); CLEAR_WEATHER_TYPE_PERSIST(); S.freeze_weather = false end),
    T("Night Vision","night"), T("Thermal Vision","thermal"),
}}
MENUS.outfits = {title="Outfit Manager", items={
    SCR("Slot","outfit_slot",1,5,1),
    A("Save Current Outfit",save_outfit), A("Load Outfit",load_outfit),
    A("Remove Hat / Glasses",function() CLEAR_PED_PROP(me(),0); CLEAR_PED_PROP(me(),1) end),
}}
MENUS.scenarios = {title="Scenarios", items={
    LST("Scenario","scenario",scenario_names()),
    A("Play",play_scenario), A("Stop",stop_scenario),
}}
MENUS.teleport = {title="Teleport", build=function()
    local it = { A("To Waypoint",teleport_waypoint), SP("Locations") }
    for _, p in ipairs(PLACES) do it[#it+1] = A(p[1], function() teleport(p[2],p[3],p[4]) end) end
    return it
end}
MENUS.heist = {title="Heist Tools", build=function()
    local it = {
        A("Heist Loadout",heist_loadout,"Full HP/armor, weapons, godmode, no wanted"),
        T("Never Wanted","never_wanted"), T("Godmode","godmode"),
        A("Spawn Getaway (Adder)",function() request_spawn("adder") end),
        SP("Heist Locations"),
    }
    for _, p in ipairs(HEISTS) do it[#it+1] = A(p[1], function() teleport(p[2],p[3],p[4]) end) end
    return it
end}

-- player list (information + friendly actions only)
local selected_player = 0
local function sel_ped() return GET_PLAYER_PED(selected_player) end
MENUS.player_actions = {title="Player", build=function()
    local it = {}
    if not NETWORK_IS_PLAYER_ACTIVE(selected_player) then
        return { INFO("Player left the session", function() return "" end) }
    end
    it[#it+1] = INFO("Health", function() return tostring(GET_ENTITY_HEALTH(sel_ped())) end)
    it[#it+1] = INFO("Wanted Level", function() return tostring(GET_PLAYER_WANTED_LEVEL(selected_player)) end)
    it[#it+1] = INFO("Distance", function()
        local a, b = GET_ENTITY_COORDS(me(), false), GET_ENTITY_COORDS(sel_ped(), false)
        return string.format("%.0f m", GET_DISTANCE_BETWEEN_COORDS(a[1],a[2],a[3],b[1],b[2],b[3],true))
    end)
    it[#it+1] = INFO("In Vehicle", function() return IS_PED_IN_ANY_VEHICLE(sel_ped(), false) and "Yes" or "No" end)
    it[#it+1] = A("Teleport To Player", function()
        local c = GET_ENTITY_COORDS(sel_ped(), false); teleport(c[1], c[2], c[3] + 1.0) end)
    it[#it+1] = A("Copy Outfit", function() apply_outfit(capture_outfit(sel_ped())); toast("Outfit copied") end)
    it[#it+1] = A("Set Waypoint To Player", function()
        local c = GET_ENTITY_COORDS(sel_ped(), false); SET_NEW_WAYPOINT(c[1], c[2]) end)
    return it
end}
MENUS.players = {title="Player List", build=function()
    local it = { INFO("Players", function() return tostring(NETWORK_GET_NUM_CONNECTED_PLAYERS()) end) }
    for i = 0, 31 do
        if NETWORK_IS_PLAYER_ACTIVE(i) then
            local nm = GET_PLAYER_NAME(i) or ("Player " .. i)
            if i == pid() then nm = nm .. "  (you)" end
            it[#it+1] = {t="sub", label=nm, menu="player_actions", on=function() selected_player = i end}
        end
    end
    return it
end}
MENUS.settings = {title="Menu Settings", items={
    T("Sounds","__sounds"),
    SCR("Max Rows","__rows",5,20,1),
    SCR("Banner Red","__br",0,255,5), SCR("Banner Green","__bg",0,255,5), SCR("Banner Blue","__bb",0,255,5),
}}

-- settings keys live in UI, not S
local SETTING_GET = {
    __sounds=function() return UI.sounds end, __rows=function() return UI.max_rows end,
    __br=function() return UI.banner[1] end, __bg=function() return UI.banner[2] end, __bb=function() return UI.banner[3] end,
}
local SETTING_SET = {
    __sounds=function(v) UI.sounds = v end, __rows=function(v) UI.max_rows = v end,
    __br=function(v) UI.banner[1] = v end, __bg=function(v) UI.banner[2] = v end, __bb=function(v) UI.banner[3] = v end,
}
local function getv(k) if SETTING_GET[k] then return SETTING_GET[k]() end return S[k] end
local function setv(k, v) if SETTING_SET[k] then SETTING_SET[k](v) else S[k] = v end end

-- ---------- navigation --------------------------------------------
local function current()
    local top = UI.stack[#UI.stack]
    local def = MENUS[top.name]
    local items = def.items or def.build()
    return top, def, items
end
local function push(name, on)
    if on then on() end
    UI.stack[#UI.stack+1] = {name=name, cursor=1}
end
local function selectable(it) return it.t ~= "spacer" and it.t ~= "info" end
local function move(items, cur, dir)
    local n = #items
    if n == 0 then return 1 end
    for _ = 1, n do
        cur = cur + dir
        if cur < 1 then cur = n elseif cur > n then cur = 1 end
        if selectable(items[cur]) then return cur end
    end
    return cur
end

local function open_keyboard(cb, maxlen)
    DISPLAY_ONSCREEN_KEYBOARD(0, "FMMC_KEY_TIP8", "", "", "", "", "", maxlen)
    keyboard_active, keyboard_cb = true, cb
end
local function keyboard_tick()
    if not keyboard_active then return end
    local st = UPDATE_ONSCREEN_KEYBOARD()
    if st == 1 then
        local res = GET_ONSCREEN_KEYBOARD_RESULT()
        keyboard_active = false
        if keyboard_cb and res and res ~= "" then keyboard_cb(res) end
    elseif st == 2 or st == 3 then
        keyboard_active = false
    end
end

-- ---------- drawing ------------------------------------------------
local function text(str, x, y, scale, col, align)
    SET_TEXT_FONT(0)
    SET_TEXT_SCALE(scale, scale)
    SET_TEXT_COLOUR(col[1], col[2], col[3], col[4])
    SET_TEXT_WRAP(0.0, 1.0)
    if align == "center" then SET_TEXT_CENTRE(true)
    elseif align == "right" then SET_TEXT_RIGHT_JUSTIFY(true); SET_TEXT_WRAP(0.0, x) end
    BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(str)
    END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end
local function rect(x, y, w, h, c) DRAW_RECT(x, y, w, h, c[1], c[2], c[3], c[4], 0) end

local WHITE, BLACK = {255,255,255,255}, {0,0,0,255}
local X, W, ROW = 0.825, 0.23, 0.035

local function value_text(it, hovered)
    if it.t == "toggle" then return getv(it.key) and "~g~On" or "~r~Off"
    elseif it.t == "scroll" then
        local v = tostring(getv(it.key)); return hovered and ("< " .. v .. " >") or v
    elseif it.t == "list" then
        local v = it.choices[getv(it.key)] or "?"; return hovered and ("< " .. v .. " >") or v
    elseif it.t == "info" then return it.get()
    elseif it.t == "sub" then return ">" end
    return nil
end

local function draw_menu(def, items, cur)
    local n = #items
    local rows = math.min(n, UI.max_rows)
    local first = 1
    if cur > UI.max_rows then first = cur - UI.max_rows + 1 end

    rect(X, 0.1175, W, 0.083, UI.banner)
    text(def.title, X, 0.1, 0.75, WHITE, "center")
    rect(X, 0.159 + (rows * ROW) / 2, W, rows * ROW, UI.body)
    for i = 0, rows - 1 do
        local idx = first + i
        local it = items[idx]
        local y = (i + 1) * ROW + 0.125
        local hovered = (idx == cur)
        if hovered then rect(X, (i + 1) * ROW + 0.1415, W, ROW, UI.scroll) end
        local col = hovered and BLACK or WHITE
        if it.t == "spacer" then
            text("~italic~" .. it.label, X, y, 0.4, WHITE, "center")
        else
            text(it.label, 0.715, y, 0.4, col, "left")
            local vt = value_text(it, hovered)
            if vt then text(vt, 0.935, y, 0.4, col, "right") end
        end
    end
    local tip = items[cur] and items[cur].tip
    if tip then
        local y = (rows + 1) * ROW
        rect(X, y + 0.1415, W, ROW, UI.banner)
        text(tip, X, y + 0.125, 0.4, WHITE, "center")
    end
end

-- ---------- input + tick ------------------------------------------
local function pressed(c) return IS_DISABLED_CONTROL_JUST_PRESSED(PAD, c) end
local function held(c) return IS_DISABLED_CONTROL_PRESSED(PAD, c) end

local function change(it, dir)
    if it.t == "scroll" then
        local v = getv(it.key) + dir * it.step
        if v > it.max then v = it.min elseif v < it.min then v = it.max end
        setv(it.key, v); snd("NAV_UP_DOWN"); if it.fn then it.fn() end
    elseif it.t == "list" then
        local v = getv(it.key) + dir
        if v > #it.choices then v = 1 elseif v < 1 then v = #it.choices end
        setv(it.key, v); snd("NAV_UP_DOWN"); if it.fn then it.fn() end
    end
end

local function menu_tick()
    if not UI.open then
        if IS_CONTROL_PRESSED(PAD, C_RIGHT) and IS_CONTROL_JUST_PRESSED(PAD, C_SQUARE) then
            UI.open = true; UI.stack = {{name="main", cursor=1}}; snd("YES")
        end
        return
    end

    for _, c in ipairs({C_UP, C_DOWN, C_LEFT, C_RIGHT, C_ACCEPT, C_CANCEL, C_SQUARE}) do
        DISABLE_CONTROL_ACTION(PAD, c, true)
    end

    local top, def, items = current()
    if top.cursor > #items then top.cursor = math.max(1, #items) end
    if items[top.cursor] and not selectable(items[top.cursor]) then top.cursor = move(items, top.cursor, 1) end

    if not keyboard_active then
        if pressed(C_CANCEL) then
            if #UI.stack == 1 then UI.open = false else table.remove(UI.stack) end
            snd("BACK"); return
        elseif pressed(C_UP) then top.cursor = move(items, top.cursor, -1); snd("NAV_UP_DOWN")
        elseif pressed(C_DOWN) then top.cursor = move(items, top.cursor, 1); snd("NAV_UP_DOWN")
        end

        local it = items[top.cursor]
        if it then
            -- left / right with key repeat for scrolling items
            local dir = 0
            if pressed(C_RIGHT) then dir = 1; hold.right = 0
            elseif pressed(C_LEFT) then dir = -1; hold.left = 0
            elseif held(C_RIGHT) then hold.right = hold.right + 1; if hold.right > 12 and hold.right % 2 == 0 then dir = 1 end
            elseif held(C_LEFT) then hold.left = hold.left + 1; if hold.left > 12 and hold.left % 2 == 0 then dir = -1 end end
            if dir ~= 0 then change(it, dir) end

            if pressed(C_ACCEPT) then
                snd("SELECT")
                if it.t == "toggle" then setv(it.key, not getv(it.key))
                elseif it.t == "action" then local ok, err = pcall(it.fn); if not ok then toast("Error: " .. tostring(err)) end
                elseif it.t == "sub" then push(it.menu, it.on)
                elseif it.t == "text" then open_keyboard(it.fn, it.maxlen) end
            elseif pressed(C_SQUARE) then
                if it.t == "scroll" then
                    open_keyboard(function(s)
                        local v = tonumber(s)
                        if v and v >= it.min and v <= it.max then setv(it.key, math.floor(v)); if it.fn then it.fn() end
                        else toast("Value must be " .. it.min .. " - " .. it.max) end
                    end, 6)
                end
            end
        end
    end

    -- the stack may have changed above
    top, def, items = current()
    draw_menu(def, items, top.cursor)
end

local function toast_tick()
    if toast_text and toast_frames > 0 then
        toast_frames = toast_frames - 1
        rect(0.5, 0.92, 0.3, 0.04, {0, 0, 0, 170})
        text(toast_text, 0.5, 0.905, 0.4, WHITE, "center")
    end
end

on_tick(function()
    if not natives_ready() then return end
    local ok, err = pcall(function()
        self_loops(); vehicle_loops(); world_loops(); spawn_tick(); teleport_gun_tick()
        keyboard_tick(); menu_tick(); toast_tick()
    end)
    if not ok then log("madoka_menu: " .. tostring(err)) end
end)

log("Madoka Menu loaded (hold D-pad RIGHT + SQUARE)")
