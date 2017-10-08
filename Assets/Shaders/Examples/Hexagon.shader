// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/MyShader"{
Properties{
_MainTex("MainTex", 2D) = "white"{}

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
uniform sampler2D  _MainTex;
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
// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// { 2d cell id, distance to border, distnace to center )
fixed4 hexagon( fixed2 p ) 
{
	fixed2 q = fixed2( p.x*2.0*0.5773503, p.y + p.x*0.5773503 );
	
	fixed2 pi = floor(q);
	fixed2 pf = frac(q);

	fixed v = fmod(pi.x + pi.y, 3.0);

	fixed ca = step(1.0,v);
	fixed cb = step(2.0,v);
	fixed2  ma = step(pf.xy,pf.yx);
	
    // distance to borders
	fixed e = dot( ma, 1.0-pf.yx + ca*(pf.x+pf.y-1.0) + cb*(pf.yx-2.0*pf.xy) );

	// distance to center	
	p = fixed2( q.x + floor(0.5+p.y/1.5), 4.0*p.y/3.0 )*0.5 + 0.5;
	fixed f = length( (frac(p) - 0.5)*fixed2(1.0,0.85) );		
	
	return fixed4( pi + ca - cb*ma, e, f );
}

fixed hash1( fixed2  p ) { fixed n = dot(p,fixed2(127.1,311.7) ); return frac(sin(n)*43758.5453); }

fixed noise( in fixed3 x )
{
    fixed3 p = floor(x);
    fixed3 f = frac(x);
	f = f*f*(3.0-2.0*f);
	fixed2 uv = (p.xy+fixed2(37.0,17.0)*p.z) + f.xy;
	fixed2 rg = tex2Dlod( _MainTex,float4( (uv+0.5)/256.0, 0.0 ,0)).yx;
	return lerp( rg.x, rg.y, f.z );
}


fixed4 frag(v2f i) : SV_Target{

{
    fixed2 uv = i.uv.xy/1;
	fixed2 pos = (-1 + 2.0*i.uv.xy)/1;
	
    // distort
	pos *= 1.0 + 0.3*length(pos);
	
    // gray
	fixed4 h = hexagon(8.0*pos + 0.5*_Time.y);
	fixed n = noise( fixed3(0.3*h.xy+_Time.y*0.1,_Time.y) );
	fixed3 col = 0.15 + 0.15*hash1(h.xy+1.2)*fixed3(1.0,1.0,1.0);
	col *= smoothstep( 0.10, 0.11, h.z );
	col *= smoothstep( 0.10, 0.11, h.w );
	col *= 1.0 + 0.15*sin(40.0*h.z);
	col *= 0.75 + 0.5*h.z*n;
	

	// red
	h = hexagon(6.0*pos + 0.6*_Time.y);
	n = noise( fixed3(0.3*h.xy+_Time.y*0.1,_Time.y) );
	fixed3 colb = 0.9 + 0.8*sin( hash1(h.xy)*1.5 + 2.0 + fixed3(0.0,1.0,1.0) );
	colb *= smoothstep( 0.10, 0.11, h.z );
	colb *= 1.0 + 0.15*sin(40.0*h.z);
	colb *= 0.75 + 0.5*h.z*n;

	h = hexagon(6.0*(pos+0.1*fixed2(-1.3,1.0)) + 0.6*_Time.y);
    col *= 1.0-0.8*smoothstep(0.45,0.451,noise( fixed3(0.3*h.xy+_Time.y*0.1,_Time.y) ));

	col = lerp( col, colb, smoothstep(0.45,0.451,n) );

	
	col *= pow( 16.0*i.uv.x*(1.0-i.uv.x)*i.uv.y*(1.0-i.uv.y), 0.1 );
	
	return fixed4( col, 1.0 );
}
}ENDCG
}
}
}

