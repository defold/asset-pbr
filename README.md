# defold-pbr

Base PBR material:

- `/defold-pbr/pbr.material`
- `/defold-pbr/shaders/pbr.vp`
- `/defold-pbr/shaders/pbr.fp`

The shader uses Defold model PBR constants from the `PbrMaterial` uniform block and binds glTF textures by the sampler names populated by the model component. This first pass supports metallic-roughness base color data, normal/occlusion/emissive textures, alpha cutoff/unlit flags, and directional/point/spot lights from Defold's light component buffer. Image based lighting and the additional glTF material extensions are intentionally left out for now.
