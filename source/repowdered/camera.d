module repowdered.camera;
import repowdered.sednapipeline;
import repowdered.settings;
import plutoecs;
import sednalib;

/// Init all systems and etcs in the camera module
public void initCamera(World world)
{
    CombinedInputAction zoomAllowedAction 
     = new CombinedInputAction(new MouseWheelAxisInputAction(),
     new KeyboardInputAction(KeyboardKey.leftControl), false, true);

    auto cameraSystem = new CameraSystem(zoomAllowedAction);
    world.addSystem!CameraSystem(cameraSystem);
}

/// Handles camera zoom and movement
private final class CameraSystem
{
    mixin SystemMembers;
    private const(CameraSettings*) settings;

    private KeyboardAxisInputAction horizontalMovementAction;
    private KeyboardAxisInputAction verticalMovementAction;
    private MouseWheelAxisInputAction zoomAction;
    private IInputAction zoomAllowedAction;

    private float targetZoom = 1.0f;

    private enum baseMovementSensitivity = 100.0;
    private enum baseZoomSensitivity = 0.1;
    private enum zoomSmoothness = 16.0f;
    private enum zoomFactor = 1.15f;
    
    public this(IInputAction zoomAllowedAction)
    {
        settings = &Settings.cameraSettings;

        horizontalMovementAction = new KeyboardAxisInputAction(KeyboardKey.a, KeyboardKey.d);
        verticalMovementAction = new KeyboardAxisInputAction(KeyboardKey.w, KeyboardKey.s);
        zoomAction = new MouseWheelAxisInputAction();
        this.zoomAllowedAction = zoomAllowedAction;
    }

    public void start()
    {
        SednalibPipeline.addRenderTask(&updateMovement);
    }

    private void updateMovement(Window window)
    {
        import std.algorithm.comparison : clamp;
        import std.math : pow;

        immutable frameTime = window.getFrameTime();
        immutable wheelDelta = zoomAction.getAxis();

        auto camera = &window.activeCamera;

        void updateCameraPosition()
        {
            camera.target.x +=
            horizontalMovementAction.getAxis()
            * settings.movementSensitivity
            * baseMovementSensitivity
            * frameTime;

            camera.target.y +=
            verticalMovementAction.getAxis()
            * settings.movementSensitivity
            * baseMovementSensitivity
            * frameTime;
        }   

        void updateZoom()
        {
            if(zoomAllowedAction.getState != InputActionState.unactive) return;

            if(wheelDelta > 0)
            {
                targetZoom *= pow(
                    zoomFactor,
                    wheelDelta * settings.zoomSensitivity
                );
            }
            else if(wheelDelta < 0)
            {
                targetZoom /= pow(
                    zoomFactor,
                    -wheelDelta * settings.zoomSensitivity
                );
            }

            targetZoom = clamp(targetZoom, settings.minZoom, settings.maxZoom);
            camera.zoom += (targetZoom - camera.zoom) * zoomSmoothness * frameTime;
        }     
         
        updateCameraPosition();

        immutable mouseWorldBefore = window.getMouseWorldPosition();
        updateZoom();
        immutable mouseWorldAfter = window.getMouseWorldPosition();

        float[2] difference = mouseWorldBefore[] - mouseWorldAfter[];
        const float[2] newTarget = (*camera).getTarget()[] + difference[];
        (*camera).setTarget(newTarget);
    }
}
