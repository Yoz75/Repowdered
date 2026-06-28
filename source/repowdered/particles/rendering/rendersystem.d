module repowdered.particles.rendering.rendersystem;

import repowdered.sednapipeline;
import repowdered.settings;
import repowdered.map;
import repowdered.particles.register;
import repowdered.particles.rendering.renderers;
import repowdered.particles.rendering.components;
import sednalib;
import plutoecs;
import dlib.container;

/// The system that updates pixels on the map sprite
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

    private IRenderModeRenderer renderer;
    private Array!Color32 spriteBuffer;

    private enum shaderCode = import("shaders/texture/drawFromBuffer.fs");
    private BasicShader shader;
    private ShaderBuffer!Color32 shaderPixels;

    public this(Map map)
    {
        this.map = map;

        immutable resolution = map.resolution;
        immutable bufferResolution = resolution[0] * resolution[1];
        spriteBuffer.resize(bufferResolution, Color32(0));
        initSpriteBuffer();

        shader = new BasicShader();
        shaderPixels = new ShaderBuffer!Color32();
    }

    public ~this()
    {
        spriteBuffer.free();
        shaderPixels.free();
        shader.free();
    }

    public ref Sprite getMapSprite()
    {
        return sprite;
    }

    /// Set new render mode.
    /// Params:
    ///   updater = the lazy buffer updater, that will update the render buffer (i.e this is the render mode)
    public void setRenderMode(IRenderModeRenderer renderMode)
    {
        assert(renderMode !is null, "render mode is null!");
        this.renderer = renderMode;
    }

    /// Schedule the whole render bufer to update (e.g when updated render mode)
    public void scheduleUpdatingWholeSprite()
    {
        foreach(entity; map)
        {
            renderables.addComponent(entity);
            markers.addComponent(entity);
        }
    }

    public void start()
    {
        renderables = myWorld.getPoolOf!MapRenderable;
        markers = myWorld.getPoolOf!UpdateRenderableMarker;
        positions = myWorld.getPoolOf!Position;

        SednalibPipeline.addOnceRenderTask(&initShader);
        SednalibPipeline.addOnceRenderTask(&initSprite);
        SednalibPipeline.addRenderTask(&drawSpriteTask);

        scheduleUpdatingWholeSprite();
    }

    public void update()
    {
        synchronized(this)
        {
            renderer.update(spriteBuffer.data, myWorld, markers);
        }
        
        markers.removeAll();
    }

    /// Init sprite buffer with black and violet squares
    private void initSpriteBuffer()
    {
        foreach(i, ref pixel; spriteBuffer)
        {
            if(i % 3 == 0)
            {
                pixel = Color32(0);
            }
            else
            {
                pixel = Color32(255, 0, 255);
            }
        }
    }

    private void initSprite(Window window)
    {
        sprite = Sprite([Settings.mapSettings.xResolution, Settings.mapSettings.yResolution], Color32(255, 255, 255));
        sprite.shader = shader;
    }

    private void initShader(Window window)
    {
        immutable resolution = map.resolution;
        immutable bufferResolution = resolution[0] * resolution[1];

        shader.initMe(null, shaderCode);
        shaderPixels.initMe(bufferResolution, null, BufferUsageHint.StreamCPU2GPU);
        shader.attachBuffer(shaderPixels.internalId, 1);
    }

    private void drawSpriteTask(Window window)
    {
        synchronized(this)
        {
            shaderPixels.update(spriteBuffer.data);
        }
        sprite.draw();
    }
}