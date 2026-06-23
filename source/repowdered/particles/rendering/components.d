module repowdered.particles.rendering.components;

import repowdered.particles.register;
import plutoecs;
import cereslib.jsonutils;
import sednalib : Color32;

/// Something that can be rendered on the map as a pixel
@scomponent public struct MapRenderable
{
    mixin MakeJsonizable;
public:
    @JsonizeField Color32 color = Color32(55, 55, 55);
}

/// A marker component that tells map renderable system to update the pixel of entity
public struct UpdateRenderableMarker
{

}