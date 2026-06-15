/// The module, in witch user make particles with their mouse
module repowdered.particles.creating.spawner;

import repowdered.particles.rendering;
import repowdered.map;
import repowdered.particles.register;
import repowdered.particles.loading;
import repowdered.particles.building;
import repowdered.particles.meta : OTM_Marker;
import repowdered.particles.rendering;
import repowdered.particles.creating.ui;
import repowdered.particles.creating.shapes;
import repowdered.particles.creating.shapeselector;
import plutoecs;
import cereslib.todo;
import cereslib.optional;
import sednalib;

public class ParticleSpawnerSystem
{
    mixin SystemMembers;
    enum float[2] categoryButtonSize = [0.05, 0.05];
    enum float[2] categoryButtonsAnchor = [0.93, 0.2];
    enum float[2] categoryButtonsMargin = [0, 0.075];

    enum float[2] typeButtonSize = categoryButtonSize;
    enum float[2] typeButtonsMargin = [-0.075, 0];
    enum float[2] typeButtonsAnchor = [0.93, 0.93];

    private SerializedParticleType airType;
    private SerializedParticleType selectedType;

    private ShapeSelectorSystem shapeSelector;
    private MapRenderSystem mapRenderer;

    private IInputAction spawnAction;
    private IInputAction destroyAction;


    public this(ShapeSelectorSystem shapeSelector, MapRenderSystem mapRenderSystem,
     IInputAction spawnAction, IInputAction destroyAction)
    {
        this.shapeSelector = shapeSelector;
        this.mapRenderer = mapRenderSystem;
        this.spawnAction = spawnAction;
        this.destroyAction = destroyAction;
    }

    public void selectType(SerializedParticleType type) pure
    {
        selectedType = type;
    }

    public void start()
    {
        airType = getAirType();

        assert(globalLoadedModules.length > 0, "CreateParticleSystem is being initialized, 
         but findAndLoadModules() still wasn't called!");
    }

    public void update()
    {
        auto shape = shapeSelector.getSelectedShape();

        immutable float[2] mouseWorldPos = screen2WorldPosition(Mouse.getPosition());
        immutable int[2] pos = world2SpritePosition(mapRenderer.getMapSprite(), mouseWorldPos);
        if(pos[0] < 0 || pos[1] < 0) return;

        shape.markBorders(pos);
        if(spawnAction.getState() != InputActionState.unactive)
        {
            mixin TODO!"Maybe set a default type?";
            if(selectedType == SerializedParticleType.init) return;        
            string* isOTM = OTM_Marker.stringof in selectedType.components;

            // If new particle is not an OTM (see OTM_Modifier) remove old one before building
            if(isOTM is null)
            {
                shape.deleteAtPos(pos);
            }

            shape.fillAtPosition(pos, selectedType);
        }
        else if(destroyAction.getState() != InputActionState.unactive)
        {
            shape.deleteAtPos(pos);
            shape.fillAtPosition(pos, airType);
        }
    }
}