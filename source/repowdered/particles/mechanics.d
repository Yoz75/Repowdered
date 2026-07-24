/// Mechanics (in a physics sense) related components and systems.
module repowdered.particles.mechanics;

import repowdered.particles.meta;
import repowdered.particles.rendering;
import repowdered.map;
import repowdered.particles.register;
import cereslib.jsonutils;
import plutoecs;
import sednalib;

package void initMechanics(Map map, World world)
{
    auto movableSystem = new MovableSystem(map);
    auto gravitySystem = new GravitySystem();
    auto powderSystem = new PowderSystem();
    auto adhesionSystem = new AdhesionSystem(map);

    auto upGravityAction = new KeyboardInputAction(KeyboardKey.up);
    auto downGravityAction = new KeyboardInputAction(KeyboardKey.down);
    auto leftGravityAction = new KeyboardInputAction(KeyboardKey.left);
    auto rightGravityAction = new KeyboardInputAction(KeyboardKey.right);
    auto noneGravityAction = new KeyboardInputAction(KeyboardKey.e);

    auto changeGravitySystem = new ChangeGravitySystem(upGravityAction, downGravityAction,
     leftGravityAction, rightGravityAction, noneGravityAction);

    world.addSystem!MovableSystem(movableSystem);
    world.addSystem!GravitySystem(gravitySystem);
    world.addSystem!PowderSystem(powderSystem);
    world.addSystem!AdhesionSystem(adhesionSystem);
    world.addSystem!ChangeGravitySystem(changeGravitySystem);
}

alias VelocityScalar = byte;

public struct GravityValue
{
    VelocityScalar[2] vector;
    GravityDirection direction;
}

public enum GravityDirection : ubyte
{
    none,
    down,
    up,
    left,
    right
}

public enum Gravity : GravityValue
{
    none = GravityValue([0, 0], GravityDirection.none),
    down = GravityValue([0, 1], GravityDirection.down),
    up = GravityValue([0, -1], GravityDirection.up),
    left = GravityValue([-1, 0], GravityDirection.left),
    right = GravityValue([1, 0], GravityDirection.right)
}

// A marker component, that indicates that this particle is affected by gravity
@scomponent public struct GravityMarker
{
    mixin MakeJsonizable;

public:
    static Gravity gravity = Gravity.down;
    static VelocityScalar scale = 10;
}

/// Component that says that this entity can move
@scomponent public struct Movable
{
    mixin MakeJsonizable;

public:
    static VelocityScalar maxVelocity = cast(VelocityScalar) 100;
    /// Current velocity of the particle [x, y] in cells per update
    VelocityScalar[2] velocity = [0, 0];
    bool isFalling;
}

/// A marker component, that indicates that this particle should slip like sand
@scomponent public struct Powder
{
    mixin MakeJsonizable;
}

/// A component that indicates slip particles
@scomponent public struct Adhesion
{
    mixin MakeJsonizable;

public:
    /// The slipperiness of particle in range 0..1
    @JsonizeField float adhesion = 1;
    /// How much cells per movement particle wants to go?
    @JsonizeField ubyte liquidness = 2;
}

/// A particle, that can turn into `result` when hits `other`
@scomponent public struct Combine
{
    mixin MakeJsonizable;
public:
    @JsonizeField TypeName otherId;
    @JsonizeField TypeName resultId;
}

@scomponent public struct Gas
{
    mixin MakeJsonizable;
}

package final class GravitySystem
{
    mixin SystemMembers;

    public ComponentPool!GravityMarker gravityMarkers;
    public ComponentPool!Movable movables;

    mixin ComponentHasUpdate!(gravityMarkers, UpdateType.update, movables);

    public void start()
    {
        gravityMarkers = myWorld.getPoolOf!GravityMarker;
        movables = myWorld.getPoolOf!Movable;
    }

    private void updateComponent(size_t denseId, ref GravityMarker marker, ref Movable movable)
    {
        movable.velocity[] += GravityMarker.gravity.vector[] * marker.scale;
    }
}

