/// The module, in witch we detect and register types as components 
///(literally say "hey, this type has Component attribute, that's a component!")
module repowdered.particles.register;

import repowdered.particles;
import repowdered.particles;
import std.meta;
import std.traits;

/// A useless thing, we need it only to emulate hash set in `globalComponents`
struct Dummy
{

}
/// All found components
public __gshared Dummy[string] globalComponents;

/// Default modules, that contain components
public alias defaultModules = AliasSeq!(repowdered.particles.rendering.components, repowdered.particles.meta,
 repowdered.particles.mechanics);

/// Serializable component. This attribute marks component as serializable (i.e user can add it to a custom type, added or deleted by `buildParticle` and `destroyParticle`)
/// Components, that should not be serializable (e.g position component) must avoid this attribute!
public struct scomponent // this should be camelCase, see https://dlang.org/dstyle.html#naming_udas
{
}

/// Get all component structs in a module `name` as AliasSeq(Components...).
/// This template returns types, that contain `Component` attribute, but `Component` itself
public template getComponentsInModule(alias name)
{
    alias getComponentsInModule = getSymbolsByUDA!(name, scomponent);
}

/// Get the component attribute, attached to type `T`. 
/// This template assumes, that `T` has Component attribute
public template getComponentAttributeOf(T)
{
    enum Component getComponentAttributeOf = getUDAs!(T, scomponent)[0];
}

/// Register all components in a module
public void registerModule(alias name)()
{
    static foreach (i, attributed; getComponentsInModule!(name))
    {    
        globalComponents[attributed.stringof] = Dummy();
    }
}

/// Register all components in `defaultModules`
public void registerDefaultModules()
{
    static foreach(module_; defaultModules)
    {
        registerModule!(module_)();
    }
}