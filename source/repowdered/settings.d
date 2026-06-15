/// The game settings. Every settings has a default value for cases when ./resources/compiletime/settings directory accidentally doesn't exists. 
/// If you want to change default value of a setting, change it in ./resources/compiletime/settings
module repowdered.settings;
import repowdered.catalogues;
import cereslib.jsonutils;
import sednalib : Color32;

/// Init the settings module and load settings from folder
public void initSettings()
{
    loadWindowSettings();
    loadMapSettings();
    loadCameraSettings();
    loadUISettings();
}

// Private now, but if I'll want to add mods support this probably should be public (and we should somehow export public symbols, but it's far far future)
private void loadSettings(string fileName, TSettings, alias field)()
{
    immutable path = combinePath(getSettingsPath, fileName);
    loadOrSave!TSettings(path, field);
}

private void loadWindowSettings()
{
    enum fileName = "window.json";
    loadSettings!(fileName, WindowSettigns, Settings.windowSettings)();
}

private void loadMapSettings()
{
    enum fileName = "map.json";
    loadSettings!(fileName, MapSettings, Settings.mapSettings)();
}

private void loadCameraSettings()
{
    enum fileName = "camera.json";
    loadSettings!(fileName, CameraSettings, Settings.cameraSettings)();
}

private void loadUISettings()
{
    enum fileName = "ui.json";
    loadSettings!(fileName, UISettings, Settings.uiSettings)();
}

/// The map settings
public struct MapSettings
{
    import repowdered.map : PositionScalar;

    mixin MakeJsonizable;
public:
@JsonizeField:
    /// The horizontal size of the map
    PositionScalar xResolution = 256;

    /// The vertical size of the map
    PositionScalar yResolution = 256;
}

/// The game window settings
public struct WindowSettigns
{
    mixin MakeJsonizable;
public:
@JsonizeField:
    /// The horizontal resolution
    int xResolution = 800;
    
    /// The vertical resolution
    int yResolution = 600;

    /// Is game should run fullscreen or not?
    bool isFullscreen = false;

    /// The title of the game window
    string title = "Repowdered";

    /// Maxinal FPS count
    int maxFPS = 240;

    Color32 backgroundColor = Color32(0x22, 0x22, 0x22);
}

/// Settings of the camera
public struct CameraSettings
{
    mixin MakeJsonizable;
public:
@JsonizeField:

    /// Sensitivity of WASD movement
    float movementSensitivity = 1;

    /// Sensitivity of zoom in/out actions
    float zoomSensitivity = 1;

    float minZoom = 0.001, maxZoom = 10;
}

/// Settings of the game UI. 
public struct UISettings
{
    mixin MakeJsonizable;

public:
@JsonizeField:
    /// Default frame background color (transparent, that's not a bug)
    Color32 frameBackground = Color32(0);

    /// Default button background
    Color32 background = Color32(0x17, 0x1A, 0x1F);

    /// Default button background when it's being selected
    Color32 selectedBackground = Color32(0x17 * 2, 0x1A * 2, 0x1F * 2);

    /// Default button background
    Color32 textColor = Color32(0xFF, 0xFF, 0xBB);

    Color32 outline = Color32(0xFF, 0xFF, 0xFF);
    int outlineSize = 4;
    int margin = 4;
}

/// The Repowdered settings. These are changeeable from in-game settings button
public final abstract class Settings
{
public:
__gshared:
    /// Settings of the map
    MapSettings mapSettings;

    /// Settings of the game window
    WindowSettigns windowSettings;

    /// Settings of the camera
    CameraSettings cameraSettings;

    /// Settings of the game UI
    UISettings uiSettings;
}