module repowdered.particles.creating.shapeformer;

import repowdered.particles.rendering;
import repowdered.particles.creating.shapes;
import repowdered.particles.creating.shapeselector;
import plutoecs;
import sednalib;

/// Controls the shape's form
public final class ShapeFormControllerSystem
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