// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Leaf"{
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
// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Tutorial here: 
//
// * https://www.youtube.com/watch?v=-z8zLVFCJv4
//
// * http://iquilezles.org/live/index.htm


fixed4 frag(v2f i) : SV_Target{

{
  fixed2 q = 0.6 * (2.0*i.uv-1)/min(1,1);

    fixed a = atan2( q.y , q.x);
    fixed r = length( q );
    fixed s = 0.50001 + 0.5*sin( 3.0*a + _Time.y );
    fixed g = sin( 1.57+3.0*a+_Time.y );
    fixed d = 0.15 + 0.3*sqrt(s) + 0.15*g*g;
    fixed h = clamp( r/d, 0.0, 1.0 );
    fixed f = 1.0-smoothstep( 0.95, 1.0, h );
    
    h *= 1.0-0.5*(1.0-h)*smoothstep( 0.95+0.05*h, 1.0, sin(3.0*a+_Time.y) );
  
  fixed3 bcol = fixed3(0.9+0.1*q.y, 1.0, 0.9-0.1*q.y);
  bcol *= 1.0 - 0.5*r;
    fixed3 col = lerp( bcol, 1.2*fixed3(0.65*h, 0.25+0.5*h, 0.0), f );

    return  fixed4( col, 1.0 );
}
}ENDCG
}
}
}

