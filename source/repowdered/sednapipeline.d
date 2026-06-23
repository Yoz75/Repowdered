module repowdered.sednapipeline;
import repowdered.catalogues;
import repowdered.settings;
import sednalib;
import cereslib.jsonutils;
import cereslib.versions;
import std.traits : isImplicitlyConvertible;
import std.concurrency;
import dlib.container;

/// A delegate that should be called from sedna thread
alias SednaTask = void delegate(Window);

/// Class that initializes Sedna thread. All interactions with game window or rendering should be passed through sedna tasks.
/// Input actions can be used without sedna tasks.
public abstract final class SednalibPipeline
{
public:
static:
    private __gshared Window window;
    private __gshared Tid renderThreadId;
    private __gshared Array!SednaTask tasks;
    private __gshared Array!SednaTask uiTasks;
    private __gshared Queue!SednaTask onceTasks;
    private __gshared Queue!SednaTask onceUITasks;
    private __gshared bool isWindowClosed;
    private __gshared bool isWindowInitialized;
    private __gshared Object pipelineMonitor = new Object;

    ~this()
    {
        tasks.free();
        uiTasks.free();
        onceTasks.free();
        onceUITasks.free();
    }

    /// Init the Sedna pipeline and create window.
    void initialize()
    {
        immutable settings = Settings.windowSettings;

        spawn(&renderThread, settings);

        while(true)
        {
            bool initialized;
            synchronized(pipelineMonitor)
            {
                initialized = isWindowInitialized;
            }
            if(initialized)
                break;
        }

        addOnceRenderTask((window) => window.setMaxFPS(settings.maxFPS));
    }

    /// Add a permanent sedna task
    /// Params:
    ///   task = the task
    void addRenderTask(SednaTask task)
    {
        synchronized(pipelineMonitor)
        {
            tasks.insertBack(task);
        }
    }

    /// Add a permanent sedna task that should be called at UI stage (remember that UI renders automatically, use this for mutability etc)
    /// Params:
    ///   uiTask = the task
    void addUITask(SednaTask uiTask)
    {
        synchronized(pipelineMonitor)
        {
            uiTasks.insertBack(uiTask);
        }
    }

    /// Add a task that should be called once. They are called before permanent tasks
    /// Params:
    ///   task = the task
    void addOnceRenderTask(SednaTask task)
    {
        synchronized(pipelineMonitor)
        {
            onceTasks.enqueue(task);
        }
    }

    /// Add a UI task that should be called once. They are called before permanent UI tasks
    /// Params:
    ///   uiTask = the task
    void addOnceUITask(SednaTask uiTask)
    {
        synchronized(pipelineMonitor)
        {
            onceUITasks.enqueue(uiTask);
        }
    }

    /// Is pipeline ended its work?
    bool isPipelineStopped()
    {
        bool closed;
        synchronized(pipelineMonitor)
        {
            closed = isWindowClosed;
        }
        return closed;
    }

    private void renderThread(WindowSettigns settings)
    {
        try
        {        
            window = Window.create([settings.xResolution, settings.yResolution], settings.isFullscreen,
            settings.title ~ ' ' ~ programVersion.toString() ~ "\0");

            window.setBackgroundColor(settings.backgroundColor);
            auto rootTheme = Theme(rule!Frame(Rule.backgroundColor = color("#00000000")));
            window.uiRoot = vframe(.layout!("fill"));
            window.uiRoot.theme = rootTheme;

            synchronized(pipelineMonitor)
            {
                isWindowInitialized = true;
            }

            while(!window.shouldClose)
            {
                window.startFrame();
                window.clearScreen();

                while(true)
                {
                    SednaTask head;
                    synchronized(pipelineMonitor)
                    {
                        if(onceTasks.empty)
                        {
                            head = null;
                        }
                        else
                        {
                            head = onceTasks.dequeue();
                        }
                    }

                    if(head is null)
                        break;

                    head(window);
                }

                synchronized(pipelineMonitor)
                {
                    foreach(task; tasks)
                    {
                        task(window);
                    }
                }

                while(true)
                {
                    SednaTask head;
                    synchronized(pipelineMonitor)
                    {
                        if(onceUITasks.empty)
                        {
                            head = null;
                        }
                        else
                        {
                            head = onceUITasks.dequeue();
                        }
                    }

                    if(head is null)
                        break;

                    head(window);
                }

                synchronized(pipelineMonitor)
                {
                    foreach(task; uiTasks)
                    {
                        task(window);
                    }
                }

                window.uiRoot.draw();
                window.endFrame();
            }

            window.close();
            synchronized(pipelineMonitor)
            {
                isWindowClosed = true;
            }
        }
        catch(Throwable ex) // "Catching Error or Throwable is almost always a bad idea."... Bro I literally kill my program instantly after this happens
        {
            import cereslib.debugtools;

            logFatalAndDie(ex);
        }
    }
}