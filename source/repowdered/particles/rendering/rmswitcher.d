module repowdered.particles.rendering.rmswitcher;

import repowdered.particles.rendering.updaters;
import repowdered.particles.rendering.rendersystem;
import sednalib.input;
import plutoecs;
import dlib;

/// Switches render modes
public final class RenderModeSwitcherSystem
{
    mixin SystemMembers;
    private struct RenderMode
    {
        IRenderModeRenderer updater;
        IInputAction inputAction;
    }
    
    Array!RenderMode renderModes;
    MapRenderSystem renderSystem;

    public this(MapRenderSystem renderSystem)
    {
        this.renderSystem = renderSystem;
    }

    public ~this()
    {
        renderModes.free();
    }

    /// Add a new render mode
    /// Params:
    ///   updater = the updater that'll update render buffer
    ///   action = the input action that switches render mode to this
    public void addRenderMode(IRenderModeRenderer renderMode, IInputAction action)
    {
        renderModes ~= RenderMode(renderMode, action);
    }

    public void update()
    {
        foreach(renderMode; renderModes)
        {
            if(renderMode.inputAction.getState() != InputActionState.unactive)
            {
                renderSystem.setRenderMode(renderMode.updater);
            }
        }
    }
}