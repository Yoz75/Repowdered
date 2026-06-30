module repowdered.particles.rendering.renderers;

import repowdered.sednapipeline;
import repowdered.particles.rendering.components;
import repowdered.map : Position;
import sednalib;
import plutoecs;
import dlib.container.array;

/// Something, that renders updated entities into the render buffer
public interface IRenderModeRenderer
{
    /// update the map sprite
    /// Params:
    /// buffer = the buffer to update. Assume its length is greater or equals `markers` length
    /// markers = a pool of `UpdateRenderableMarker`, all entities with this component should be updated on the sprite
    public void update(Color32[] buffer, World world, ComponentPool!UpdateRenderableMarker markers) pure;
}

public final class ColorRenderer : IRenderModeRenderer
{
    private int[2] resolution;

    public this(int[2] resolution)
    {
        this.resolution = resolution;
    }

    /// update the map sprite
    /// Params:
    /// buffer = the buffer to update. Assume its length is greater or equals `markers` length
    /// markers = a pool of `UpdateRenderableMarker`, all entities with this component should be updated on the sprite
    public void update(Color32[] buffer, World world, ComponentPool!UpdateRenderableMarker markers) pure
    {
        auto renderables = world.getPoolOf!MapRenderable;
        auto positions = world.getPoolOf!Position;
        
        auto data = markers.getComponents();

        foreach(i, marker; data)
        {
            Entity entity = markers.dense2Entity(i);

            immutable position = positions.getComponent(entity);
            immutable index = position.y * resolution[0] + position.x;

            buffer[index] = renderables.getComponent(entity).color;
        }
    }
}

public final class ThermalRenderer : IRenderModeRenderer
{
    import repowdered.particles.thermal;
    import cereslib.math;

    enum minColdTemperaure = -100;
    enum maxColdTemperature = 0;
    enum maxNormalTemperature = 100;
    enum maxWarmTemperature = 1000;
    enum maxHotTemperature = 2000;
    enum maxVeryHotTemperature = 4000;
    enum maxInsaneTemperature = 6000;
    enum maxUltraTemperature = 8000;
    enum maxNetherTemperature = 10_000;

    private int[2] resolution;

    public this(int[2] resolution)
    {
        this.resolution = resolution;
    }

    public void update(Color32[] buffer, World world, ComponentPool!UpdateRenderableMarker markers) pure
    {
        auto temperatures = world.getPoolOf!Temperature;
        auto positions = world.getPoolOf!Position;

        auto data = markers.getComponents();
        foreach(i, marker; data)
        {
            const Entity entity = markers.dense2Entity(i);

            immutable position = positions.getComponent(entity);
            immutable index = position.y * resolution[0] + position.x;

            buffer[index] = temperature2Color(temperatures.getComponent(entity).value);
        }
    }

    private static Color32 temperature2Color(TemperatureScalar value) pure
    {
        enum coldColor = Color32(0, 0, 255);
        enum zeroColor = Color32(0, 0, 0);
        enum normalColor = Color32(32, 32, 32);
        enum warmColor = Color32(0, 255, 0);
        enum hotColor = Color32(255, 0, 0);
        enum veryHotColor = Color32(255, 96, 0);
        enum insaneColor = Color32(255, 255, 0);
        enum ultraColor = Color32(255, 255, 255);
        enum netherColor = Color32(255, 0, 255);

        /*
            HUGE IF BLOCK ATTENTION!!!!!
        */

        if(value < minColdTemperaure)
        {
            return coldColor;
        } 
        if(value < maxColdTemperature)
        {
            immutable normalized = remap!TemperatureScalar(value, minColdTemperaure, maxColdTemperature, 0, 1);
            return lerp(coldColor, zeroColor, normalized);
        }
        if(value < maxNormalTemperature)
        {
            immutable normalized = remap!TemperatureScalar(value, maxColdTemperature, maxNormalTemperature, 0, 1);
            return lerp(zeroColor, normalColor, normalized);
        }
        if(value < maxWarmTemperature)
        {
            immutable normalized = remap!TemperatureScalar(value, maxNormalTemperature, maxWarmTemperature, 0, 1);
            return lerp(normalColor, warmColor, normalized);
        }
        if(value < maxHotTemperature)
        {
            immutable normalized = remap!TemperatureScalar(value, maxWarmTemperature, maxHotTemperature, 0, 1);
            return lerp(warmColor, hotColor, normalized);
        }
        if(value < maxVeryHotTemperature)
        {
            immutable normalized = remap!TemperatureScalar(value, maxHotTemperature, maxVeryHotTemperature, 0, 1);
            return lerp(hotColor, veryHotColor, normalized);
        }
        if(value < maxInsaneTemperature)
        {
            immutable normalized = remap!TemperatureScalar(value, maxVeryHotTemperature, maxInsaneTemperature, 0, 1);
            return lerp(veryHotColor, insaneColor, normalized);
        }
        if(value < maxUltraTemperature)
        {
            immutable normalized = remap!TemperatureScalar(value, maxInsaneTemperature, maxUltraTemperature, 0, 1);
            return lerp(insaneColor, ultraColor, normalized);
        }
        if(value < maxNetherTemperature)
        {
            immutable normalized = remap!TemperatureScalar(value, maxUltraTemperature, maxNetherTemperature, 0, 1);
            return lerp(ultraColor, netherColor, normalized);
        }
        else 
        {
            return netherColor;
        }
    }
}