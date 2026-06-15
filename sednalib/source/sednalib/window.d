module sednalib.window;
import std.exception : enforce;
import raylib;
import sednalib.color;
import fluid : Frame;

/// The window instance. Sedna allows only one window to be active!
package __gshared Window globalWindowInstance;

/// Set camera offset
public void setOffset(ref Camera2D camera, float[2] offset)
{
    camera.offset = Vector2(offset[0], offset[1]);
}

/// Set camera target
public void setTarget(ref Camera2D camera, float[2] target)
{
    camera.target = Vector2(target[0], target[1]);
}

/// Get camera offset
public float[2] getOffset(Camera2D camera)
{
    return [camera.offset.x, camera.offset.y];
}

/// Get camera target
public float[2] getTarget(Camera2D camera)
{
    return [camera.target.x, camera.target.y];
}

public final class Window
{
public:
    /// Active camera of the window. This is a Raylib's camera 2D.
    Camera2D activeCamera;

    /// A comfortable reference to the window UI. Should be created and updated manually.
    Frame uiRoot;

    private Color32 backgroundColor;

    private this()
    {

    }
    
    /// Create and display a new `Window`.
    /// Params:
    ///   resolution = the resolution of the winodw
    ///   isFullscreen = is window should be fullscreen? If true, `resolution` is ommited and actual resolution will be the monitor size.
    ///   title = the title of the window
    /// Returns: a new initialized `Window` that's ready to render stuff!
    static Window create(int[2] resolution, bool isFullscreen, string title)
    {
        Window window = new Window();
        window.activeCamera = Camera2D(Vector2(0, 0), Vector2(0, 0), 0, 1);

        enforce(globalWindowInstance is null, "Sednalib doesn't support multiple main windows,
         but a window already exists!");
        globalWindowInstance = window;
        if(isFullscreen)
        {
            SetConfigFlags(ConfigFlags.FLAG_BORDERLESS_WINDOWED_MODE);
            InitWindow(GetScreenWidth(), GetScreenHeight(), title.ptr);
        }
        else
        {
            InitWindow(resolution[0], resolution[1], title.ptr);
        }

        SetExitKey(raylib.KeyboardKey.KEY_NULL);
        return window;
    }

    /// Set the background color
    /// Params:
    ///   color = 
    void setBackgroundColor(Color32 color) pure
    {
        backgroundColor = color;
    }

    /// Should the window close?
    /// Returns: true if yes and false otherwise
    bool shouldClose()
    {
        return WindowShouldClose();
    }

    /// Get the window resolution
    /// Returns: [xResolution, yResolution]
    int[2] getResolution()
    {
        return [GetScreenWidth(), GetScreenHeight()];
    }

    /// Start the frame. This should be called every frame before any interactions with the window
    void startFrame()
    {
        BeginDrawing();
    }

    /// End the frame. This should be called every frame after all interactions with the window
    void endFrame()
    {
        EndDrawing();
    }

    /// Close the window
    void close()
    {
        CloseWindow();
        globalWindowInstance = null;
    }

    /// Clear the screen with some color
    void clearScreen()
    {
        ClearBackground(cast(Color) backgroundColor);
    }

    /// Set maximal FPS for the window.
    /// Params:
    ///   fps = the maximal frames per second count
    void setMaxFPS(int fps)
    {
        SetTargetFPS(fps);
    }

    /// Get mouse position according to world
    /// Returns: position of mouse in world coordinates
    float[2] getMouseWorldPosition()
    {
        immutable pos = GetScreenToWorld2D(GetMousePosition(), activeCamera);

        return[pos.x, pos.y];
    }

    /// Get pixel at witch mouse points
    /// Returns: pixel at witch mouse points as float[2] array
    float[2] getMousePosition()
    {
        immutable auto pos = GetMousePosition();
        return [pos.x, pos.y];
    }

    /// Get time of rendering previous frame
    float getFrameTime() => GetFrameTime();
}