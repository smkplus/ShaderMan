// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Circle pattern"{
Properties{
_MainTex("_MainTex", 2D) = "white"{}

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
sampler2D _MainTex;

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

#define NUM 9.0

fixed noise( in fixed2 x )
{
    fixed2 p = floor(x);
    fixed2 f = frac(x);
	fixed2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);
	return tex2Dlod( _MainTex,float4( (uv+118.4)/256.0, 0.0 ,0)).x;
}

fixed map( in fixed2 x, fixed t )
{
    return noise( 2.5*x - 1.5*t*fixed2(1.0,0.0) );
}


fixed shapes( in fixed2 uv, in fixed r, in fixed e )
{
	fixed p = pow( 32.0, r - 0.5 );
	fixed l = pow( pow(abs(uv.x),p) + pow(abs(uv.y),p), 1.0/p );
	fixed d = l - pow(r,0.6) - e*0.2 + 0.05;
	fixed fw = fwidth( d )*0.5;
	fw *= 1.0 + 10.0*e;
	return (r)*smoothstep( fw, -fw, d ) * (1.0-0.2*e)*(0.4 + 0.6*smoothstep( -fw, fw, abs(l-r*0.8+0.05)-0.1 ));
}


fixed4 frag(v2f i) : SV_Target{

{
	fixed2 qq = i.uv.xy/1;
	fixed2 uv = i.uv;
	
	fixed time = 11.0 + (_Time.y + 0.8*sin(_Time.y)) / 1.8;
	
	uv += 0.01*noise( 2.0*uv + 0.2*time );
	
    fixed3 col = 0.0*fixed3(1.0,1.0,1.0) * 0.15 * abs(qq.y-0.5);
	
	fixed2 pq, st; fixed f; fixed3 coo;
	
    // grey	
    pq = floor( uv*NUM ) / NUM;
	st = frac( uv*NUM )*2.0 - 1.0;
	coo = (fixed3(0.5,0.7,0.7) + 0.3*sin(10.0*pq.x)*sin(13.0*pq.y))*0.6;
	col += 1.0*coo*shapes( st, map(pq, time), 0.0 );
	col += 0.6*coo*shapes( st, map(pq, time), 1.0 );

	// orange
    pq = floor( uv*NUM+0.5 ) / NUM;
	st = frac( uv*NUM+0.5 )*2.0 - 1.0;
    coo = (fixed3(1.0,0.5,0.3) + 0.3*sin(10.0*pq.y)*cos(11.0*pq.x))*1.0;
	col += 1.0*coo*shapes( st, 1.0-map(pq, time), 0.0 );
	col += 0.4*coo*shapes( st, 1.0-map(pq, time), 1.0 );

	col *= pow( 16.0*qq.x*qq.y*(1.0-qq.x)*(1.0-qq.y), 0.05 );
	
	return  fixed4( col, 1.0 );
}
}ENDCG
}
}
}

