local ffi = require "ffi"

ffi.cdef [[

typedef uint16_t LuaGBAddress;

// graphics/palette
typedef uint8_t LuaGBPaletteColor[4];
typedef struct _LuaGBPalette {
    LuaGBPaletteColor dmg_colors[4];
    LuaGBPaletteColor bg[4], obj0[4], obj1[4];
    LuaGBPaletteColor color_bg[8][4];
    uint8_t color_bg_raw[64], color_obj_raw[64];
    uint8_t color_bg_index, color_obj_index;
    bool color_bg_auto_increment, color_obj_auto_increment;
    LuaGBPaletteColor color_obj[8][4];
    void (*set_dmg_colors)(LuaGBPaletteColor, LuaGBPaletteColor, LuaGBPaletteColor, LuaGBPaletteColor);
    void (*reset)();
} LuaGBPalette;

// graphics/cache
typedef struct _LuaGBTileAttribute {
    LuaGBPaletteColor *palette;
    uint8_t bank;
    bool horizontal_flip, vertical_flip, priority;
} LuaGBTileAttritbute,
  *LuaGBTileAttritbutePtr,
  (*LuaGBTileAttritbuteMapPtr)[32],
  LuaGBTileAttributeMap[32][32];

typedef uint8_t LuaGBTile,
                *LuaGBTileList,
                (*LuaGBTileList2)[8],
                (*LuaGBTileListMapPtr)[8][8],
                LuaGBTileListMap[768][8][8],
                (*LuaGBTileMapPtr)[32][8][8],
                LuaGBTileMap[32][32][8][8];

typedef struct _LuaGBOAMEntry {
    uint8_t x;
    uint8_t y;
    LuaGBTileList2 tile, upper_tile, lower_tile;
    bool bg_priority, horizontal_flip, vertical_flip;
    LuaGBPaletteColor palette[4];
} LuaGBOAMEntry, LuaGBOAM[40];
typedef struct _LuaGBTileCache {
    LuaGBTileListMap tiles;
    LuaGBTileListMap tiles_h_flipped;
    LuaGBTileMap map_0;
    LuaGBTileMap map_1;
    LuaGBTileAttributeMap map_0_attr;
    LuaGBTileAttributeMap map_1_attr;
    LuaGBOAM oam;
    void (*reset)();
    void (*refreshOamEntry)(uint8_t);
    void (*refreshAttributes)(LuaGBTileAttritbuteMapPtr, uint8_t, uint8_t, LuaGBAddress);
    void (*refreshTile)(LuaGBAddress, uint8_t);
    void (*refreshTiles)();
    void (*refreshTileIndex)(uint8_t, uint8_t, LuaGBAddress, LuaGBTileMap, LuaGBTileAttributeMap);
    void (*refreshTileMap)(LuaGBAddress, LuaGBTileMap, LuaGBTileAttributeMap);
    void (*refreshTileMaps)();
    void (*refreshTileAttributes)();
    void (*refreshAll)();
    void (*reset)();
} LuaGBTileCache;


// graphics/registers

typedef struct _LuaGBGraphicRegisterStatus {
    uint8_t mode;
    bool lyc_interrupt_enabled,
         oam_interrupt_enabled,
         vblank_interrupt_enabled,
         hblank_interrupt_enabled;
    void (*SetMode)(uint8_t);

} LuaGBGraphicRegisterStatus;

typedef struct _LuaGBGraphicRegisters {
    LuaGBGraphicRegisterStatus status;
    bool display_enabled;
    LuaGBTileMapPtr window_tilemap,
                 background_tilemap;
    LuaGBTileAttritbuteMapPtr window_attr,
                              background_attr;
    bool window_enabled, background_enabled;
    LuaGBAddress tile_select;
    bool large_sprites,
         sprites_enabled,
         background_enabled,
         oam_priority;
} LuaGBGraphicRegisters;


//graphics/init

typedef struct _LuaGBGraphicsScanlineData {
    uint8_t x,
            bg_tile_x,
            bg_tile_y,
            sub_x,
            sub_y;
    LuaGBTileMapPtr current_map;
    LuaGBTileAttritbuteMapPtr current_map_attr;
    bool window_active;
    LuaGBTileList2 active_tile;
    LuaGBTileAttritbutePtr active_attr;
    uint8_t bg_index[160];
    bool bg_priority[160];
} LuaGBGraphicsScanlineData;

typedef struct _LuaGBGraphics {
    LuaGBGraphicsScanlineData scanline_data;
    uint64_t vblank_count;
    uint32_t last_edge;
    uint32_t next_edge;
    bool lcdstat;
    uint8_t vram[0x8000];
    uint8_t vram_bank;
    uint8_t oam[0xA0];
    LuaGBPaletteColor game_screen[144 * 160];

    LuaGBGraphicRegisters registers;
    LuaGBPalette palette;
    LuaGBTileCache cache;
} LuaGBGraphics;
]]