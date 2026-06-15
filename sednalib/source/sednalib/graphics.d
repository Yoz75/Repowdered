module sednalib.graphics;
import sednalib.color;
import sednalib.window;
import std.traits : isNumeric;
import raylib;

/// Sednalib members required for an image
public mixin template SednaImage()
{
    /// The color of the image.
    Color32 color;

    /// The scale of the image.
    float[2] scale = [1, 1];

    /// The pivot of the image (center)
    float[2] origin = [0.5, 0.5];

    /// The image's rotation
    float rotation = 0;
            
    /// The position of the image.
    float[2] position = [0, 0];    

    private Image image;
    private Texture texture;

    this(int[2] resolution, Color32 color)
    {
        this.color = color;
        image = GenImageColor(resolution[0], resolution[1], Colors.WHITE);
        texture = LoadTextureFromImage(image);
    }

    @property int width() inout => texture.width;
    @property int height() inout => texture.height;

    void setPixel(int[2] position, Color32 color)
    {
        ImageDrawPixel(cast(Image*) &image, position[0], position[1], cast(raylib.Color) color);   
    }  
    
    /// Update texture's data after image manipulaton
    void applyChanges() inout
    {
        UpdateTexture(texture, image.data);
    }

    void free() inout
    {
        UnloadTexture(texture);
    }
}

/// A structure that represents an image placed in world and stored both on GPU and CPU, witch you can rotate, change pivot, position, color and scale.
public struct Sprite
{
    mixin SednaImage;
public:

    /// Draw the sprite
    void draw()
    {
        BeginMode2D(globalWindowInstance.activeCamera);

        immutable source = Rectangle(0, 0, texture.width, texture.height);
        immutable auto destination = Rectangle(position[0], position[1], 
        texture.width * scale[0], 
        texture.height * scale[1]);

        immutable auto origin = Vector2(origin[0], origin[1]);
        DrawTexturePro(texture, source, destination, origin, rotation, cast(raylib.Color) color);

        EndMode2D();   
    }
}

/// A structure that represents an image placed on the screen and stored both on GPU and CPU, witch you can rotate, change pivot, position, color and scale.
/// The position field is considered as a relative position in bounds 0..1 for each coordinate
public struct ScreenImage
{
    mixin SednaImage;

public:
    /// Draw the image at relative screen position
    void drawAtRelativeScreenPosition()
    {
        auto absolutePosition = relativeScreenPos2ScreenPos(position, globalWindowInstance.getResolution());
        drawAtScreenPosition(absolutePosition);
    }

    /// Draw the image at absolute position
    /// Params:
    ///   position = the absolute screen position of sprite's origin
    void drawAtScreenPosition(int[2] position)
    {
        immutable source = Rectangle(0, 0, texture.width, texture.height);
        immutable auto destination = Rectangle(position[0], position[1], 
        texture.width * scale[0], 
        texture.height * scale[1]);

        immutable auto origin = Vector2(origin[0], origin[1]);
        DrawTexturePro(texture, source, destination, origin, rotation, cast(raylib.Color) color);
    }
}

public int[2] relativeScreenPos2ScreenPos(float[2] relativePosition, int[2] resolution) pure nothrow @nogc @safe
{
    pure remap(float value, float fromMin, float fromMax, float toMin, float toMax)
    {
        float t = (value - fromMin) / (fromMax - fromMin);
        return toMin + t * (toMax - toMin);
    }

    int[2] absolutePosition;

    absolutePosition[0] = cast(int) remap(relativePosition[0], 0, 1, 0, resolution[0]);
    absolutePosition[1] = cast(int) remap(relativePosition[1], 0, 1, 0, resolution[1]);

    return absolutePosition;
}

/// The type of a uniform variable
public enum UniformType
{
    float_ = 0,
    vector2,
    vector3,
    vector4,

    int_,
    vector2i,
    vector3i,
    vector4i,

    uint_,
    vector2ui,
    vector3ui,
    vector4ui,

    sampler2d
}

/// Hint that tells driver how we will use our buffer
public enum BufferUsageHint
{
    /// Fast data flow, From cpu to gpu
    StreamCPU2GPU =0x88E0,
    /// Fast data flow, From gpu to cpu
    StreamGPU2CPU,
    /// Fast data flow, From gpu to gpu
    StreamGPU2GPU,

    /// Data's being written once and being read many times, From cpu to gpu
    StaticCPU2GPU,
    /// Data's being written once and being read many times, From gpu to cpu
    StaticGPU2CPU,
    /// Data's being written once and being read many times, From gpu to gpu
    StaticGPU2GPU,

    /// Medium data flow, From cpu to gpu
    DynamicCPU2GPU,
    /// Medium data flow, From gpu to cpu
    DynamicGPU2CPU,
    /// Medium data flow, From gpu to gpu
    DynamicGPU2GPU,
}


