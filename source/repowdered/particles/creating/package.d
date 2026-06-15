module repowdered.particles.creating;

public import repowdered.particles.creating.spawner;
public import repowdered.particles.creating.shapeselector;
public import repowdered.particles.creating.shapecontroller;
public import repowdered.particles.creating.shapes;
public import repowdered.particles.creating.ui;
import repowdered.map;
import repowdered.particles.rendering;
import plutoecs;
import sednalib.graphics;
import sednalib.input;

public void initParticleCreating(Map map, World world, MapRenderSystem renderSystem)
{
    KeyboardInputAction nextKeyAction = new KeyboardInputAction(KeyboardKey.tab);
    MouseWheelAxisInputAction resizeAction = new MouseWheelAxisInputAction();
    CombinedInputAction resizeAvailableAction  
     = new CombinedInputAction(resizeAction, new KeyboardInputAction(KeyboardKey.leftControl));

    IShape[] shapes = [new Rectangle(world, map, renderSystem)];

    auto shapeSelector = new ShapeSelectorSystem(map, nextKeyAction, shapes);

    auto shapeController = new ShapeControllerSystem(resizeAvailableAction, resizeAction, shapeSelector, renderSystem);

    auto particleSpawner 
     = new ParticleSpawnerSystem(shapeSelector, renderSystem, 
     new MouseButtonInputAction(MouseButton.left), new MouseButtonInputAction(MouseButton.right));

    world.addSystem!ShapeSelectorSystem(shapeSelector);
    world.addSystem!ShapeControllerSystem(shapeController);
    world.addSystem!ParticleSpawnerSystem(particleSpawner);

    initUICreating(world, particleSpawner);
}