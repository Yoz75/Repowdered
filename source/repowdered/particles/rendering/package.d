module repowdered.particles.rendering;

public import repowdered.particles.rendering.rendersystem;
public import repowdered.particles.rendering.components;
public import repowdered.particles.rendering.rmswitcher;
public import repowdered.particles.rendering.updaters;

import repowdered.map;
import plutoecs;
import sednalib.input;

public void initRendering(Map map, World world)
{
    int[2] resolution = [map.resolution[0], map.resolution[1]];
    // Yup, technically, default render mode and color render mode apllied when pressing key 1 are different instances
    auto defaultRenderMode = new ColorRenderer(resolution);

    auto mrSystem = new MapRenderSystem(map);
    mrSystem.setRenderMode( defaultRenderMode);

    auto rmsSystem = new RenderModeSwitcherSystem(mrSystem);

    world.addSystem!MapRenderSystem(mrSystem);
    world.addSystem!RenderModeSwitcherSystem(rmsSystem);

    addRenderModes(map, rmsSystem);
}

private void addRenderModes(Map map, RenderModeSwitcherSystem rmsSystem)
{
    int[2] resolution = [map.resolution[0], map.resolution[1]];

    auto colorRenderMode = new ColorRenderer(resolution);
    auto colorRenderModeAction = new KeyboardInputAction(KeyboardKey.one);

    rmsSystem.addRenderMode(colorRenderMode, colorRenderModeAction);
}
