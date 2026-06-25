/// Thermal phenomena
module repowdered.particles.thermal;

import repowdered.map;
import repowdered.particles.register;
import repowdered.sednapipeline;
import repowdered.particles.rendering;
import plutoecs;
import sednalib;
import cereslib.jsonutils;

// Number type used for heat and temperature
alias TemperatureScalar = float;

public pure TemperatureScalar conductivity2coefficient(TemperatureScalar conductivity, 
    TemperatureScalar scale, TemperatureScalar maxConductivity)
{
    import std.math;

    return(log(1 + scale * conductivity)) / (log(scale * maxConductivity));
}

@scomponent public struct Temperature
{
    mixin MakeJsonizable;

public:
    enum TemperatureScalar min = -273.15;
    enum TemperatureScalar max = 100_000;

    enum TemperatureScalar maxCondictivity = 2200;
    enum TemperatureScalar minConductivity = 0;
    enum TemperatureScalar defaultConductivity = conductivity2coefficient(0.024, conductivityScale, maxCondictivity);

    /// Scale of conductivity normalisation
    enum conductivityScale = 250;

    enum TemperatureScalar airHeatCapacity = 1005;
    enum TemperatureScalar defaultTemperature = 25;

    /// The heat capacity. 
    /// Indicates how much a substance will "pull the resulting temperature onto itself" during heat exchange
    TemperatureScalar heatCapacity = airHeatCapacity;

    /// How fast particle changes it's temperature.
    TemperatureScalar transferCoefficient = defaultConductivity;

    /// Temperature of a particle in degrees Celsius
    TemperatureScalar value = defaultTemperature; 

    @JsonizeField this(TemperatureScalar value, TemperatureScalar heatCapacity, 
    TemperatureScalar thermalConductivity = defaultConductivity)
    {
        import std.math;
        this.value = value;
        this.heatCapacity = heatCapacity;

        // Logarithmic compression because we want both water (0.603) and diamonds (2200) would had
        // at least a little similar transfer coefficients
        transferCoefficient = (log(1 + conductivityScale * thermalConductivity)) / 
         (log(conductivityScale * maxCondictivity));
    }
}

/// A Kostyl, that's needed to increase or decrease temperature
public @scomponent struct DeltaTemperature
{
    mixin MakeJsonizable;
public:
    @JsonizeField TemperatureScalar delta;
    @JsonizeField TemperatureScalar boostMultiplier = 1;
}

/// Something that turns into something other when temperature more than critical point
public @scomponent struct Meltable
{
    mixin MakeJsonizable;
public:
    @JsonizeField string resultId;
    @JsonizeField TemperatureScalar criticalTemperature;
}

/// Something that turns into something other when temperature less than critical point
public @scomponent struct Solidable
{
    mixin MakeJsonizable;
public:
    @JsonizeField string resultId;
    @JsonizeField TemperatureScalar criticalTemperature;
}

public @scomponent struct Convection
{
    mixin MakeJsonizable;
public:
}

alias TemperatureChangedAction = void delegate(Entity entity);
/// The system that updates temperatures of all cells
public final class TemperatureSystem
{
    mixin SystemMembers;
    private TemperatureChangedAction[] onTemperatureChanged;

    private ComputeShader temperatureShader;
    private ShaderBuffer!Temperature valueInSSBO, valueOutSSBO;

    private shared Temperature[] valueInBuffer;
    private shared Temperature[] valueOutBuffer;

    private ComponentPool!UpdateRenderableMarker markers;
    private ComponentPool!Position positions;
    private ComponentPool!Temperature temperatures;

    private Map map;

    public this(Map map)
    {
        this.map = map;
        temperatureShader = new ComputeShader();
    }

    public void addOnTemperatureChanged(TemperatureChangedAction action)
    {
        onTemperatureChanged ~= action;
    }

    public void start()
    {
        markers = myWorld.getPoolOf!UpdateRenderableMarker;
        positions = myWorld.getPoolOf!Position;
        temperatures = myWorld.getPoolOf!Temperature;

        temperatureShader = new ComputeShader();
        SednalibPipeline.addOnceRenderTask(&initGPUStuff);
    }

    /// Manually read the Temperature component of the `entity` and update entity's temperature
    /// Params:
    ///   entity = the entity 
    public void updateTemperatureOf(Entity entity)
    {
        immutable auto mapPos = positions.getComponent(entity).xy;
        Temperature[1] resultBuffer;
        resultBuffer[0] = temperatures.getComponent(entity);

        void updateSSBO(Window window)
        {
            immutable uint index = cast(uint)(mapPos[0] + map.resolution[0] * mapPos[1]);
            valueInSSBO.update(resultBuffer, index);
        }

        SednalibPipeline.addOnceRenderTask(&updateSSBO);

        foreach(action; onTemperatureChanged)
        {
            action(entity);
        }
    }

