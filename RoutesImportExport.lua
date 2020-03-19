local LibBase64 = LibStub("LibBase64-1.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Routes", false)

local route_zone_args_desc_table = {
	type = "description",
	name = function(info)
		local zone = tonumber(info[2])
		local count = 0

		for route_name, route_table in pairs(Routes.db.global.routes[zone]) do
			if #route_table.route > 0 then
				count = count + 1
			end
		end

		return L["You have |cffffd200%d|r route(s) in |cffffd200%s|r."]:format(count, C_Map.GetMapInfo(zone).name)
	end,
	order = 0,
}

local function importRoute(value)
    if strlen(value) > 0 then
        local result, data = AceSerializer:Deserialize(LibBase64.Decode(value))

        if result and data and data.RouteZone and data.RouteKey and data.RouteName and data.RouteData then
		    Routes.db.global.routes[data.RouteZone][data.RouteName] = nil
		    Routes.db.global.routes[data.RouteZone][data.RouteName] = data.RouteData

		    local opts = Routes.options.args.routes_group.args
            local zoneKey = tostring(data.RouteZone)

		    if not opts[zoneKey] then
                local mapName = C_Map.GetMapInfo(data.RouteZone).name

			    opts[zoneKey] = {
				    type = "group",
				    name = mapName,
				    desc = L["Routes in %s"]:format(mapName),
				    args = {
					    desc = route_zone_args_desc_table,
				    },
			    }

			    Routes.routekeys[data.RouteZone] = {}
		    end

		    Routes.routekeys[data.RouteZone][data.RouteKey] = data.RouteName
		    opts[zoneKey].args[data.RouteKey] = Routes:GetAceOptRouteTable()

		    local AutoShow = Routes:GetModule("AutoShow", true)

		    if AutoShow and Routes.db.defaults.use_auto_showhide then
			    AutoShow:ApplyVisibility()
		    end

		    Routes:DrawWorldmapLines()
		    Routes:DrawMinimapLines(true)
        end
    end
end

local exportGroup = {
	name = "Export",
    type = "input",
    width = "full",
    multiline = true,
	get = function(info)
        local zone = tonumber(info[2])
	    local routekey = info[3]
	    local name = Routes.routekeys[zone][routekey]
        local route = Routes.db.global.routes[zone][name]
        local data = { RouteZone = zone, RouteKey = routekey, RouteName = name, RouteData = route }

        return LibBase64.Encode(AceSerializer:Serialize(data))
    end,
	order = 999,
}

local importGroup = {
	name = "Import",
    type = "input",
    width = "full",
    multiline = true,
    set = function(info, value)
        importRoute(value)
    end,
	order = 999,
}

local function init(self, event, name)
    if (name ~= "RoutesImportExport") then return end

    Routes:GetAceOptRouteTable().args.info_group.args.export = exportGroup
    Routes.options.args.routes_group.args.import = importGroup
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", init)