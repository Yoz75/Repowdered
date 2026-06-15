/// The module, in witch we add particles to the map
module repowdered.particles.building;

import cereslib.todo;
import cereslib.optional;
import plutoecs;
import repowdered.map : Position;
import repowdered.particles.rendering : UpdateRenderableMarker;
import repowdered.particles.meta;
import repowdered.particles.register;
import repowdered.particles.loading;
import jsonizer;

private T getCachedComponent(T)(const SerializedParticleType type)
{
    import cereslib.optional;
    /// Don't use `T value` here and value == T.init. This fails at some reason with DeltaTemperature and some other components
    static Optional!T[const SerializedParticleType] type2Value;
    auto value = type in type2Value;

    if(value is null || !value.hasValue)
    {
        type2Value[type] = fromJSONString!T(type.components[T.stringof]);
    }

    return type2Value[type].value;
}

/// Build the air particle
/// Params:
///   entity = the entity to become air
pragma(inline, true)
public void buildAir(World world, Entity entity)
{
    buildParticle(world, entity, globalTypesDictionary[airTypeId]);
}

/// Build the border particle
/// Params:
///   entity = the entity to become air
pragma(inline, true)
public void buildBorder(World world, Entity entity)
{
    buildParticle(world, entity, globalTypesDictionary[borderTypeId]);
}

/// Build entity as a some particle type
/// Params:
///   entity = the entity
///   type = the particle's type
public void buildParticle(World world, Entity entity, in SerializedParticleType type)
{
    foreach(key, value; type.components)
    {
        LSwitch: switch(key)
        {
            static foreach (module_; defaultModules)
            {
                static foreach (Component; getComponentsInModule!(module_))
                {
                    case Component.stringof:
                    {            
                        auto pool = world.getPoolOf!Component;
                        pragma(msg, "MSG: registered a new component " ~ Component.stringof);

                        // TLDR: add component using parsed from json value
                        // Find raw json data in AA of type by getting `Component` (attribute) of `Component` 
                        // (type, that contains this attribute) and parse it
                        Component component = getCachedComponent!Component(type);
                        pool.addComponent(entity, component);
                    break LSwitch;
                    }
                }
            }
            default:
                throw new Exception("Not all components are foreached!");
        }
    }

    world.getPoolOf!UpdateRenderableMarker().addComponent(entity);

    bool isOTM_Marker = (OTM_Marker.stringof in type.components) !is null;
    if(!isOTM_Marker) world.getPoolOf!TypeName().addComponent(entity, TypeName(type.fullName));
}

/// Destroy all components of `entity`.
public void destroyParticle(World world, Entity entity)
{
    static foreach (module_; defaultModules)
    {
        static foreach (Component; getComponentsInModule!(module_))
        {
            {
                auto pool = world.getPoolOf!Component;
                pool.removeComponent(entity);
            }
        }
    }

    world.getPoolOf!UpdateRenderableMarker().addComponent(entity);
}