    public void destroyed()
    {
        SednalibPipeline.addOnceRenderTask((window) 
        {
            valueInSSBO.free();
            valueOutSSBO.free();
            temperatureShader.free();
        });
    }

    private void onAdd(Entity entity)
    {
        updateTemperatureOf(entity);
        foreach(action; onTemperatureChanged)
        {
            action(entity);
        }
    }

    public  void update()
    {
        /*if(globalGameState != GameState.play)
        {
            foreach(entity; globalMap)
            {
                foreach(action; onTemperatureChanged)
                {
                    action(entity);
                }
            }

            return;
        }*/

        import std.math;
        import std.algorithm.comparison : clamp;
        import std.traits : EnumMembers;

        SednalibPipeline.addOnceRenderTask(&executeShader);

        auto data = temperatures.getComponents();
        foreach(i, temperature; data)
        {
            Entity entity = temperatures.dense2Entity(i);
            auto position = positions.getComponent(entity);

            immutable bufferIndex = position.x + map.resolution[0] * position.y;
            valueOutBuffer[bufferIndex].value =
            clamp(valueOutBuffer[bufferIndex].value, Temperature.min, Temperature.max);

            temperature = valueOutBuffer[bufferIndex];
            foreach(action; onTemperatureChanged)
            {
                action(entity);
            }
        }
    }

    private void executeShader(Window window)
    {
        temperatureShader.execute([map.resolution[0] / Map.chunkSize, map.resolution[1] / Map.chunkSize, 1]);

        synchronized(this)
        {
            valueOutSSBO.read(cast(Temperature[]) valueOutBuffer);
            auto temp = valueInSSBO;
            valueInSSBO = valueOutSSBO;
            valueOutSSBO = temp;
        }        

        temperatureShader.detachBuffer(1);
        temperatureShader.detachBuffer(2);

        temperatureShader.attachBuffer(valueInSSBO.internalId, 1);
        temperatureShader.attachBuffer(valueOutSSBO.internalId, 2);
    }

    /// Init all stuff allocated on GPU
    private void initGPUStuff(Window window)
    {
        synchronized(this)
        {
            valueInSSBO = new ShaderBuffer!Temperature();
            valueOutSSBO = new ShaderBuffer!Temperature();

            immutable bufferLength = map.resolution[0] * map.resolution[1];
            valueInBuffer = new shared Temperature[bufferLength];
            valueInBuffer[] = Temperature.init; // bruh at some reasone default values in the array are not Temperature.init

            valueOutBuffer = new shared Temperature[bufferLength];
            
            // this is a synchronized section, we can safely cast shared to unshared
            valueInSSBO.initMe(bufferLength, cast(Temperature[]) valueInBuffer, BufferUsageHint.StreamCPU2GPU);
            valueOutSSBO.initMe(bufferLength, null, BufferUsageHint.StreamGPU2CPU);

            temperatureShader.attachBuffer(valueInSSBO.internalId, 1);
            temperatureShader.attachBuffer(valueOutSSBO.internalId, 2);
        }
    }
}

private final class DeltaTemperatureSystem
{
    mixin SystemMembers;
    private ComponentPool!DeltaTemperature deltaTemperatures;
    private ComponentPool!Temperature temperatures;

    private IInputAction boostDeltaAction;
    private TemperatureSystem temperatureSystem;

    public this(IInputAction boostDeltaAction, TemperatureSystem temperatureSystem)
    {
        this.boostDeltaAction = boostDeltaAction;
    }

    public void start()
    {
        deltaTemperatures = myWorld.getPoolOf!DeltaTemperature;
        deltaTemperatures.addOnAddAction(&onAdd);
        
        temperatures = myWorld.getPoolOf!Temperature;
    }

    private void onAdd(Entity entity)
    {
        immutable deltaTime = GameLoop.getTickTime();
        ref DeltaTemperature delta = deltaTemperatures.getComponent(entity);
        ref Temperature temperature = temperatures.getComponent(entity);

        auto resultDelta = boostDeltaAction.isActive() ? delta.delta * delta.boostMultiplier : delta.delta;

        temperature.value += resultDelta * deltaTime;
        temperatureSystem.updateTemperatureOf(entity);

        deltaTemperatures.removeComponent(entity);
    }
}

public class MeltableSystem
{
    mixin SystemMembers;

    import repowdered.particles.building;
    import repowdered.particles.register;
    import repowdered.particles.loading;

    private ComponentPool!Meltable meltables;
    private ComponentPool!Temperature temperatures;

    public void start()
    {
        meltables = myWorld.getPoolOf!Meltable;
        temperatures = myWorld.getPoolOf!Temperature;
    }

