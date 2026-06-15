module repowdered.particles.rendering;

import repowdered.sednapipeline;
import repowdered.settings;
import repowdered.map;
import repowdered.particles.register;
import sednalib;
import plutoecs;
import cereslib.jsonutils;
import dlib.container;

package void initRendering(Map map, World world)
{
    MapRenderSystem mrSystem = new MapRenderSystem(map);
    world.addSystem!MapRenderSystem(mrSystem);
}

/// Something that can be rendered on the map as a pixel
@scomponent public struct MapRenderable
{
    mixin MakeJsonizable;
public:
    @JsonizeField Color32 color = Color32(55, 55, 55);
}

/// A marker component that tells map renderable system to update the pixel of entity
public struct UpdateRenderableMarker
{

}

public final class MapRenderSystem
{
    mixin SystemMembers;
    private Sprite sprite;
    private ComponentPool!MapRenderable renderables;
    private ComponentPool!UpdateRenderableMarker markers;
    private ComponentPool!Position positions;
    private Map map;

    private struct SpriteBufferInfo
    {
        Color32 color;
        int[2] position;
    }

    private Array!SpriteBufferInfo bufferA;
    private Array!SpriteBufferInfo bufferB;

    private Array!SpriteBufferInfo* readBuffer;
    private Array!SpriteBufferInfo* writeBuffer;

    private bool hasNewFrame;

    public this(Map map)
    {
        this.map = map;

        readBuffer = &bufferA;
        writeBuffer = &bufferB;
    }

    public ref Sprite getMapSprite()
    {
        return sprite;
    }

    public void start()
    {
        renderables = myWorld.getPoolOf!MapRenderable;
        markers = myWorld.getPoolOf!UpdateRenderableMarker;
        positions = myWorld.getPoolOf!Position;

        SednalibPipeline.addOnceRenderTask(&initSprite);
        SednalibPipeline.addRenderTask(&drawSpriteTask);
        SednalibPipeline.addRenderTask(&updateRenderables);
        foreach(entity; map)
        {
            renderables.addComponent(entity);
            markers.addComponent(entity);
        }
    }

    public void update()
    {
        auto write = writeBuffer;

        write.resize(0, SpriteBufferInfo.init);

        auto data = markers.getComponents();
        if(data.length <= 0) return;
        foreach(i, ref marker; data)
        {
            Entity entity = markers.dense2Entity(i);
            auto renderable = renderables.getComponent(entity);

            immutable pos = positions.getComponent(entity);

            (*write) ~= SpriteBufferInfo(
                renderable.color,
                [pos.x, pos.y]
            );
        }

        synchronized(this)
        {
            auto tmp = readBuffer;
            readBuffer = writeBuffer;
            writeBuffer = tmp;

            hasNewFrame = true;
        }

        markers.removeAll();
    }

    private void initSprite(Window window)
    {
        sprite = Sprite([Settings.mapSettings.xResolution, Settings.mapSettings.yResolution], Color32(255, 255, 255));
    }

    private void drawSpriteTask(Window window)
    {
        sprite.draw();
    }

    private void updateRenderables(Window window)
    {
        Array!SpriteBufferInfo localBuffer;

        synchronized(this)
        {
            if(!hasNewFrame)
                return;

            localBuffer = *readBuffer;
            hasNewFrame = false;
        }

        foreach(ref info; localBuffer)
        {
            sprite.setPixel(cast(int[2]) info.position, info.color);
        }

        sprite.applyChanges();
    }
}