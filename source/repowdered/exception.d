module repowdered.exception;

/// Exception throwed when an argument is a wrong value
class ArgumentException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__,
     Throwable nextInChain = null) pure nothrow @nogc @safe
    {
        super(msg, file, line, nextInChain);
    }
}