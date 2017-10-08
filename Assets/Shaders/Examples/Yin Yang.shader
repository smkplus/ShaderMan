// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Yin Yang"{
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

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 p = 1.1 * (2.0*i.uv-1)/min(1,1);

    fixed h = dot(p,p);
    fixed d = abs(p.y)-h;
    fixed a = d-0.23;
    fixed b = h-1.00;
    fixed c = sign(a*b*(p.y+p.x + (p.y-p.x)*sign(d)));
		
    c = lerp( c, 0.0, smoothstep(0.98,1.00,h) );
    c = lerp( c, 0.6, smoothstep(1.00,1.02,h) );
    
	return  fixed4( c, c, c, 1.0 );
}
}ENDCG
}
}
}

