module repowdered.particles.rendering.updaters;

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