local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
local config = dofile(modpath .. "/config.lua")

local registered_on_heatmap_generated = {}
local registered_on_humiditymap_generated = {}
local registered_on_climatemap_generated = {}

------------------------------------------------------------
-- Callback API
------------------------------------------------------------
voronoi_climates_api = {}

function voronoi_climates_api.register_on_heatmap_generated(callback)
    table.insert(registered_on_heatmap_generated, callback)
end

function voronoi_climates_api.register_on_humiditymap_generated(callback)
    table.insert(registered_on_humiditymap_generated, callback)
end

function voronoi_climates_api.register_on_climatemap_generated(callback)
    table.insert(registered_on_climatemap_generated, callback)
end

local function on_heatmap_generated(map, minp, maxp, seed)
    for _, callback in ipairs(registered_on_heatmap_generated) do
        callback(map, minp, maxp, seed)
    end
end

local function on_humiditymap_generated(map, minp, maxp, seed)
    for _, callback in ipairs(registered_on_humiditymap_generated) do
        callback(map, minp, maxp, seed)
    end
end

local function on_climatemap_generated(heatmap, humidmap, minp, maxp, seed)
    for _, callback in ipairs(registered_on_climatemap_generated) do
        callback(heatmap, humidmap, minp, maxp, seed)
    end
end

------------------------------------------------------------
-- Voronoi generation
------------------------------------------------------------
local function get_climate_noise(x, y, nobj_noise, nobj_heat, nobj_humid)
	x = x / config.climate_size
	y = y / config.climate_size

	local id_x = math.floor(x)
	local id_y = math.floor(y)

	local fr_x = x - id_x
	local fr_y = y - id_y

	local min_x = math.huge
	local min_y = math.huge
	local min_dist = math.huge

	for o_y = -1, 1 do
	for o_x = -1, 1 do
		local cell_x = id_x + o_x
		local cell_y = id_y + o_y

		-- randomly shift the origin around in the cell, so the voronoi isnt just squares
		local d_x = nobj_noise:get2d({x=cell_x, y=cell_y}) / 2 + .5
		local d_y = nobj_noise:get2d({x=cell_x+32000, y=cell_y+32000}) / 2 + .5
		local p_x = d_x + o_x
		local p_y = d_y + o_y

		local dist_x = p_x - fr_x
		local dist_y = p_y - fr_y
		local dist_sq = dist_x * dist_x + dist_y * dist_y

		if dist_sq < min_dist then
			min_dist = dist_sq
			min_x = cell_x
			min_y = cell_y
		end
	end
	end

	local point = {x=min_x * config.climate_size, y=min_y * config.climate_size}
	local heat = nobj_heat:get_2d(point) * 50 + 50
	local humid = nobj_humid:get_2d(point) * 50 + 50
	return heat, humid
end

local nobj_heat = nil
local nobj_humidity = nil
local nobj_noise = nil
core.register_on_generated(function(minp, maxp, seed)
	if #registered_on_heatmap_generated == 0 and #registered_on_humiditymap_generated == 0 and #registered_on_climatemap_generated == 0 then
		return
	end

	local sidelen = maxp.x - minp.x + 1
	local dims = {x = sidelen, y = sidelen, z = sidelen}
	nobj_heat = nobj_heat or core.get_value_noise(config.np_heat, dims)
	nobj_humidity = nobj_humidity or core.get_value_noise(config.np_humidity, dims)
	nobj_noise = nobj_noise or core.get_value_noise({
		offset = 0,
		scale = 1,
		spread = {x=.000001, y=.000001, z=.000001},
		seed = 247926073,
		octaves = 1,
	}, dims)

	local heatmap = {}
	local humidmap = {}

	local ni = 1
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		local o_x = nobj_noise:get2d({x=x, y=z}) / 2 * config.blend_factor
		local o_z = nobj_noise:get2d({x=x+32000, y=z+32000}) / 2 * config.blend_factor
		heatmap[ni], humidmap[ni] = get_climate_noise(x+o_x, z+o_z, nobj_noise, nobj_heat, nobj_humidity)

		ni = ni + 1
	end
	end

	on_heatmap_generated(heatmap, minp, maxp, seed)
	on_humiditymap_generated(humidmap, minp, maxp, seed)
	on_climatemap_generated(heatmap, humidmap, minp, maxp, seed)
end)
