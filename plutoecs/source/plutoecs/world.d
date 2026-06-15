module plutoecs.world;
import plutoecs.pool;
import plutoecs.system;
import std.container.binaryheap;
import dlib.container.array;
import std.datetime : Duration;

public alias UpdateAction = void delegate();
public alias DestroyAction = void delegate();
public final class World
{
    private struct PriorityUpdate
    {
        UpdateAction action;
        alias action this;

        long priority;

        public long opCmp(ref const PriorityUpdate other) const
        {
            return priority - other.priority;
        }
    }

    private Object[string] name2pool;
    private void*[string] name2system;
    // Try to use dlib array with binary heap
    private PriorityUpdate[] beforeUpdates;
    private PriorityUpdate[] updates;
    private PriorityUpdate[] afterUpdates;
    private Array!DestroyAction destructors;

    public ComponentPool!T getPoolOf(T)() nothrow pure
    {
        enum name = ComponentPool!T.stringof;
        auto pool = name in name2pool;

        if(pool is null)
        {
            auto newPool = new ComponentPool!T;
            name2pool[name] = newPool;
            return newPool;
        }

        return cast(ComponentPool!T) *pool;
    }

    public T getSystem(T)() nothrow pure if(isSystem!(T))
    {
        enum name = T.stringof;
        auto system = name in name2system;
        return (system is null) ? T.init : cast(T) *system;
    }

    public void beforeUpdate()
    {
        foreach(action; beforeUpdates)
        {
            action();
        }
    }

    public void update()
    {
        foreach(action; beforeUpdates)
        {
            action();
        }

        foreach(action; updates)
        {
            action();
        }

        foreach(action; afterUpdates)
        {
            action();
        }
    }

    public void afterUpdate()
    {
        foreach(action; afterUpdates)
        {
            action();
        }
    }

    /// Add a system to the world. This operation is pretty expensive, please don't call it multiple times per frame (or even once per frame)
    /// Params:
    ///   system = the system to be added to the range
    ///   priority = the priority of the system to be updated, greater = will be executed earlier. Default priority is 0.
    public void addSystem(T)(T system, long priority = 0) if(isSystem!(T))
    {
        import std.traits : hasMember, isFunction;

        name2system[T.stringof] = cast(void*) system;
        static if(__traits(compiles, {T.init.beforeUpdate();}))
        {
            beforeUpdates ~= PriorityUpdate(&system.beforeUpdate, priority);
            heapify(beforeUpdates);
        }

        static if(__traits(compiles, {T.init.update();}))
        {
            updates ~= PriorityUpdate(&system.update, priority);
            heapify(updates);
        }

        static if(__traits(compiles, {T.init.afterUpdate();}))
        {
            afterUpdates ~= PriorityUpdate(&system.afterUpdate, priority);
            heapify(afterUpdates);
        }

        system.setWorld(this);
        static if(__traits(compiles, {T.init.start();}))
        {
            system.start();
        }

        static if(__traits(compiles, {T.init.destroyed();}))
        {
            destructors ~= &system.destroyed;
        }
    }

    /// Cleanup world when game stopped or world changed
    package void destroy()
    {
        foreach(destructor; destructors)
        {
            destructor();
        }
    }
}

unittest
{
    import plutoecs.entity;
    struct A {}
    World world = new World();
    auto pool = world.getPoolOf!A;
    
    pool.addComponent(Entity(0));

    auto otherPool = world.getPoolOf!A;
    assert(otherPool.getComponents().length == 1);
}

unittest
{
    class ASystem
    {
        mixin SystemMembers;
    }

    auto system = new ASystem();
    auto world = new World();

    world.addSystem!ASystem(system);
    assert(world.getSystem!ASystem() is system);
}