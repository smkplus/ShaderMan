// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/Warpingprocedural2"{
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
// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// See here for a tutorial on how to make this: http://www.iquilezles.org/www/articles/warp/warp.htm

const fixed2x2 m = fixed2x2( 0.80,  0.60, -0.60,  0.80 );

fixed noise( in fixed2 x )
{
	return sin(1.5*x.x)*sin(1.5*x.y);
}

fixed fbm4( fixed2 p )
{
    fixed f = 0.0;
    f += 0.5000*noise( p ); p = mul(m,p)*2.02;
    f += 0.2500*noise( p ); p = mul(m,p)*2.03;
    f += 0.1250*noise( p ); p = mul(m,p)*2.01;
    f += 0.0625*noise( p );
    return f/0.9375;
}

fixed fbm6( fixed2 p )
{
    fixed f = 0.0;
    f += 0.500000*(0.5+0.5*noise( p )); p = mul(m,p)*2.02;
    f += 0.250000*(0.5+0.5*noise( p )); p = mul(m,p)*2.03;
    f += 0.125000*(0.5+0.5*noise( p )); p = mul(m,p)*2.01;
    f += 0.062500*(0.5+0.5*noise( p )); p = mul(m,p)*2.04;
    f += 0.031250*(0.5+0.5*noise( p )); p = mul(m,p)*2.01;
    f += 0.015625*(0.5+0.5*noise( p ));
    return f/0.96875;
}


fixed func( fixed2 q, out fixed4 ron )
{
    fixed ql = length( q );
    q.x += 0.05*sin(0.27*_Time.y+ql*4.1);
    q.y += 0.05*sin(0.23*_Time.y+ql*4.3);
    q  = mul(    q ,0.5);

	fixed2 o = fixed2(0.0,0.0);
    o.x = 0.5 + 0.5*fbm4(2.0*q);
    o.y = 0.5 + 0.5*fbm4( fixed2(2.0*q+fixed2(5.2,5.2))  );

	fixed ol = length( o );
    o.x += 0.02*sin(0.12*_Time.y+ol)/ol;
    o.y += 0.02*sin(0.14*_Time.y+ol)/ol;

    fixed2 n;
    n.x = fbm6( fixed2(4.0*o+fixed2(9.2,9.2))  );
    n.y = fbm6( fixed2(4.0*o+fixed2(5.7,5.7))  );

    fixed2 p = 4.0*q + 4.0*n;

    fixed f = 0.5 + 0.5*fbm4( p );

    f = lerp( f, f*f*f*3.5, f*abs(n.x) );

    fixed g = 0.5 + 0.5*sin(4.0*p.x)*sin(4.0*p.y);
    f  = mul(    f ,1.0-0.5*pow( g, 8.0 ));

	ron = fixed4( o, n );
	
    return f;
}



fixed3 doMagic(fixed2 p)
{
	fixed2 q = p*0.6;

    fixed4 on = fixed4(0.0,0.0,0.0,0.0);
    fixed f = func(q, on);

	fixed3 col = fixed3(0.0,0.0,0.0);
    col = lerp( fixed3(0.2,0.1,0.4), fixed3(0.3,0.05,0.05), f );
    col = lerp( col, fixed3(0.9,0.9,0.9), dot(on.zw,on.zw) );
    col = lerp( col, fixed3(0.4,0.3,0.3), 0.5*on.y*on.y );
    col = lerp( col, fixed3(0.0,0.2,0.4), 0.5*smoothstep(1.2,1.3,abs(on.z)+abs(on.w)) );
    col = clamp( col*f*2.0, 0.0, 1.0 );
    
	fixed3 nor = normalize( fixed3( 1, 6.0, 1 ) );

    fixed3 lig = normalize( fixed3( 0.9, -0.2, -0.4 ) );
    fixed dif = clamp( 0.3+0.7*dot( nor, lig ), 0.0, 1.0 );
    fixed3 bdrf;
    bdrf  = fixed3(0.70,0.90,0.95)*(nor.y*0.5+0.5);
    bdrf += fixed3(0.15,0.10,0.05)*dif;
    col  = mul(    col ,1.2*bdrf);
	col = 1.0-col;
	return 1.1*col*col;
}
fixed4 frag(v2f i) : SV_Target{

{
    fixed2 q = i.uv / 1;
    fixed2 p = -1.0 + 2.0 * q;
    p.x  = mul(    p.x ,1/1);

    return fixed4( doMagic( p ), 1.0 );
}

}ENDCG
}
}
}

