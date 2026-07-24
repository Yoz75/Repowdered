module plutoecs.entity;

public alias EntityId = size_t;
public struct Entity
{
public:
    enum invalid = Entity(EntityId.max);
    EntityId id;
}