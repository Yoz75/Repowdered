module repowdered.particles;

import repowdered.map;
public import repowdered.particles.rendering;
public import repowdered.particles.register;
public import repowdered.particles.loading;
public import repowdered.particles.building;
public import repowdered.particles.meta;
public import repowdered.particles.mechanics;
public import repowdered.particles.creating;
public import repowdered.particles.thermal;
import plutoecs;

/// Init all systems in particles package
void initParticlesSystems(Map map, World world)
{
    registerDefaultModules();
    findAndLoadModules();
    initRendering(map, world);
    initMechanics(map, world);
    initThermal(map, world);

    auto renderSystem = world.getSystem!MapRenderSystem;
    initParticleCreating(map, world, renderSystem);

    auto temperatureSystem = world.getSystem!TemperatureSystem();
    auto markers = world.getPoolOf!UpdateRenderableMarker();

    temperatureSystem.addOnTemperatureChanged((entity)
    {
        if(cast(ThermalRenderer) renderSystem.currentRenderMode)
        {
            markers.addComponent(entity);
        }
    });
    
}