package class ChangeGravitySystem
{
    mixin SystemMembers;
    private IInputAction upDirectionAction, downDirectionAction,
     leftDirectionAction, rightDirectionAction, noneDirectionAction;

    public this(IInputAction upAction, IInputAction downAction, 
        IInputAction leftAction, IInputAction rightAction, IInputAction noneAction)
    {
        upDirectionAction = upAction;
        downDirectionAction = downAction;
        leftDirectionAction = leftAction;
        rightDirectionAction = rightAction;
        noneDirectionAction = noneAction;
    }

    public void update()
    {
        if (upDirectionAction.getState() != InputActionState.unactive)
        {
            GravityMarker.gravity = Gravity.up;
        }
        else if (downDirectionAction.getState() != InputActionState.unactive)
        {
            GravityMarker.gravity = Gravity.down;
        }
        else if (leftDirectionAction.getState() != InputActionState.unactive)
        {
            GravityMarker.gravity = Gravity.left;
        }
        else if (rightDirectionAction.getState() != InputActionState.unactive)
        {
            GravityMarker.gravity = Gravity.right;
        }
        else if (noneDirectionAction.getState() != InputActionState.unactive)
        {
            GravityMarker.gravity = Gravity.none;
        }
    }
}

package final class MovableSystem
{
    mixin SystemMembers;

    public ComponentPool!Movable movables;
    private ComponentPool!Position positions;
    private ComponentPool!HollowMarker hollowMarkers;
    private ComponentPool!UpdateRenderableMarker updateMarkers;

    private Map map;

    mixin ComponentUpdate!(movables);

    public this(Map map)
    {
        this.map = map;
    }

    public void start()
    {
        movables = myWorld.getPoolOf!Movable;
        positions = myWorld.getPoolOf!Position;
        hollowMarkers = myWorld.getPoolOf!HollowMarker;
        updateMarkers = myWorld.getPoolOf!UpdateRenderableMarker;
    }

    private void updateComponent(size_t denseId, ref Movable movable)
    {
        import std.math : round;
        import std.algorithm : clamp;

        Entity entity = movables.dense2Entity(denseId);
        Position currentPosition = positions.getComponent(entity);

        movable.isFalling = true;
        if(movable.velocity[0] == 0 && movable.velocity[1] == 0) return;

        movable.velocity[0] = movable.velocity[0].clamp(cast(VelocityScalar) -Movable.maxVelocity, Movable.maxVelocity);
        movable.velocity[1] = movable.velocity[1].clamp(cast(VelocityScalar) -Movable.maxVelocity, Movable.maxVelocity);

        immutable PositionScalar[2] velocity = movable.velocity.toPS();

        Position targetPosition;
        targetPosition.xy[] = currentPosition.xy[] + velocity[];

        immutable finalPosition = findLastFreeCellOnLine(currentPosition, targetPosition);
        if(finalPosition == currentPosition)
        {
            movable.velocity = [0, 0];
            movable.isFalling = false;
            return;
        }

        Entity other = map.getAt(finalPosition);
        
        if(finalPosition != targetPosition)
        {
            movable.velocity = [0, 0];
            movable.isFalling = false;
        }

        map.swap(entity, other);
        updateMarkers.addComponent(entity);
        updateMarkers.addComponent(other);
    }

    private Position findLastFreeCellOnLine(Position start, Position end)
    {
        import repowdered.particles.loading : airTypeId;
        import std.algorithm : max;
        import std.math : abs;

        immutable deltaX = end.x - start.x;
        immutable deltaY = end.y - start.y;

        immutable stepsCount = max(abs(deltaX), abs(deltaY));
        if(stepsCount == 0) return start;

        double stepX = cast(double) deltaX / stepsCount;
        double stepY = cast(double) deltaY / stepsCount;

        auto lastFree = start;

        for(PositionScalar i = 1; i <= stepsCount; i++)
        {
            PositionScalar x = cast(PositionScalar) (start.x + stepX * i);
            PositionScalar y = cast(PositionScalar) (start.y + stepY * i);
            immutable Position checkedPosition = Position(x, y);

            const entity = map.tryGetAt(checkedPosition);
            if(!entity.hasValue || !hollowMarkers.hasComponent(entity.value)) break;
            lastFree = checkedPosition;
        }

        return lastFree;
    }
}

