module cereslib.debugtools;
import colorize;

/// Logs message of `ex` and kills program
/// Params:
///   ex = the throwable that should be logged
/// Returns: bro it doesn't returns it kills program
noreturn logFatalAndDie(Throwable ex)
{
	cwriteln("Unhandled error or exception: ".color(fg.red), ex.msg.color(fg.red));
	cwriteln("Stack trace:\n".color(fg.red));

	foreach(i, info; ex.info)
	{
		string strInfo = cast(string) info[0..$];
		
		if(i % 2 == 0)
		{
			cwriteln(strInfo.color(fg.red));
		}
		else
		{
			cwriteln(strInfo.color(fg.yellow));
		}
	}

    import core.stdc.stdlib;
    // 228 is logFatalAndDie exit code
    exit(228);
}