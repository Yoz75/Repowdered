module repowdered.particles.creating.shapecontroller;

import repowdered.particles.rendering;
import repowdered.particles.creating.shapes;
import repowdered.particles.creating.shapeselector;
import plutoecs;
import sednalib;


public final class ShapeControllerSystem
{
    mixin SystemMembers;

    private IInputAction resizeAvailableAction;
    private IAxisInputAction resizeAction;
    private ShapeSelectorSystem shapeSelector;
    private MapRenderSystem mapRenderer;

    public this(IInputAction resizeAvailableAction, IAxisInputAction resizeAction, ShapeSelectorSystem shapeSelector, MapRenderSystem mapRenderer)
    {   
        this.resizeAction = resizeAction;
        this.resizeAvailableAction = resizeAvailableAction;
        this.shapeSelector = shapeSelector;
        this.mapRenderer = mapRenderer;
    }

    public void update()
    {
        IShape currentShape = shapeSelector.getSelectedShape();

        immutable float[2] mouseWorldPos = screen2WorldPosition(Mouse.getPosition());
        immutable int[2] pos = world2SpritePosition(mapRenderer.getMapSprite(), mouseWorldPos);
        if(pos[0] < 0 || pos[1] < 0) return;

        currentShape.markBorders(pos);
        
        immutable shapeScale = currentShape.getScale();

        immutable float resizeAxis = resizeAction.getAxis();
        if(resizeAxis > 0 && resizeAvailableAction.getState() != InputActionState.unactive)
        {
            currentShape.setScale(shapeScale + 1);
        }
        else if(resizeAxis < 0 && resizeAvailableAction.getState() != InputActionState.unactive)
        {
            if(shapeScale <= 1) return;
            currentShape.setScale(shapeScale - 1);
        }
    }
}