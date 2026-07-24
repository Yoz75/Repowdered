module repowdered.map;
import repowdered.exception;
import plutoecs;
import cereslib.optional;
import std.exception : enforce;
import std.traits : isNumeric;
import dlib.container.array;

alias PositionScalar = short;

/// Converts an array of two elements of `T` to array of two elements of `PositionScalar`
/// Params:
///    value = the value, that will be converted to `PositionScalar[2]`
/// Returns: a `PositionsScalar[2]` representation of `value`
pragma(inline, true)
public PositionScalar[2] toPS(T = int)(T[2] value) nothrow @nogc pure @safe if(isNumeric!T)
{
    return [cast(PositionScalar) value[0], cast(PositionScalar) value[1]];
}

/// Represents position of a particle on the map
public struct Position
{
    union 
    {
        struct
        {            
            /// The x coordinate
            PositionScalar x;

            /// The y coordinate
            PositionScalar y;
        }

        /// Array of combined x and y coordinates, where xy[0] is x and xy[1] is y. Needed for simple vector operations.
        PositionScalar[2] xy;
    }
}

public struct Neighbors
{
    union
    {
        Entity leftUpper;
        Entity upper;
        Entity rightUpper;
        Entity left;
        Entity right;
        Entity leftDown;
        Entity down;
        Entity rightDown;

        Entity[8] entities;
    }
}

/// This class represents the structure of Repowdered world (cellular automaton's grid)
public final class Map
{
public:
    /// The size of a map chunk. The map size must be a multiple of the chunk size. This is necessory for various optimizations.
    enum chunkSize = 16;
    
    immutable PositionScalar[2] resolution;
    private Array!Entity entities;
    private Array!Entity tempEntities;
    private ComponentPool!Position positions;

    this(PositionScalar xResolution, PositionScalar yResolution, World world)
    {
        resolution = [xResolution, yResolution];
        enforce!ArgumentException(xResolution % chunkSize == 0, 
         "x resolution of the map must be a multiple of " ~ chunkSize); 
        
        enforce!ArgumentException(xResolution % chunkSize == 0, 
         "x resolution of the map must be a multiple of " ~ chunkSize); 

        entities.reserve(xResolution * yResolution);
        tempEntities.reserve(xResolution * yResolution);

        positions = world.getPoolOf!Position;
        foreach(PositionScalar y; 0..yResolution)
        {
            foreach(PositionScalar x; 0..xResolution)
            {
                Entity entity = Entity(y * xResolution + x);
                positions.addComponent(entity, Position(x, y));
                entities ~= entity;
                tempEntities ~= entity;
            }
        }
    }

    ~this()
    {
        entities.free();
        tempEntities.free();
    }

    /// Get entity at position (position is automatically bounded to map size)
    /// Returns: entity at position
    pragma(inline, true) Entity getAt(Position position)
    {
        if(position.x < 0) position.x = 0;
        else if(position.x >= resolution[0]) position.x = cast(PositionScalar)(resolution[0] - 1);

        if(position.y < 0) position.y = 0;
        else if(position.y >= resolution[1]) position.y = cast(PositionScalar)(resolution[1] - 1);

        immutable auto index = position.y * resolution[0] + position.x;
        return entities[index];
    }
    
    pragma(inline, true) Optional!Entity tryGetAt(Position position)
    {
        if(position.x < 0 || position.x >= resolution[0]) return none!Entity;
        if(position.y < 0 || position.y >= resolution[1]) return none!Entity;

        immutable auto index = position.y * resolution[0] + position.x;
        return Optional!Entity(entities[index]);
    }

    /// Get neighbors of entity at `position`. If there is no nehgbor at position, it will be Entity(EntityId.max).
    /// Params:
    ///   position = the position of central entity
    /// Returns: `Neighbors` instance
    pragma(inline, true) Neighbors getNeighborsAt(Position position)
    {
        Neighbors result;
        result.entities[] = Entity.invalid;
        
        int index;
        foreach(y; -1..2)
        foreach(x; -1..2)
        {
            if(x == 0 && y == 0) continue;
            Position neighborPosition = position;
            neighborPosition.x += x;
            neighborPosition.y += y;

            auto optional = tryGetAt(neighborPosition);
            if(!optional.hasValue)
            {
                result.entities[index] = Entity.invalid;
                goto LEnd;
            }
            
            result.entities[index] = optional.value;

            LEnd:
            index++;
        }

        return result;
    }

    /// Swap two entities on the map and update their Position components
    pragma(inline, true) void swap(Entity first, Entity second)
    {
        ref Position firstPos = positions.getComponent(first);
        ref Position secondPos = positions.getComponent(second);
        Position temp = firstPos;     

        tempEntities[firstPos.y * resolution[0] + firstPos.x] = second;
        tempEntities[secondPos.y * resolution[0] + secondPos.x] = first;

        firstPos.xy[] = secondPos.xy[];
        secondPos.xy[] = temp.xy[];
    }

    /// Apply changes made to the map
    void applyChanges()
    {
        auto temp = entities;
        entities = tempEntities;
        tempEntities = temp;

        foreach(i, ref entity; tempEntities)
        {
            entity = entities[i];
        }
    }

    int opApply(scope int delegate(ref Entity) dg)
    {
        foreach(entity; entities)
        {
            immutable int result = dg(entity);
            if(result) return result;            
        }

        return 0;
    }
}

unittest
{
    Position pos;

    pos.x = 1;
    assert(pos.xy[0] == 1);

    pos.y = 2;
    assert(pos.y == 2);

    pos.xy = [6, 9];
    assert(pos.x == 6);
    assert(pos.y == 9);

    short[2] v = [1, -1];
    pos.xy[] -= v[];
    assert(pos.x == 5);
    assert(pos.y == 10);
}

unittest
{
    World world = new World();
    auto positions = world.getPoolOf!Position;
    Map map = new Map(128, 128, world);

    assert(map.entities.length == 128 * 128);
    assert(map.entities[0].id == 0);
    assert(map.entities[127].id == 127);
    assert(map.entities[128 * 64].id == 128 * 64);

    auto pos1 = [0, 0].toPS;
    assert(positions.getComponent(map.entities[0]).xy == pos1);

    auto pos2 = [10, 0].toPS;
    assert(positions.getComponent(map.entities[10]).xy == pos2);

    auto pos3 = [0, 1].toPS;
    assert(positions.getComponent(map.entities[128]).xy == pos3);
}