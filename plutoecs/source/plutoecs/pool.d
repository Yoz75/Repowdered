module plutoecs.pool;
import plutoecs.entity;
import plutoecs.world;
import dlib.container.array;
import std.parallelism;

/// Executes `dg` for each component in pool
/// Params:
///   dg = the delegate executed for each component. size_t parameter is the dense id and ref parameter is the component!
public void forEach(alias pool)(scope void delegate(size_t, ref pool.ComponentType) dg)
{
    auto data = pool.getComponents();

    foreach(i, ref component; data)
    {
        dg(i, component);
    }
}

/// Mixin template for using `forEach` and `forEachValue` with has constraits.
/// `forEach` expects all parameters to be references
/// `forEachValue` expects first parameter to be reference and "has-parameters" to be value passed:
/// -------------------------------
///    struct A {}
///    struct B {}
///    struct C {}
///    
///    ComponentPool!A alfas = new ComponentPool!A;
///    ComponentPool!B betas = new ComponentPool!B;
///    ComponentPool!C gammas = new ComponentPool!C;
///
///    void handleValue(size_t denseID, ref A a, B hasB, C hasC)
///    {
///        Entity entity = alfas.dense2Entity(denseID);
///        assert(entity.id == 0);
///    }
///
///    void handle(size_t denseID, ref A a, ref B hasB, ref C hasC)
///    {
///        Entity entity = alfas.dense2Entity(denseID);
///        assert(entity.id == 0);
///    }
///
///    Entity entityHasAll = Entity(0);
///    Entity entityHasnt = Entity(1);
///
///    alfas.addComponent(entityHasAll);
///    alfas.addComponent(entityHasnt);
///
///    betas.addComponent(entityHasAll);
///    gammas.addComponent(entityHasAll);    
///
///    mixin forEach!(alfas, betas, gammas);
///
///    forEach(&handle);
///    forEachValue(&handleValue);
/// -------------------------------
/// Params:
///   pool = the pool for iterationg
public mixin template forEach(alias pool, hasPools...)
{
    private string __variadic2PoolsDeclaration(bool useRef)() 
    {
        import std.string;
        string result;

        static foreach(hasPool; hasPools)
        {
            static if( useRef)
            {
                result ~= "ref ";
            }
            result ~= hasPool.ComponentType.stringof ~ ", ";
        }

        result = result[0..$-2]; // remove last ", "

        return result;
    }

    private string __variadic2PoolsCall() 
    {
        import std.string;
        import std.conv;
        string result;

        static foreach(i, hasPool; hasPools)
        {
            result ~= "hasPools[" ~ i.to!string ~ "].getComponent(entity), ";
        }

        result = result[0..$-2]; // remove last ", "

        return result;
    }

    mixin("public void forEachValue(scope void delegate(size_t denseID, ref pool.ComponentType, " 
     ~ __variadic2PoolsDeclaration!false() ~ ") dg)
    {
        auto data = pool.getComponents();

        LProcess: foreach(i, component; data)
        {
            Entity entity = pool.dense2Entity(i);

            static foreach(hasPool; hasPools)
            {
                if(!hasPool.hasComponent(entity)) continue LProcess;
            }

            dg(i, pool.getComponent(entity), "~ __variadic2PoolsCall() ~");
        }
    }");

    
    mixin("public void forEach(scope void delegate(size_t denseID, ref pool.ComponentType, " 
     ~ __variadic2PoolsDeclaration!true() ~ ") dg)
    {
        auto data = pool.getComponents();    

        LProcess: foreach(i, ref component; data)
        {
            Entity entity = pool.dense2Entity(i);

            static foreach(hasPool; hasPools)
            {
                if(!hasPool.hasComponent(entity)) continue LProcess;
            }

            dg(i, component, "~ __variadic2PoolsCall() ~");
        }
    }");

    mixin("public void forEachParallel(scope void delegate(size_t denseID, ref pool.ComponentType, " 
     ~ __variadic2PoolsDeclaration!true() ~ ") dg)
    {
        import std.parallelism : parallel;
        auto data = pool.getComponents();    

        foreach(i, ref component; data.parallel)
        {
            Entity entity = pool.dense2Entity(i);

            static foreach(hasPool; hasPools)
            {
                if(!hasPool.hasComponent(entity)) goto LProcess;
            }

            dg(i, component, "~ __variadic2PoolsCall() ~");
            LProcess:
        }
    }");
}



alias onRemoveAction = void delegate(Entity entity);
alias onAddAction = void delegate(Entity entity);

private enum chunkSize = 128;
public alias ComponentArray(T) = Array!(T, chunkSize);

/// Type that contains components. `T` can be every type.
public final class ComponentPool(TComponent)
{
    public alias ComponentType = TComponent;

    private ComponentArray!TComponent dense;
    private ComponentArray!Entity entities;        // dense index -> entity id
    private ComponentArray!size_t sparse;          // entity id -> dense index

    private onAddAction[] onAddDelegates;
    private onRemoveAction[] onRemoveDelegates;

    ~this()
    {
        dense.free();
        entities.free();
        sparse.free();
    }

    public Entity dense2Entity(size_t denseId)
    {
        return entities[denseId];
    }

    /// Reserve space for components in the world
    /// Params:
    ///   world = the world
    ///   componentsCount = count of reserved components 
    public void reserve(size_t componentsCount)
    {
        dense.reserve(componentsCount);
        entities.reserve(componentsCount);
    }

    /// Add component to entity
    /// Params:
    ///   entity = the entity
    ///   value = the value of added component
    public void addComponent(Entity entity, TComponent value = TComponent.init)
    {
        ensureSparse(entity);
        if (hasComponent(entity))
        {
            dense[sparse[entity.id]] = value;            
        }
        else
        {
            auto index = dense.length;

            dense ~= value;
            entities ~= entity;
            sparse[entity.id] = index;
        }

        foreach (onAddDelegate; onAddDelegates)
        {
            onAddDelegate(entity);
        }
    }

    public void removeAll()
    {
        if (dense.length == 0)
            return;

        if (onRemoveDelegates.length > 0)
        {
            foreach (index; 0..dense.length)
            {
                Entity entity = entities[index];

                sparse[entity.id] = size_t.max;

                foreach (onRemove; onRemoveDelegates)
                {
                    onRemove(entity);
                }
            }
        }
        else
        {
            foreach (index, _; dense)
            {
                Entity entity = dense2Entity(index);
                sparse[entity.id] = size_t.max;
            }
        }

        dense.resize(0, TComponent.init);
        entities.resize(0, Entity(EntityId.max));
    }

    /// Remove component from entity. If entity already doesn't have this component, nothing will happen
    public void removeComponent(Entity entity)
    { 
        if (!hasComponent(entity))
            return;

        auto index = sparse[entity.id];
        auto lastIndex = dense.length - 1;
        auto lastEntity = entities[lastIndex];

        // swap-remove
        dense[index] = dense[lastIndex];
        entities[index] = lastEntity;
        sparse[lastEntity.id] = index;

        dense.removeBack(1);
        entities.removeBack(1);

        // mark as removed
        sparse[entity.id] = size_t.max;

        foreach (onRemove; onRemoveDelegates)
        {
            onRemove(entity);
        }
    }
    
    public void addOnRemoveAction(scope onRemoveAction action)
    {
        onRemoveDelegates ~= action;
    }

    public void addOnAddAction(scope onAddAction action)
    {
        onAddDelegates ~= action;
    }

    public TComponent[] getComponents()
    {
        return dense.data;
    }

    /// Get component for entity
    /// Params:
    ///   entity = the entity
    /// Returns: the component value. Check if this value valid with `hasComponent`` method
    // when error is true
    public ref TComponent getComponent(Entity entity)
    {
        auto eid = entity.id;

        auto idx = sparse[eid];

        if(idx == EntityId.max)
        {
            import std.conv : to;
            throw new Exception("Entity " ~ entity.id.to!string ~ " does not have component " ~ TComponent.stringof);
        }

        return dense.data[idx];
    }

    /// Is this entity has component `TComponent` or not?
    /// Params:
    ///   entity = the entity
    /// Returns: true if has, false otherwise
    public bool hasComponent(Entity entity)
    {
        if (entity.id >= sparse.length) return false;

        auto idx = sparse[entity.id];

        if (idx == EntityId.max) return false;

        return idx < entities.length &&
            entities[idx].id == entity.id;
    }

    private void ensureSparse(Entity entity)
    {
        if (entity.id >= sparse.length)
        {
            sparse.resize(entity.id + chunkSize, size_t.max);
        }
    }
}

unittest
{
    struct A {}
    ComponentPool!A alfas = new ComponentPool!A();
}

unittest
{
    struct A 
    {
        int a = 128;
    }

    ComponentPool!A alfas = new ComponentPool!A();
    Entity entity = Entity(0);

    alfas.addComponent(entity, A(127));
    assert(alfas.hasComponent(entity));
    assert(alfas.getComponent(entity).a == 127);

    ref A alfa = alfas.getComponent(entity);
    assert(alfa.a == 127);
    alfa.a = 10;
    assert(alfas.getComponent(entity).a == 10);
}

unittest
{
    import std.conv;
    struct A 
    {
        int a = 0;
    }

    ComponentPool!A alfas = new ComponentPool!A();
    Entity entity0 = Entity(0);
    Entity entity1 = Entity(1);
    Entity entity2 = Entity(2);
    Entity entity3 = Entity(3);

    alfas.addComponent(entity0, A(256));
    alfas.addComponent(entity1);
    alfas.addComponent(entity2, A(69));
    alfas.addComponent(entity3);

    auto ref data = alfas.getComponents();
    
    assert(data.length == 4);
    assert(data[0].a == 256);
    assert(data[1].a == 0);
    assert(data[2].a == 69);
    assert(data[3].a == 0);

    data[3].a = 100;
    assert(alfas.getComponents()[3].a == 100, alfas.getComponents()[3].a.to!string);
}

unittest
{
    struct A {}
    struct B { int v = 0;}
    struct C {}
    
    ComponentPool!A alfas = new ComponentPool!A;
    ComponentPool!B betas = new ComponentPool!B;
    ComponentPool!C gammas = new ComponentPool!C;

    void handleValue(size_t denseID, ref A a, B hasB, C hasC)
    {
        Entity entity = alfas.dense2Entity(denseID);
        assert(entity.id == 0);
    }

    void handle(size_t denseID, ref A a, ref B hasB, ref C hasC)
    {
        Entity entity = alfas.dense2Entity(denseID);
        assert(entity.id == 0);

        hasB.v = 10;
    }

    Entity entityHasAll = Entity(0);
    Entity entityHasnt = Entity(1);

    alfas.addComponent(entityHasAll);
    alfas.addComponent(entityHasnt);

    betas.addComponent(entityHasAll);
    gammas.addComponent(entityHasAll);    

    mixin forEach!(alfas, betas, gammas);

    forEach(&handle);
    assert(betas.getComponent(entityHasAll).v == 10);
    forEachValue(&handleValue);
}