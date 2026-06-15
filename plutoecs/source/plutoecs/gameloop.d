module plutoecs.gameloop;
import plutoecs.world;
import std.datetime.stopwatch;

/// The class that needed to start and update the game.
public final abstract class GameLoop
{
public:
static:

    /// The time speed multiplier.
    shared float timeScale = 1;
    private World currentWorld_;

    private bool shouldStop = false;
    private double lastTickTime = 1;
    private double minTickTime = 1.0 / 60.0;

    /// Current updating world of the simulation
    @property World currentWorld()
    {
        return currentWorld_;
    }

    /// Run the simulation.
    void run(World world)
    {
        currentWorld_ = world;
        StopWatch sw = StopWatch(AutoStart.no);
        
        while(!shouldStop)
        {
            sw.start();
            currentWorld.update();
            
            lastTickTime = cast(double) sw.peek().total!"usecs"() / 1_000_000.0;

            immutable auto waitTime = minTickTime - lastTickTime;
            if(waitTime > 0)
            {
                import core.thread.osthread;
                long integerWaitTime = cast(long)(waitTime * 1_000_000.0);
                Thread.sleep(usecs(integerWaitTime));
            }

            sw.stop();
            lastTickTime = cast(double) sw.peek().total!"usecs"() / 1_000_000.0;
            sw.reset();
        }

        currentWorld.destroy();
    }

    /// Change current world to `world`
    void changeWorld(World world)
    {
        currentWorld.destroy();
        currentWorld_ = world;
    }

    void stop()
    {
        shouldStop = true;
    }

    /// Get time of a single tick in seconds
    double getTickTime()
    {
        return lastTickTime;
    }

    /// Get TPS of simulation
    double getTPS()
    {
        return 1 / lastTickTime;
    }

    void setMaxTPS(double tps)
    {
        minTickTime = 1 / tps;
    }
}