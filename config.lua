local settings = core.settings
local function get_num(name, default)
	return tonumber(settings:get(name)) or default
end

local config = {
	climate_size = get_num("climate_zones_climate_size", 100),
	climate_spread = get_num("climate_zones_climate_spread", 256),
	blend_factor = get_num("climate_zones_climate_transition_size", 10),
	np_heat = {
		offset = 0,
		scale = 1,
		spread = {},
		seed = 3,
		octaves = 1,
	},
	np_humidity = {
		offset = 0,
		scale = 1,
		spread = {},
		seed = 5,
		octaves = 1,
	}
}

config.np_heat.spread.x = config.climate_spread
config.np_heat.spread.y = config.climate_spread
config.np_heat.spread.z = config.climate_spread
config.np_humidity.spread.x = config.climate_spread
config.np_humidity.spread.y = config.climate_spread
config.np_humidity.spread.z = config.climate_spread

return config
