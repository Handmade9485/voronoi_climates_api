local settings = core.settings
local function get_num(name, default)
	return tonumber(settings:get(name)) or default
end

local function cap_octaves(np)
	local min_spread = math.min(np.spread.x, np.spread.y, np.spread.z)
	local octaves = math.max(
		1,
		math.floor(math.log(min_spread / 4) / math.log(np.lacunarity or 2)) + 1
	)
	return math.min(np.octaves, octaves)
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
config.np_heat.octaves = cap_octaves(config.np_heat)
config.np_humidity.spread.x = config.climate_spread
config.np_humidity.spread.y = config.climate_spread
config.np_humidity.spread.z = config.climate_spread
config.np_humidity.octaves = cap_octaves(config.np_humidity)

return config
