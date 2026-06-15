module cereslib.optional;

/// Type that tells that Result has `TError.init` value.
/// ------
/// Result!(T, U) result;
/// result = None();
/// ------
struct None
{
}

/// Get an `Optinal` initialized with `None`
/// ------
/// Optional!int opt = none!int;
/// ------
/// Returns: an `Optional` that doesn't has a value 
pragma(inline, true) 
public Optional!T none(T)()
{
    Optional!T result = None();
    return result;
}

/// Error type for Optional alias. Ommit it!
struct OptionalError
{    
}

alias Optional(TValue) = Result!(TValue, OptionalError);

struct Result(TValue, TError)
{
public:

    union 
    {
        TValue value;
        TError error;
    }

    bool hasValue;

    this(TValue value)
    {
        this.value = value;
        hasValue = true;
    }

    this(TError error)
    {
        this.error = error;
        hasValue = false;
    }

    this(None none)
    {
        this.error = TError.init;
        hasValue = false;
    }

    void opAssign(TValue value)
    {
        this.value = value;
        hasValue = true;
    }

    void opAssign(TError value)
    {
        error = value;
        hasValue = false;
    }

    void opAssign(None none)
    {
        error = TError.init;
        hasValue = false;
    }
}

unittest
{
    Result!(int, bool) res;
    res = 5;

    assert(res.hasValue);
    assert(res.value == 5);

    res = true;

    assert(!res.hasValue);
    assert(res.error == true);

    res = None();
    assert(!res.hasValue);
    assert(res.error == bool.init);
}

unittest
{
    Optional!int opt;
    opt = 128;

    assert(opt.hasValue);
    assert(opt.value == 128);

    opt = None();
    assert(!opt.hasValue);
}