/// A program executed on GPU
public interface IShader
{
    /// Free the shader's resources
    void free();

    /// Attach a GPU buffer to a shader. You can attach a single buffer to multiple shaders
    /// Params:
    /// shader = the shader
    /// buffer = the attach buffer
    /// bindingIndex = the binding index of buffer in shader's code
    void attachBuffer(ShaderBuffer buffer, uint bindingIndex);

    /// Detach a buffer from a shader
    /// Params:
    /// shader = the shader;
    /// index = the index of buffer in shader's code
    void detachBuffer(uint bindingIndex);

    /// Create CPU handle for a uniform variable of this shader
    /// Params:
    /// name = the name of variable in shader
    /// type = the type of variable in shader
    /// Returns: `Uniform` instance
    Uniform createUniform(string name, UniformType type);
}

/// A buffer allocated on GPU
public final class ShaderBuffer
{
    private uint glID;
    
    /// Initialize this buffer
    /// Params:
    /// size = size of buffer in bytes
    /// data = the initial data of buffer, if `data` == null, buffer won't be initialized
    /// hint = hint that tells driver how we'll use our buffer
    void initMe(uint size, void* data, BufferUsageHint hint)
    {
        glID = rlLoadShaderBuffer(size, data, hint);
        checkErrors();
    }

    /// Get internal id of the buffer
    uint getInternalID() => glID;

    /// Free GPU resources of the buffer
    void free()
    {
        rlUnloadShaderBuffer(glID);
        checkErrors();
    }
    
    /// Update SSBO buffer's value.
    /// Params:
    /// data = the new data
    /// offset = ofset of data
    void update (void[] data, uint offset = 0)
    {
        rlUpdateShaderBuffer(glID, data.ptr, cast(uint) data.length, offset);  
        checkErrors();
    }

    /// Read SSBO buffer's value
    /// Params:
    /// data = the array that'll be overwritten
    /// elementSize = size of one element in array
    /// offset = offset of data
    void read(void[] data, uint offset = 0)
    {
        rlReadShaderBuffer(glID, data.ptr, cast(uint) data.length, offset);
        checkErrors();
    }
}

/// A program executed on GPU
public final class BasicShader : IShader
{
    private Shader shader;

    // Key is buffer's binding index, value is glID
    private uint[uint] attachedBuffers;

    /// Init the shader: compile and link its vertex and fragment parts
    /// Params:
    /// vs = vertex shader
    /// fs = fragment shader
    void initMe(string vs, string fs)
    {
        shader = LoadShaderFromMemory(vs.ptr, fs.ptr);
    }

    /// Free the shader's resources
    void free()
    {
        // associative arrays support value iterations (like there) and key-value iterations
        foreach(bufferId; attachedBuffers)
        {
            rlUnloadShaderBuffer(bufferId);
            rlCheckErrors();
        }

        UnloadShader(shader);
    }

    /// Attach a GPU buffer to a shader. You can attach a single buffer to multiple shaders
    /// Params:
    /// shader = the shader
    /// buffer = the attach buffer
    /// index = the index of buffer in shader's code
    void attachBuffer(ShaderBuffer buffer, uint bindingIndex)
    {
        attachedBuffers[bindingIndex] = buffer.getInternalID();
    }

    /// Detach a buffer from a shader
    /// Params:
    /// shader = the shader;
    /// index = the index of buffer in shader's code
    void detachBuffer(uint bindingIndex)
    {
        attachedBuffers.remove(bindingIndex);
    }

    /// Begin current shader mode
    void beginMode()
    {
        BeginShaderMode(shader);
    }
    
    /// End current shader mdoe
    void endMode()
    {
        EndShaderMode();
    }

    /// Create CPU handle for a uniform variable of this shader
    /// Params:
    /// name = the name of variable in shader
    /// type = the type of variable in shader
    /// Returns: `Uniform` instance
    Uniform createUniform(string name, UniformType type)
    {
        auto uniform = new Uniform();

        uniform.glID = rlGetLocationUniform(shader.id, name.ptr);

        uniform.shaderGlID = shader.id;
        uniform.type = type;

        return uniform;
    }
}

/// A program executed on GPU
public final class ComputeShader : IShader
{
    private uint glID;

    // Key is buffer's binding index, value is glID
    private uint[uint] attachedBuffers;

    /// Init the shader: compile and link its code from sources
    /// Params:
    /// source = the source code of the shader
    void initMe(string source)
    {
        glID = rlLoadComputeShaderProgram(rlCompileShader(source.ptr, RL_COMPUTE_SHADER));
        checkErrors();
    }

    /// Free the shader's resources
    void free()
    {
        // associative arrays support value iterations (like there) and key-value iterations
        foreach(bufferId; attachedBuffers)
        {
            rlUnloadShaderBuffer(bufferId);
            rlCheckErrors();
        }

        rlUnloadShaderProgram(glID);
        checkErrors();
    }

