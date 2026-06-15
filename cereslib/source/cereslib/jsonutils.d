module cereslib.jsonutils;

import jsonizer;
import cereslib.optional;
import std.file;

/// Error code if reading json file
public enum JSONErrorCode
{
    None = 0,
    FileNotFound,
    ParseError,
}

/// alias stuff to abstract jsonizer from user
alias JsonizeField = jsonize;

///ditto
public mixin template MakeJsonizable()
{
    public import jsonizer;
    mixin JsonizeMe;
}

/// Load an instance of `T` from file
/// Params:
///   path = path to file
/// Returns: an instance of T or error code if something went wrong
public Result!(T, JSONErrorCode) loadFromFile(T)(const string path)
{
    if(!exists(path)) return Result!(T, JSONErrorCode)(JSONErrorCode.FileNotFound);

    T result;
    try
    {
        result = readJSON!T(path);
        return Result!(T, JSONErrorCode)(result);
    }
    catch(JsonizeTypeException ex)
    {
        return Result!(T, JSONErrorCode)(JSONErrorCode.ParseError);    
    }
    
}

/// Save data to a json file
/// Params:
///   path = the path to the file
///   value = the data that should be serialized
public void saveToFile(T)(const string path, const T value)
{
    writeJSON!T(path, value);
}

/// Load data from settings file or leave it default if couldn't
/// Params:
///   path = full path to the data
///   data = the data
void loadOrSave(T)(string path, ref T data)
{
    auto dataResult = loadFromFile!T(path); 
    if(!dataResult.hasValue)
    {
        saveToFile(path, data);
    }
    else
    {
        data = dataResult.value;
    }
}