/// The module, in witch we load types from settings
module repowdered.particles.loading;

import cereslib.jsonutils;
import repowdered.catalogues;
import repowdered.particles.register;
import std.file;

/// The id of the Air component
public enum airTypeId = "Repowdered.Special.Air";
public enum borderTypeId = "Repowdered.Special.Border";

/// Loaded types, but as dictionary
public __gshared SerializedParticleType[string] globalTypesDictionary;

/// All loaded categories
public __gshared Category[] globalLoadedCategories;

/// All loaded modules
public __gshared Module[] globalLoadedModules;

/// Exception, that occurs, when the game couldn't associate directory's name with any component name
public class WrongComponentLoadException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) 
    pure nothrow @nogc @safe
    {
        super(msg, file, line, nextInChain);
    }
}

/// Type, that contains ID of particle's type and its components. This is needed for loading types from settings
public struct SerializedParticleType
{
public:
    /// The name of particle's module (The "X" in X.Y.Z)
    string moduleName;

    /// The name of particle's category (The "Y" in X.Y.Z)
    string categoryName;

    /// The name of particle's type (The "Z" in X.Y.Z)
    string typeName;

    ///Authors: The full name of type. That's the X.Y.Z
    string fullName;

    // The dictionary of raw .json values of components by their names
    string[string] components;
}

/// A module that contains categories that contain particles. E.g Repowdered
public struct Module
{
    string name;
    Category[] categories;
}

/// A Category that contains types. E.g Repowdered.Fluids
public struct Category
{
    string name;
    SerializedParticleType[] types;
}

/// Try to find and load a module that contains categories that contain types
public void findAndLoadModules()
{
    immutable string particlesDirectory = getParticlesPath() ~ pathSeparator;

    foreach(moduleEntry; dirEntries(particlesDirectory, SpanMode.shallow))
    {
        if(!moduleEntry.isDir) continue;

        Module module_;
        module_.name = moduleEntry.name.extractDirName();

        module_.categories = processCategories(moduleEntry.name, module_.name);
        globalLoadedModules ~= module_;
    }
}

private:

Category[] processCategories(string modulePath, string moduleName)
{
    Category[] categories;

    foreach(categoryEntry; dirEntries(modulePath, SpanMode.shallow))
    {
        if(!categoryEntry.isDir) continue;

        Category category;
        category.name = categoryEntry.name.extractDirName();
        category.types = processTypes(categoryEntry.name, moduleName, category.name);

        categories ~= category;
    }

    assert(categories.length > 0, "at some reason we couldn't process categories (maybe there's no categories?!)");

    return categories;
}

SerializedParticleType[] processTypes(string path, string moduleName, string categoryName)
{
    SerializedParticleType[] types;

    foreach (typeEntry; dirEntries(path, SpanMode.shallow))
    {
        /// typeEntry is a directory inside particles directory, every directory inside this is recognized as a type direcotry
        if(!typeEntry.isDir()) continue;
        
        SerializedParticleType type;

        type.typeName = typeEntry.name.extractDirName();
        type.moduleName = moduleName;
        type.categoryName = categoryName;
        type.fullName = type.moduleName ~ "." ~ type.categoryName ~ "." ~ type.typeName;

        type.components = processComponents(typeEntry);
        globalTypesDictionary[type.fullName] = type;
        types ~= type;
    }

    assert(types.length > 0, "at some reasone we couldn't process types! Maybe there's no types in a directory???");

    return types;
}

/// Process components of a type and get them
/// Params:
///   path = path to the type
/// Returns: associative array, where key is name of component and value is serialized component
string[string] processComponents(string path)
{
    string[string] components;

    foreach(componentEntry; dirEntries(path, SpanMode.shallow))
    {
        if(!componentEntry.isFile()) continue;

        // Get the name of component's json file from full path
        string componentName = extractFileName(componentEntry.name);

        const auto component = componentName in globalComponents;
        if(component is null)
        {
            throw new WrongComponentLoadException("Component " ~ componentName ~ " does not exists!");
        }

        // A huge kostyl lol (not only this code, but the whole concept)
        components[componentName] = readText(componentEntry.name);    
    }

    assert(components.length > 0, "at some reason we couldn't load components! Maybe there's no attached components to a type?");

    return components;
}

/// Extract file's name without extension from file's path
pure string extractFileName(string path)
{
    import std.array; 
    return path.split(pathSeparator)[$-1].split('.')[0];
}

/// Extract directory's name from it's path
pure string extractDirName(string path)
{
    import std.array;
    return path.split(pathSeparator)[$-1];
}

public SerializedParticleType getAirType()
{
    auto airType = airTypeId in globalTypesDictionary;
    assert(airType !is null, "At some reason getAirType() called before air component registered!");
    return globalTypesDictionary[airTypeId];
}

public SerializedParticleType getBorderType()
{
    auto borderType = borderTypeId in globalTypesDictionary;
    assert(borderType !is null, "At some reason getBorderType() called before border component registered!");
    return globalTypesDictionary[airTypeId];
}