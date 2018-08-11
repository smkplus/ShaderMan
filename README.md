ShaderMan

ShaderToy to ShaderLab Converter

If you’ve tried dabbling with shaders at all, you’ve probably come across ShaderToy – an online shader showcase with some pretty amazing examples of what’s possible in a few lines of shader code, inspired greatly by classic demoscene coding. Here’s just two examples: https://www.shadertoy.com/view/4dl3zn

It’s an amazing resource, not only for inspiration but for learning how to create shaders, since every example comes with full source code which you can edit and immediately test online in your browser, alter parameters, supply different inputs etc.

The shaders exhibited on ShaderToy are exclusively written in GLSL, and run in your browser using WebGL.I write an automatic conversion tool to turn a GLSL shader into an HLSL shader that help you fast convert ShaderToy to ShaderLab unity.

Microsoft have published a very useful reference guide [here](https://docs.microsoft.com/en-us/previous-versions/windows/apps/dn166865(v=win.10)) which details many of the general differences between GLSL and HLSL. Unity also have a useful page [here](https://docs.unity3d.com/Manual/SL-PlatformDifferences.html).
```
    Replace iGlobalTime shader input (“shader playback time in seconds”) with _Time.y
    Replace iResolution.xy (“viewport resolution in pixels”) with _ScreenParams.xy
    Replace vec2 types with float2, mat2 with float2x2 etc.
    Replace vec3(1) shortcut constructors in which all elements have same value with explicit float3(1,1,1)
    Replace Texture2D with Tex2D
    Replace atan(x,y) with atan2(y,x) <- Note parameter ordering!
    Replace mix() with lerp()
    Replace *= with mul()
    Remove third (bias) parameter from Texture2D lookups
    mainImage(out vec4 fragColor, in vec2 fragCoord) is the fragment shader function, equivalent to float4 mainImage(float2 fragCoord : SV_POSITION) : SV_Target
    UV coordinates in GLSL have 0 at the top and increase downwards, in HLSL 0 is at the bottom and increases upwards, so you may need to use uv.y = 1 – uv.y at some point.
```
Note that ShaderToys don’t have a vertex shader function – they are effectively full-screen pixel shaders which calculate the value at each UV coordinate in screenspace. As such, they are most suitable for use in a full-screen image effect (or, you can just apply them to a plane/quad if you want) in which the UVs range from 0-1.

But calculating pixel shaders for each pixel in a 1024×768 resolution (or higher) is *expensive*. One solution if you want to achieve anything like a game-playable framerate is to render the effect to a fixed-size rendertexture, and then scale that up to fill the screen. Here’s a simple generic script to do that:

# Demo
# https://www.youtube.com/watch?v=ZncPTfT8wLg



__________________________


# How to use:
# 1.copy your lovely shader from www.shadertoy.com
![ShaderToy](https://user-images.githubusercontent.com/16706911/33229710-44a67f1e-d1e9-11e7-9ed2-f338625b6c5d.jpg)

# 2.Open ShaderMan from Tools\ShaderMan
before opening shaderman be sure that there is codegenerator.cs in scene otherwise ShaderMan throws NullReferenceException.
# 3.Choose Name for you shader:
![Step](https://user-images.githubusercontent.com/16706911/33229605-db538f5e-d1e6-11e7-8563-a48a7df3ae60.png)

# 4.Import your shader from shaderToy.com
![Step](https://user-images.githubusercontent.com/16706911/33229653-1350acc4-d1e8-11e7-85d1-3f4613eed690.png)


# 5.Click On Convert And Enjoy :D
![Final Step](https://user-images.githubusercontent.com/16706911/33229663-366dc5ac-d1e8-11e7-81ec-4539a025f111.png)


________________________
# Video Tutorial is Available


![capturedwadad](https://user-images.githubusercontent.com/16706911/43994219-9bafa39e-9dae-11e8-9560-c759c01dbb6d.PNG)

https://www.youtube.com/watch?v=MCER5P8Xz3w&lc=z22ysdkqln2texqj004t1aokgkzlpvkn3rdybfw1wtugrk0h00410

________________________

# Musual
Music Visualization Shader

![Musual](https://user-images.githubusercontent.com/16706911/40903967-693154a8-67ee-11e8-8c09-6d59b9a463b8.PNG)

# https://github.com/smkplus/Musual

# https://youtu.be/ppSjyvxR8uI





