This README and large parts of the code were written by ChatGPT.

Thanks to sumianvoice on the Luanti Discord for explaining this stuff to me.

# Voronoi Climates API

A lightweight Luanti mod that generates **Voronoi-based climate maps** for use by other mods.

The mod produces heat and humidity values during map generation and exposes callbacks so other mods can use the generated climate data for biome generation, vegetation, terrain decoration, or other environmental systems.

## Features

* Generates a **heat map** for each map chunk.
* Generates a **humidity map** for each map chunk.
* Combines heat and humidity into a single climate-generation callback.
* Uses a Voronoi-style distribution to create large, irregular climate regions.
* Supports configurable climate cell size and blending.
* Runs during Luanti's `on_generated` map-generation callback.
* Provides a simple callback API for other mods.

## API

### `register_on_heatmap_generated(callback)`

Registers a callback that is called after a heat map has been generated.

```lua
register_on_heatmap_generated(function(map, minp, maxp, seed)
    -- Use the heat map here
end)
```

#### Parameters

| Parameter | Description                     |
| --------- | ------------------------------- |
| `map`     | Array containing heat values    |
| `minp`    | Minimum map-generation position |
| `maxp`    | Maximum map-generation position |
| `seed`    | Map-generation seed             |

The values in `map` correspond to the X/Z positions of the generated map area.

---

### `register_on_humiditymap_generated(callback)`

Registers a callback that is called after a humidity map has been generated.

```lua
register_on_humiditymap_generated(function(map, minp, maxp, seed)
    -- Use the humidity map here
end)
```

#### Parameters

| Parameter | Description                      |
| --------- | -------------------------------- |
| `map`     | Array containing humidity values |
| `minp`    | Minimum map-generation position  |
| `maxp`    | Maximum map-generation position  |
| `seed`    | Map-generation seed              |

---

### `register_on_climatemap_generated(callback)`

Registers a callback that receives both climate maps at once.

```lua
register_on_climatemap_generated(function(heatmap, humidmap, minp, maxp, seed)
    -- Use both maps here
end)
```

#### Parameters

| Parameter  | Description                      |
| ---------- | -------------------------------- |
| `heatmap`  | Array containing heat values     |
| `humidmap` | Array containing humidity values |
| `minp`     | Minimum map-generation position  |
| `maxp`     | Maximum map-generation position  |
| `seed`     | Map-generation seed              |

This is generally the most convenient callback when a system needs both temperature and humidity.

## Map Layout

The generated arrays contain one value for every X/Z coordinate in the generated map area.

Values are written in this order:

```text
for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
        ...
    end
end
```

The index for a position can therefore be calculated as:

```lua
local xlen = maxp.x - minp.x + 1
local index = (z - minp.z) * xlen + (x - minp.x) + 1
```

For example:

```lua
register_on_climatemap_generated(function(heatmap, humidmap, minp, maxp, seed)
    local xlen = maxp.x - minp.x + 1

    local x = 10
    local z = 20

    local index =
        (z - minp.z) * xlen +
        (x - minp.x) +
        1

    local heat = heatmap[index]
    local humidity = humidmap[index]
end)
```

## Climate Values

Heat and humidity are sampled from configured value noise at the center of the selected Voronoi climate cell.

The current implementation transforms the noise values approximately as follows:

```lua
heat = noise * 50 + 50
humidity = noise * 50 + 50
```

This means heat and humidity is intended to cover roughly a `0–100` range.

## Voronoi Climate Generation

Instead of assigning climate independently at every coordinate, the mod divides the world into large climate cells.

Each cell receives a pseudo-random point. The closest point determines which climate cell a coordinate belongs to.

This creates broad, irregular regions rather than a smooth per-node noise pattern.

## Example: Using Climate for Biomes

Another mod can register a climate callback and use the values to determine what should be generated:

```lua
register_on_climatemap_generated(function(heatmap, humidmap, minp, maxp, seed)
    local xlen = maxp.x - minp.x + 1

    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local index =
                (z - minp.z) * xlen +
                (x - minp.x) +
                1

            local heat = heatmap[index]
            local humidity = humidmap[index]

            if heat > 70 and humidity > 70 then
                -- Hot and humid
                -- Generate tropical vegetation, for example.
            elseif heat < 30 then
                -- Cold climate
            end
        end
    end
end)
```
