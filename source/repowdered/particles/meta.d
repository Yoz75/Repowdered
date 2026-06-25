module repowdered.particles.meta;

import repowdered.particles.register : scomponent;
import cereslib.jsonutils;


/// The name of particle type
public struct TypeName // Remember: components without @Component attribute don't delete when particle is removed, we add the once!
{
    mixin MakeJsonizable;
public:
    /// The name of the particle type. For example, Repowdered.FLuids.Water
    string name;

    bool opEquals(const TypeName other) const
    {
        return name == other.name;
    }

    size_t toHash() const @nogc @safe pure nothrow
    {
        return name.hashOf;
    }
}

/// Marks that current entity is a hollow particle. Add this component to make it act as air
@scomponent public struct HollowMarker
{
    mixin MakeJsonizable;
}

/// Marks that this particle is a One Time Modifier, it only applies some modifiers to an existing particle and doesn't replace it.
@scomponent public struct OTM_Marker
{
    mixin MakeJsonizable;
}