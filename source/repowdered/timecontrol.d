module repowdered.timecontrol;

import repowdered.sednapipeline;
import sednalib;
import plutoecs;

public void initTimeControl(World world)
{
    auto pauseAction = new KeyboardInputAction(KeyboardKey.space);
    auto passFrameAction = new KeyboardInputAction(KeyboardKey.f);
    auto timeSystem = new TimeControlSystem(pauseAction, passFrameAction);

    world.addSystem!TimeControlSystem(timeSystem);
}

private final class TimeControlSystem
{
    mixin SystemMembers;

    /// Should we process 1 frame of the game or not?
    private bool shouldPassFrame;
    private IInputAction pauseAction, passFrameAction;

    public this(IInputAction pauseAction, IInputAction passFrameAction)
        {
        this.pauseAction = pauseAction;
        this.passFrameAction = passFrameAction;
    }

    public void update()
    {
        if(shouldPassFrame && GameLoop.timeScale > 0)
        {
            GameLoop.timeScale = 0;
        }

        if(pauseAction.getState() == InputActionState.began)
        {
            immutable timeScale = GameLoop.timeScale;
            GameLoop.timeScale = timeScale != 0 ? 0 : 1;
            shouldPassFrame = false;
        }

        if(passFrameAction.getState() == InputActionState.began)
        {
            shouldPassFrame = true;
            GameLoop.timeScale = 1;
        }
    }
}
