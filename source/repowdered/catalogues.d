module repowdered.catalogues;
import std.file;

version(Windows)
{
    enum char pathSeparator = '\\';
}
else
{
    enum char pathSeparator = '/';
}

string combinePath(T...)(T path)
{
    import std.array;
    import std.traits;
    auto sb = appender!string;

    static foreach(part; path)
    {
        static if(hasMember!(typeof(part), "toString"))
        {
            sb.put(part.toString());
        }
        else
        {
            sb.put(part);
        }
    }

    return sb[];
}

/// Get path of app's data (it can be any directory, not only C:\Users\user\AppData)
/// Returns: the path
string getAppDataPath()
{
    auto cwd = getcwd();

    return cwd ~ pathSeparator; 
}   

/// Get path of the particles directory
/// Returns: the path
string getParticlesPath()
{
    enum particlesFolderName = "particles";

    immutable string path = getAppDataPath ~ particlesFolderName ~ pathSeparator;

    if(!exists(path))
    {
        mkdirRecurse(path);
    }

    return path;
}

/// Get path of the settings directory
/// Returns: the path
string getSettingsPath()
{
    enum settingsFolderName = "settings";

    immutable string path = getAppDataPath ~ settingsFolderName ~ pathSeparator;

    if(!exists(path))
    {
        mkdirRecurse(path);
    }

    return path;
}