public final class PowderSystem
{
    mixin SystemMembers;

    private uint fallDirection;
    private ComponentPool!Powder powders;
    private ComponentPool!Movable movables;

    /*
           -1 0 1
        -1 [][][]
         0 []xx[]
         1 [][][]
    */
    immutable static VelocityScalar[2][2][GravityDirection.max + 1] biases = 
    [
        GravityDirection.none: [[0, 0], [0, 0]],
        GravityDirection.down: [[1, 1], [-1, 1]],
        GravityDirection.up: [[-1, -1], [1, -1]],
        GravityDirection.left: [[-1, -1], [-1, 1]],
        GravityDirection.right: [[1, -1], [1, 1]]
    ];

    public void start()
    {
        powders = myWorld.getPoolOf!Powder();
        movables = myWorld.getPoolOf!Movable();
    }

    public void update()
    {
        if(GameLoop.timeScale <= 0) return;
        fallDirection++;

        mixin forEach!(powders, movables);
        forEach(&updateComponent);
    }

    pragma(inline, true)
    private void updateComponent(size_t denseId, ref Powder powder, ref Movable movable)
    {
        if(movable.isFalling) return;

        //Every odd frame fall to one side and every even to the other
        movable.velocity = biases[GravityMarker.gravity.direction][fallDirection & 1];
    }
}

public final class AdhesionSystem
{
    mixin SystemMembers;

    private uint fallDirection;
    private ComponentPool!Adhesion adhesions;
    private ComponentPool!Movable movables;
    private ComponentPool!Position positions;
    private ComponentPool!TypeName names;

    Map map;

    /*
       -1 0 1
    -1 [][][]
     0 []xx[]
     1 [][][]
    */
    immutable static VelocityScalar[2][2][GravityDirection.max + 1] biases = 
    [
        GravityDirection.none: [[0, 0], [0, 0]],
        GravityDirection.down: [[-1, 0], [1, 0]],
        GravityDirection.left: [[0, -1], [0, 1]],
        GravityDirection.right: [[-1, 0], [1, 0]],
        GravityDirection.up: [[-1, 0], [1, 0]]
    ];

    public this(Map map)
    {
        this.map = map;
    }

    public void start()
    {
        adhesions = myWorld.getPoolOf!Adhesion();
        movables = myWorld.getPoolOf!Movable();
        positions = myWorld.getPoolOf!Position();
        names = myWorld.getPoolOf!TypeName();
    }

    public void update()
    {
        if(GameLoop.timeScale <= 0) return;
        fallDirection++;

        mixin forEach!(adhesions, movables);
        forEach(&updateComponent);
    }

    pragma(inline, true)
    private void updateComponent(size_t denseId, ref Adhesion adhesion, ref Movable movable)
    {
        import repowdered.particles.loading : airTypeId;
        import std.random;

        if(movable.isFalling) return;
        Entity entity = adhesions.dense2Entity(denseId);

        auto position = positions.getComponent(entity);
        position.x += GravityMarker.gravity.vector[0];
        position.y += GravityMarker.gravity.vector[1];

        if(names.getComponent(map.getAt(position)).name == airTypeId) return;

        VelocityScalar[2][2] resultBiases;

        if(uniform01() >= adhesion.adhesion)
        {
            resultBiases = biases[GravityMarker.gravity.direction];
        }
        else
        {
            resultBiases = [0, 0];
        }

        movable.velocity = resultBiases[uniform(0, 2)];
        movable.velocity[] *= adhesion.liquidness;
    }
}

            immutable multiplier = uniform!("[)", ubyte, ubyte)(one, adhesion.liquidness);
            movable.velocity[] *= multiplier;
        }
    }
}