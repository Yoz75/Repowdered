module repowdered.particles.creating.shapes;

import repowdered.particles.loading;
import repowdered.particles.building;
import repowdered.particles.rendering;
import repowdered.sednapipeline;
import repowdered.map;
import sednalib;
import plutoecs;

public interface IShape
{
    /// Set the size of the shape
    public void setScale(in int scale);

    /// Get the scale of the shape
    /// Returns: scale of the shape
    public int getScale();
    
    /// Place shape at `position` and fill all it's cells with `type`
    public void fillAtPosition(in int[2] position, in SerializedParticleType type);

    /// Delete all particles situated under shape placed at `position`
    public void deleteAtPos(in int[2] position);

    /// Mark borders of the shape at `position`
    public void markBorders(in int[2] position);
}

package final class Rectangle : IShape
{
    private int scale = 5;

    /// Contains the sprite to be rendered
    private Sprite shapeSprite;
    private enum Color32 shapeColor = Color32(180, 180, 180);

    private World world;
    private Map map;
    private MapRenderSystem mapRenderSystem;

    public this(World world, Map map, MapRenderSystem mapRenderSystem)
    {
        setScale(scale);
        this.world = world;
        this.map = map;
        this.mapRenderSystem = mapRenderSystem;

        SednalibPipeline.addRenderTask((window) {shapeSprite.draw();});
    }

    /// Set the size of the shape
    public void setScale(in int scale)
    {
        this.scale = scale;
        
        SednalibPipeline.addOnceRenderTask((window) 
        {
            shapeSprite.free();
             shapeSprite = Sprite([scale, scale], shapeColor);
        });
    }

    
    /// Get the scale of the shape
    /// Returns: scale of the shape
    public int getScale()
    {
        return scale;
    }
    
    /// Place shape at `position` and fill all it's cells with `type`
    public void fillAtPosition(in int[2] position, in SerializedParticleType type)
    {
        int[2] leftCorner;
        leftCorner[] = position[] - (scale / 2);
        
        for(int y = leftCorner[1]; y < leftCorner[1] + scale; y++)
        {
            for(int x = leftCorner[0]; x < leftCorner[0] + scale; x++)
            {
                immutable pos = Position(cast(PositionScalar) x, cast(PositionScalar) y);
                if(pos.x < 0 || pos.y < 0 || pos.x >= map.resolution[0] || pos.y >= map.resolution[1]) continue;

                Entity entity = map.getAt(pos);
                buildParticle(world, entity, type);
            }
        }
    }

    /// Delete all particles situated under shape placed at `position`
    public void deleteAtPos(in int[2] position)
    {
        int[2] leftCorner;
        leftCorner[] = position[] - (scale / 2);
        
        for(int y = leftCorner[1]; y < leftCorner[1] + scale; y++)
        {
            for(int x = leftCorner[0]; x < leftCorner[0] + scale; x++)
            {
                immutable pos = Position(cast(PositionScalar) x, cast(PositionScalar) y);
                if(pos.x < 0 || pos.y < 0 || pos.x >= map.resolution[0] || pos.y >= map.resolution[1]) continue;
                
                Entity entity = map.getAt(pos);
                destroyParticle(world, entity);
            }
        }
    }

    /// Mark borders of the shape at `position`
    public void markBorders(in int[2] position)
    {
        import std.math : round;
        shapeSprite.position = sprite2WorldPosition(mapRenderSystem.getMapSprite(), position);
        immutable int[2] halfSize =[shapeSprite.width, shapeSprite.height] / 2;
        shapeSprite.position[0] -= round(halfSize[0]);
        shapeSprite.position[1] -= round(halfSize[1]);
    }
}