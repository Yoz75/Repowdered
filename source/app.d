import std.stdio;
import repowdered.entry;
import cereslib.debugtools;

void main()
{
    try
    {
        startGame();
    }
    catch(Throwable ex)
    {
        logFatalAndDie(ex);
    }
}
