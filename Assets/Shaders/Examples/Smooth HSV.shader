// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Smooth HSV"{
Properties{

}
SubShader{
Pass{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest
#include "UnityCG.cginc"
struct appdata{
float4 vertex : POSITION;
float2 uv : TEXCOORD0;
};
uniform fixed4     fragColor;
uniform fixed      iChannelTime[4];// channel playback time (in seconds)
uniform fixed3     iChannelResolution[4];// channel resolution (in pixels)
uniform fixed4     iMouse;// mouse pixel coords. xy: current (if MLB down), zw: click
uniform fixed4     iDate;// (year, month, day, time in seconds)
uniform fixed      iSampleRate;// sound sample rate (i.e., 44100)

struct v2f
{
float2 uv : TEXCOORD0;
float4 vertex : SV_POSITION;
float4 screenCoord : TEXCOORD1;
};

v2f vert(appdata v)
{
v2f o;
o.vertex = UnityObjectToClipPos(v.vertex);
o.uv = v.uv;
o.screenCoord.xy = ComputeScreenPos(o.vertex);
return o;
}
// The MIT License
// Copyright © 2014 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, fmodify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



// Converting from HSV to RGB leads to C1 discontinuities, for the RGB components
// are driven by picewise linear segments. Using a cubic smoother (smoothstep) makes 
// the color transitions in RGB C1 continuous when linearly interpolating the hue H.

// C2 continuity can be achieved as well by replacing smoothstep with a quintic
// polynomial. Of course all these cubic, quintic and trigonometric variations break 
// the standard (http://en.wikipedia.org/wiki/HSL_and_HSV), but they look better.


// Official HSV to RGB conversion 
fixed3 hsv2rgb( in fixed3 c )
{
    fixed3 rgb = clamp( abs(fmod(c.x*6.0+fixed3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	return c.z * lerp( fixed3(1.0,1.0,1.0), rgb, c.y);
}

// Smooth HSV to RGB conversion 
fixed3 hsv2rgb_smooth( in fixed3 c )
{
    fixed3 rgb = clamp( abs(fmod(c.x*6.0+fixed3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * lerp( fixed3(1.0,1.0,1.0), rgb, c.y);
}

// compare
fixed4 frag(v2f i) : SV_Target{

{
	fixed2 uv = i.uv;
	
	fixed3 hsl = fixed3( uv.x, 1.0, uv.y );

	fixed3 rgb_o = hsv2rgb( hsl );
	fixed3 rgb_s = hsv2rgb_smooth( hsl );
	
	fixed3 rgb = lerp( rgb_o, rgb_s, smoothstep( -0.2, 0.2, sin(2.0*_Time.y)) );
	
	return  fixed4( rgb, 1.0 );
}
}ENDCG
}
}
}

