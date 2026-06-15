module repowdered.entry;
import repowdered.settings;
import repowdered.catalogues;
import repowdered.map;
import repowdered.sednapipeline;
import repowdered.particles;
import repowdered.camera;
import repowdered.settings;
import repowdered.ui;
import repowdered.timecontrol;
import plutoecs;
import cereslib.jsonutils;
import cereslib.versions;

private final class ExitSystem
{
    mixin SystemMembers;

    public void update()
    {
        if(SednalibPipeline.isPipelineStopped)
        {
            GameLoop.stop();
        }
    }
}

private final class ApplyMapChangesSystem
{
    mixin SystemMembers;

    private Map map;

    public this(Map map)
    {
        this.map = map;
    }

    public void afterUpdate()
    {
        map.applyChanges();
    }
}

public void startGame()
{
    programVersion = Version.fromString(import("version.txt"));
    startGameScene();
}

private void startGameScene()
{
    import std.functional : toDelegate;
    initSettings();
    
    World gameWorld = new World();
    auto map = new Map(Settings.mapSettings.xResolution, Settings.mapSettings.yResolution, gameWorld);

    auto applyChangesSystem = new ApplyMapChangesSystem(map);
    gameWorld.addSystem!ApplyMapChangesSystem(applyChangesSystem, long.max);

    ExitSystem exitSystem = new ExitSystem();
    gameWorld.addSystem!ExitSystem(exitSystem);

    SednalibPipeline.initialize();
    SednalibPipeline.addOnceUITask(toDelegate(&initUI));

    initParticlesSystems(map, gameWorld);
    initCamera(gameWorld);
    initTimeControl(gameWorld);   

    fillMapWithDefaultType(gameWorld, map);
    GameLoop.run(gameWorld);
}

private void fillMapWithDefaultType(World world, Map map)
{
    foreach(entity; map)
    {
        buildAir(world, entity);
    } 
}