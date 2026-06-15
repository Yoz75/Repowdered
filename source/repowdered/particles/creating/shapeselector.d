module repowdered.particles.creating.shapeselector;

import plutoecs;
import repowdered.particles.rendering;
import repowdered.particles.creating.shapes;
import repowdered.map;
import sednalib;

package final class ShapeSelectorSystem
{
    mixin SystemMembers;

    private IShape[] shapes;
    private size_t selectedShapeId;

    public IShape getSelectedShape() => shapes[selectedShapeId];

    private IInputAction nextShapeAction;

    private Map map;

    public this(Map map,  IInputAction nextShapeAction, IShape[] shapes)
    {
        this.nextShapeAction = nextShapeAction;
        this.map = map;
        this.shapes = shapes;
    }

    public void start()
    {
        nextShapeAction = new KeyboardInputAction(KeyboardKey.tab);
        selectNextShape();
    }

    public void update()
    {
        if(nextShapeAction.getState() != InputActionState.unactive)
        {
            selectNextShape();
        }
    }

    private void selectNextShape()
    {
        selectedShapeId++;
        if(selectedShapeId >= shapes.length) selectedShapeId = 0;
    }
}