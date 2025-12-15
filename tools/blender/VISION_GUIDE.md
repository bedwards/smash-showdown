# MERTIN-FLEMMER: THE WILDEST DREAMS

## A Guide for Claude - What We're Building

---

## THE VISION

### 1. TOLKIEN-WORTHY TERRAIN
> "Tolein should be proud of this terrain"

The user wants terrain that feels like Middle-earth:
- **Misty Mountains** rising dramatically from valleys
- **Rolling hills** of the Shire - gentle, pastoral
- **Dark forests** with ancient trees
- **Alpine meadows** with wildflowers
- **Snow-capped peaks** glittering in sunlight
- **Deep valleys** where rivers carve through stone

### 2. ELDER SCROLLS ATMOSPHERE
> "Elder Scrolls baby!!!!"

Think Skyrim's epic vistas:
- Mountains you can actually climb
- Varied biomes that feel distinct
- Ancient ruins scattered across the landscape
- Weather and atmosphere
- Scale that makes you feel small

### 3. NATURAL UNDULATION
> "Ground to undulate in a natural way"

No flat terrain! Everything should:
- Roll and flow like real land
- Water collects in LOW places naturally
- Slopes lead UP to mountains gradually
- Valleys carved by ancient rivers
- No sharp transitions - smooth, organic

### 4. ALPINE PARADISE
> "valleys with wild flowers, snow caps on the mountains, alpine"

Swiss Alps meets fantasy:
- Flower-filled meadows in valleys
- Treeline transitions to rock to snow
- Crystal clear alpine lakes
- Mountain streams cascading down
- That crisp, clean feeling

### 5. DRAMATIC VERTICALITY
> "Mountains not balls!"

Real mountain topology:
- Jagged peaks, not smooth bumps
- Ridgelines connecting summits
- Cliff faces and rock outcroppings
- Caves carved into mountainsides
- Dramatic silhouettes against sky

---

## HOW TO ACHIEVE THIS IN BLENDER

### TECHNIQUE 1: Multi-Layer Noise

```python
# Layer different noise types for natural terrain:

# Base layer - continental shape (very large scale)
continental = fbm(x, y, octaves=3, scale=2000)

# Hill layer - rolling terrain (medium scale)
hills = fbm(x, y, octaves=4, scale=500)

# Detail layer - small variations (fine scale)
detail = fbm(x, y, octaves=6, scale=100)

# Mountain ridges - sharp peaks
ridges = ridged_multifractal(x, y, octaves=6, scale=300)

# Combine with weights
height = continental * 0.3 + hills * 0.2 + ridges * 0.4 + detail * 0.1
```

### TECHNIQUE 2: Domain Warping

Makes terrain look MORE organic by warping the input coordinates:

```python
def domain_warp(x, y, strength=0.3):
    # Warp x and y using noise
    warp_x = fbm(x + 100, y + 100, octaves=3) * strength
    warp_y = fbm(x + 200, y + 200, octaves=3) * strength
    return x + warp_x, y + warp_y

# Use warped coordinates for height
wx, wy = domain_warp(x, y)
height = fbm(wx, wy, ...)
```

### TECHNIQUE 3: Erosion Simulation

Carve realistic valleys and river paths:

```python
def hydraulic_erosion(heightmap, iterations=50):
    for _ in range(iterations):
        # Drop water particles
        # Let them flow downhill
        # Erode and deposit sediment
        # Creates natural river valleys
```

### TECHNIQUE 4: Biome Blending

Smooth transitions between terrain types:

```python
def blend_biomes(x, y, height):
    # Use Voronoi for biome regions
    biome = voronoi_biome(x, y)

    # Blend at boundaries
    blend_factor = smooth_step(distance_to_boundary)

    return lerp(biome_a_height, biome_b_height, blend_factor)
```

### TECHNIQUE 5: Snow Line & Treeline

Natural altitude-based transitions:

```python
SNOW_LINE = 250
TREELINE = 180

def get_material(height, slope):
    if height > SNOW_LINE:
        return SNOW
    if height > TREELINE:
        if slope > 0.6:
            return ROCK
        return ALPINE_GRASS
    if slope > 0.7:
        return ROCK
    return GRASS
```

### TECHNIQUE 6: Valley Flower Placement

Only place flowers in valleys (low, flat areas):

```python
def should_place_flower(x, y, height, slope):
    # Only in valleys
    if height > 50:
        return False
    # Only on gentle slopes
    if slope > 0.2:
        return False
    # Random distribution
    return noise(x * 10, y * 10) > 0.6
```

---

## THE EXECUTION PLAN

### Phase 1: Base Terrain Mesh
1. Generate 4096x4096 heightmap
2. Use multi-octave ridged noise for mountains
3. Apply domain warping for organic feel
4. Carve valleys with erosion simulation

### Phase 2: Mountain Peaks
1. Place 5 major mountain ranges
2. Each with multiple peaks connected by ridges
3. Varying heights (150-400 studs)
4. Sharp ridgelines using ridged noise

### Phase 3: Water Systems
1. Identify lowest points in terrain
2. Fill with water planes
3. Create river meshes following valleys
4. Add waterfalls at cliff edges

### Phase 4: Vegetation Scatter
1. Trees on slopes below treeline
2. Flowers in valley meadows
3. Rocks and boulders on steep terrain
4. Snow patches above snow line

### Phase 5: Detail Passes
1. Add cliff face geometry
2. Create cave entrances
3. Place ancient ruins
4. Add atmospheric elements

---

## OUTPUT TARGETS

- `epic_world.fbx` - Complete terrain mesh (high poly)
- `terrain_LOD1.fbx` - Medium detail for gameplay
- `terrain_LOD2.fbx` - Low detail for distance
- `mountains/*.fbx` - Individual mountain meshes
- `props/*.fbx` - Rocks, ruins, vegetation
- `renders/*.png` - Preview images for Claude to see

---

## SUCCESS CRITERIA

The terrain is ready when:
- [ ] You can see individual mountain peaks on the horizon
- [ ] Valleys naturally contain water
- [ ] Walking uphill leads to mountains
- [ ] Snow appears only on high peaks
- [ ] Flowers bloom in low meadows
- [ ] It feels like you could get lost exploring
- [ ] Tolkien would nod approvingly
- [ ] The user says "EPIC"

---

*Now let's build it.*