    /// Attach a GPU buffer to a shader. You can attach a single buffer to multiple shaders
    /// Params:
    /// shader = the shader
    /// buffer = the attach buffer
    /// index = the index of buffer in shader's code
    void attachBuffer(ShaderBuffer buffer, uint bindingIndex)
    {
        attachedBuffers[bindingIndex] = buffer.getInternalID();
    }

    /// Detach a buffer from a shader
    /// Params:
    /// shader = the shader;
    /// index = the index of buffer in shader's code
    void detachBuffer(uint bindingIndex)
    {
        attachedBuffers.remove(bindingIndex);
    }

    /// Execute the shader
    void execute(uint[3] groupSizes)
    {
        rlEnableShader(glID);

        foreach(bufferIndex, bufferId; attachedBuffers)
        {
            rlBindShaderBuffer(bufferId, bufferIndex);
        }

        rlComputeShaderDispatch(groupSizes[0], groupSizes[1], groupSizes[2]);
        checkErrors();

        rlDisableShader();
    }

    /// Create CPU handle for a uniform variable of this shader
    /// Params:
    /// name = the name of variable in shader
    /// type = the type of variable in shader
    /// Returns: `Uniform` instance
    Uniform createUniform(string name, UniformType type)
    {
        Uniform uniform = new Uniform();

        uniform.glID = rlGetLocationUniform(glID, name.ptr);
        checkErrors();

        uniform.shaderGlID = glID;
        uniform.type = type;

        return uniform;
    }
}

public final class Uniform
{
    private uint glID;
    private uint shaderGlID;
    private UniformType type;

    /// Set the value of uniform
    /// Params:
    /// value = the pointer to value
    /// count = if uniform is an array, this parameter must be length of the array, otherwise 1
    void setValue(void* value, uint count = 1)
    {
        rlEnableShader(shaderGlID);
        rlSetUniform(glID, value, type, count);
        checkErrors();
        rlDisableShader();
    }
}

/// Converts pixel position on a sprite to the position of this pixel in world coordinates
/// Params:
///   sprite = the sprite
///   position = the pixel coordinate
/// Returns: the pixel position in world
public float[2] sprite2WorldPosition(in Sprite sprite, in int[2] position)
{
    import std.math;
    
    immutable float lx = position[0] * sprite.scale[0];
    immutable float ly = position[1] * sprite.scale[1];

    immutable rad = sprite.rotation * (PI / 180);
    immutable cosr = cos(rad);
    immutable sinr = sin(rad);

    immutable rx = lx * cosr - ly * sinr;
    immutable ry = lx * sinr + ly * cosr;

    return [rx + sprite.position[0], ry + sprite.position[1]];
}

public int[2] world2SpritePosition(in Sprite sprite, in float[2] position)
{
    import std.math;

    immutable cx = sprite.origin[0] * sprite.texture.width * sprite.scale[0];
    immutable cy = sprite.origin[1] * sprite.texture.height * sprite.scale[1];

    immutable float lx = position[0] - cx;
    immutable float ly = position[1] - cy;
    
    immutable rad = -sprite.rotation * (PI / 180);
    immutable cosr = cos(rad);
    immutable sinr = sin(rad);

    immutable rx = lx * cosr - ly * sinr;
    immutable ry = lx * sinr + ly * cosr;

    immutable tx = rx / sprite.scale[0] + sprite.origin[0] * sprite.texture.width;
    immutable ty = ry / sprite.scale[1] + sprite.origin[1] * sprite.texture.height;

    if (tx < 0 || ty < 0 || tx >= sprite.texture.width || ty >= sprite.texture.height)
        return [-1, -1];
    return [cast(int) tx, cast(int) ty];
}

/// Convert screen position to corresponding world position
/// Params:
///   screenPosition = the position of a pixel on the screen
/// Returns: position of this pixel in world coordinates
public float[2] screen2WorldPosition(float[2] screenPosition)
{
    immutable position =
     GetScreenToWorld2D(Vector2(screenPosition[0], screenPosition[1]), globalWindowInstance.activeCamera);

    return [position.x, position.y];
}

/// Convert world position to corresponding screen position
/// Params:
///   screenPosition = the world position
/// Returns: approximate pixel position at this world position on screen
public float[2] world2ScreenPosition(float[2] worldPosition)
{
    immutable position =
     GetWorldToScreen2D(Vector2(worldPosition[0], worldPosition[1]), globalWindowInstance.activeCamera);

    return [position.x, position.y];
}

pragma(inline, true)
private void checkErrors()
{
    rlCheckErrors();
}

unittest
{
    assert(Color(69, 128, 127, 51) == cast(Color) Color32(69, 128, 127, 51));
}