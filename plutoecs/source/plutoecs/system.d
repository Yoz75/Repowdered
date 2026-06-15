module plutoecs.system;

import plutoecs.world;

/// Mixin that adds some members to a type and makes it a system (update and other methods should be added mannually!)
public mixin template SystemMembers()
{
    /// The system's world
    protected World myWorld;

    public void setWorld(World world)
    {
        this.myWorld = world;
    }
}

/// Returns true if `T` is a system type and false otherwise. To become a system, a type should mix in `SystemMembers` and can be assignable to a null value
public template isSystem(T)
{
    enum isSystem = __traits(compiles, {T.init.setWorld(World.init);}) && __traits(compiles, {T system = null;});
}

/// The type of the update
public enum UpdateType : ubyte
{
    /// Method called before the update
    beforeUpdate = 0,
    /// The update
    update,
    /// Method called after update
    afterUpdate
}

/// Mixes in logic required to use `beforeUpdateComponent(ref Component component)`, `updateComponent(ref Component component)` 
/// and `afterUpdateComponent(ref Component component)`. Won't update if GameLoop.timeScale <= 0.
/// Params:
///   pool = the iterated pool. Must be a public variable.
public mixin template ComponentUpdate(alias pool, UpdateType type = UpdateType.update)
{
    import plutoecs.pool;
    static if(type == UpdateType.beforeUpdate)
    {
        enum methodPrefix = "beforeUpdate";
    }
    else static if(type == UpdateType.update)
    {
        enum methodPrefix = "update";
    }
    else static if(type == UpdateType.update)
    {
        enum methodPrefix = "update";
    }

    import std.traits : lvalueOf;

    mixin("public void " ~ methodPrefix ~ "() 
    {
        if(GameLoop.timeScale <= 0) return;
        forEach!pool(&" ~ methodPrefix ~"Component);
    }");
}

/// A mixin for easy use of `forEach` **template**
/// Params:
///   pool = the main pool witch will be lineary searched
///   type = the update type
///   hasPools = entity must have components in these pools
/// --------
///    import plutoecs.pool;
///    import plutoecs.world;
///    import plutoecs.entity;
///
///    struct A
///    {
///        int a = 0;
///    }
///
///    struct B 
///    {
///
///    }
///
///    struct C
///    {
///
///    }
///
///    final class ASystem
///    {
///        mixin SystemMembers;
///
///        public ComponentPool!A poolA;
///        public ComponentPool!B poolB;
///        public ComponentPool!C poolC;
///        mixin ComponentHasUpdate!(poolA, UpdateType.update, poolB, poolC);
///
///        bool wasUpdateComponentCalled;
///
///        this()
///        {
///            poolA = new ComponentPool!A;
///            poolB = new ComponentPool!B;
///            poolC = new ComponentPool!C;
///        }
///
///        private void updateComponent(size_t denseId, ref A a, ref B b, ref C c)
///        {
///            assert(a.a == 69);
///            assert(poolA.dense2Entity(denseId).id == 100_500);
///
///            wasUpdateComponentCalled = true;
///        }
///
///    }
///    ASystem system = new ASystem();
///
///    Entity entity = Entity(100_500);
///    Entity entity2 = Entity(1);
///    Entity entity3 = Entity(0);
///
///    system.poolA.addComponent(entity, A(69));
///    system.poolB.addComponent(entity);
///    system.poolC.addComponent(entity);
///
///    system.poolA.addComponent(entity2, A(67));
///    system.poolB.addComponent(entity2);
///
/// system.poolA.addComponent(entity3, A(61));
///
///    system.update();
///
///    assert(system.wasUpdateComponentCalled);
/// --------
public mixin template ComponentHasUpdate(alias pool, UpdateType type, hasPools...)
{
    import plutoecs.pool;
    static if(type == UpdateType.beforeUpdate)
    {
        enum methodPrefix = "beforeUpdate";
    }
    else static if(type == UpdateType.update)
    {
        enum methodPrefix = "update";
    }
    else static if(type == UpdateType.update)
    {
        enum methodPrefix = "update";
    }

    private static string __variadic2PoolsCall() 
    {
        import std.string;
        import std.conv;
        string result;

        static foreach(i, hasPool; hasPools)
        {
            result ~= "hasPools[" ~ i.to!string ~ "], ";
        }

        result = result[0..$-2]; // remove last ", "

        return result;
    }

    mixin("public void " ~ methodPrefix ~ "() 
    {
        if(GameLoop.timeScale <= 0) return;
        mixin forEach!(pool, " ~ __variadic2PoolsCall() ~ ");
        forEach(&" ~ methodPrefix ~"Component);
    }");
}

/// Same as `ComponentHasUpdate`, but uses `forEachValue` (has components are passed by value)
/// Params:
///   pool = the main pool witch will be lineary searched
///   type = the update type
///   hasPools = entity must have components in these pools
public mixin template ComponentHasUpdateValue(alias pool, UpdateType type, hasPools...)
{
    import plutoecs.pool;
    static if(type == UpdateType.beforeUpdate)
    {
        enum methodPrefix = "beforeUpdate";
    }
    else static if(type == UpdateType.update)
    {
        enum methodPrefix = "update";
    }
    else static if(type == UpdateType.update)
    {
        enum methodPrefix = "update";
    }

    private static string __variadic2PoolsCall() 
    {
        import std.string;
        import std.conv;
        string result;

        static foreach(i, hasPool; hasPools)
        {
            result ~= "hasPools[" ~ i.to!string ~ "], ";
        }

        result = result[0..$-2]; // remove last ", "

        return result;
    }

    mixin("public void " ~ methodPrefix ~ "() 
    {
        mixin forEach!(pool, " ~ __variadic2PoolsCall() ~ ");
        forEachValue(&" ~ methodPrefix ~"Component);
    }");
}


unittest
{
    struct StructSystem
    {
        mixin SystemMembers;
    }

    class ClassSystem
    {
        mixin SystemMembers;
    }

    struct S
    {

    }

    class C
    {

    }

    static assert(isSystem!(StructSystem*));
    static assert(isSystem!(ClassSystem));

    static assert(!isSystem!(S));
    static assert(!isSystem!(C));
}

unittest
{
    import plutoecs.pool;
    import plutoecs.world;
    import plutoecs.entity;

    struct A
    {
        int a = 0;
    }

    final class ASystem
    {
        mixin SystemMembers;

        public ComponentPool!A pool;
        mixin ComponentUpdate!pool;

        bool wasUpdateComponentCalled;

        this()
        {
            pool = new ComponentPool!A;
        }

        private void updateComponent(size_t denseId, ref A a)
        {
            assert(a.a == 69);
            assert(pool.dense2Entity(denseId).id == 100_500);

            wasUpdateComponentCalled = true;
        }

    }

    ASystem system = new ASystem();

    Entity entity = Entity(100_500);
    system.pool.addComponent(entity, A(69));
    system.update();

    assert(system.wasUpdateComponentCalled);
}

unittest
{
    import plutoecs.pool;
    import plutoecs.world;
    import plutoecs.entity;

    struct A
    {
        int a = 0;
    }

    struct B 
    {

    }

    struct C
    {

    }

    final class ASystem
    {
        mixin SystemMembers;

        public ComponentPool!A poolA;
        public ComponentPool!B poolB;
        public ComponentPool!C poolC;
        mixin ComponentHasUpdate!(poolA, UpdateType.update, poolB, poolC);

        bool wasUpdateComponentCalled;

        this()
        {
            poolA = new ComponentPool!A;
            poolB = new ComponentPool!B;
            poolC = new ComponentPool!C;
        }

        private void updateComponent(size_t denseId, ref A a, ref B b, ref C c)
        {
            assert(a.a == 69);
            assert(poolA.dense2Entity(denseId).id == 100_500);

            wasUpdateComponentCalled = true;
        }

    }

    ASystem system = new ASystem();

    Entity entity = Entity(100_500);
    Entity entity2 = Entity(1);
    Entity entity3 = Entity(0);

    system.poolA.addComponent(entity, A(69));
    system.poolB.addComponent(entity);
    system.poolC.addComponent(entity);

    system.poolA.addComponent(entity2, A(67));
    system.poolB.addComponent(entity2);

    system.poolA.addComponent(entity3, A(61));

    system.update();

    assert(system.wasUpdateComponentCalled);
}