    public void update()
    {
        auto data = meltables.getComponents();

        foreach(i, meltable; data)
        {
            Entity entity = meltables.dense2Entity(i);
            Temperature temperature = temperatures.getComponent(entity);

            if(temperature.value > meltable.criticalTemperature)
            {
                auto serializedResult = globalTypesDictionary[meltable.resultId];
                destroyParticle(myWorld, entity);
                buildParticle(myWorld, entity, serializedResult);
                temperatures.addComponent(entity, temperature);
            }
        }
    }
}

public class SolidableSystem
{
    mixin SystemMembers;

    import repowdered.particles.building;
    import repowdered.particles.register;
    import repowdered.particles.loading;

    private ComponentPool!Solidable solidables;
    private ComponentPool!Temperature temperatures;

    public void start()
    {
        solidables = myWorld.getPoolOf!Solidable;
        temperatures = myWorld.getPoolOf!Temperature;
    }

    public void update()
    {
        auto data = solidables.getComponents();

        foreach(i, meltable; data)
        {
            Entity entity = solidables.dense2Entity(i);
            Temperature temperature = temperatures.getComponent(entity);

            if(temperature.value > meltable.criticalTemperature)
            {
                auto serializedResult = globalTypesDictionary[meltable.resultId];
                destroyParticle(myWorld, entity);
                buildParticle(myWorld, entity, serializedResult);
                temperatures.addComponent(entity, temperature);
            }
        }
    }
}

public class ConvectionSystem
{        
    import repowdered.particles.meta;
    import repowdered.particles.mechanics;
    mixin SystemMembers;

    public ComponentPool!Convection convectionsPool;
    private ComponentPool!Position positionsPool;
    private ComponentPool!Temperature temperaturesPool;
    private ComponentPool!TypeName particlesPool;
    private ComponentPool!UpdateRenderableMarker markersPool;

    private TemperatureSystem temperatureSystem;
    private Map map;

    private ubyte rawMoveOffset;
    
    public this(TemperatureSystem temperatureSystem, Map map)
    {
        this.temperatureSystem = temperatureSystem;
        this.map = map;
    }

    public void start()
    {
        convectionsPool = myWorld.getPoolOf!Convection;
        positionsPool = myWorld.getPoolOf!Position;
        temperaturesPool = myWorld.getPoolOf!Temperature;
        particlesPool = myWorld.getPoolOf!TypeName;
        markersPool = myWorld.getPoolOf!UpdateRenderableMarker;
    }

    immutable static PositionScalar[2][GravityDirection.max + 1] gravity2convection = 
    [
        GravityDirection.down: [0, -1],
        GravityDirection.up: [0, 1],
        GravityDirection.left: [-1, 0],
        GravityDirection.right: [1, 0],
        GravityDirection.none: [0, 0]
    ];

    public void update()
    {
        if(GameLoop.timeScale <= 0) return;
        if(GravityMarker.gravity.direction == GravityDirection.none) return;

        forEach!convectionsPool(&updateComponent);
        rawMoveOffset++;
    }

    private void updateComponent(size_t denseId, ref Convection convection)
    {
        Entity entity = convectionsPool.dense2Entity(denseId);
        immutable Position position = positionsPool.getComponent(entity);

        immutable PositionScalar[2] gravityDirection = gravity2convection[GravityMarker.gravity.direction];

        // `-1` part converts ofsset from [0..2] to [-1.1]
        immutable int moveOffset = (rawMoveOffset % 3) - 1;
        immutable PositionScalar[2] gravityPerpendicular = [gravityDirection[1], -gravityDirection[0]].toPS;

        immutable PositionScalar[2] rawUpperPos 
         = position.xy[] + gravityDirection[] + gravityPerpendicular[] * moveOffset;

        immutable Position upperPos = Position(rawUpperPos[0], rawUpperPos[1]);
        
        immutable upperEntity = map.tryGetAt(upperPos);
        if(!upperEntity.hasValue) return;
        if(!convectionsPool.hasComponent(upperEntity.value)) return;

        immutable areSameType = particlesPool.getComponent(entity) == particlesPool.getComponent(upperEntity.value);
        
        immutable Temperature selfTemperature = temperaturesPool.getComponent(entity);
        immutable Temperature upperTemperature = temperaturesPool.getComponent(upperEntity.value);

        immutable bool isThermalConvectionSuitable = 
            selfTemperature.value > upperTemperature.value && areSameType;

        if(isThermalConvectionSuitable)
        {
            map.swap(entity, upperEntity.value);
        }
        else return;

        temperatureSystem.updateTemperatureOf(entity);
        temperatureSystem.updateTemperatureOf(upperEntity.value);

        markersPool.addComponent(entity);
        markersPool.addComponent(upperEntity.value);
    }
}