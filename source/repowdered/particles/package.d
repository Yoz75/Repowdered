module repowdered.particles;

import repowdered.map;
public import repowdered.particles.rendering;
public import repowdered.particles.register;
public import repowdered.particles.loading;
public import repowdered.particles.building;
public import repowdered.particles.meta;
public import repowdered.particles.mechanics;
public import repowdered.particles.creating;
import plutoecs;

/// Init all systems in particles package
void initParticlesSystems(Map map, World world)
{
    registerDefaultModules();
    findAndLoadModules();
    initRendering(map, world);
    initMechanics(map, world);
    initParticleCreating(map, world, world.getSystem!MapRenderSystem);
}