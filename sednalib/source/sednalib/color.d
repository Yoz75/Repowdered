module sednalib.color;
import std.traits : isNumeric;
import jsonizer;

/// Stores color in RGBA format
public struct Color32
{
    mixin JsonizeMe;
    union
    {
        struct
        {
            @jsonize:
            ubyte r = 0, g = 0, b = 0, a = 255;
        }

        /// RRGGBBAA representation of the color
        uint value;
    }

    public this(ubyte r, ubyte g, ubyte b, ubyte a = 255)
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    public this(uint rgba)
    {
        value = rgba;
    }
}

/// Convert `Color32` to a [#]RRGGBBAA string. Runnable during both CTFE and runtime
public string toHexString(bool addSharp = false)(Color32 color)
{
    import std.format : format;
    
    static if(addSharp)
    {
        return "#" ~ format("%02X%02X%02X%02X", color.r, color.g, color.b, color.a);
    }
    else
    {
        return format("%02X%02X%02X%02X", color.r, color.g, color.b, color.a);
    }
}

public Color32 lerp(T)(inout Color32 from, inout Color32 to, inout T lerpFactor) pure if (isNumeric!T)
{
    Color32 result;

    result.r = cast(ubyte)(from.r + (to.r - from.r) * lerpFactor);
    result.g = cast(ubyte)(from.g + (to.g - from.g) * lerpFactor);
    result.b = cast(ubyte)(from.b + (to.b - from.b) * lerpFactor);
    result.a = cast(ubyte)(from.a + (to.a - from.a) * lerpFactor);

    return result;
}

unittest
{
    enum Color32 white =  Color32(255, 255, 255);
    enum string whiteStr = white.toHexString();
    enum string whiteStrSharp = white.toHexString!true();

    static assert(whiteStr == "FFFFFFFF");
    static assert(whiteStrSharp == "#FFFFFFFF");

    if(!__ctfe)
    {
        Color32 yellow = Color32(255, 0, 255);
        string yellowString = yellow.toHexString;
        string yellowStringSharp = yellow.toHexString!true();
        assert(yellowString == "FF00FFFF");
        assert(yellowStringSharp == "#FF00FFFF");
    }
}

unittest
{
    Color32 a = Color32(200, 100, 0);
    Color32 b = Color32(0, 0, 50);

    Color32 c = lerp(a, b, 0.5);
    assert(c == Color32(100, 50, 25, 255));
}