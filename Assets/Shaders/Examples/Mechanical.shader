// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Mechanical"{
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
// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

fixed fstep( fixed x )
{
    fixed df = fwidth(x);
    return smoothstep( -df, df,  x);
}

fixed hash( fixed2 p )
{
    return frac(sin(dot(p,fixed2(127.1,311.7)))*43758.5453123);
}

fixed4 frag(v2f i) : SV_Target{

{
    fixed2  p = (-1 + 2.0*i.uv.xy)/1;
    fixed2  q = i.uv.xy/1;
    
    fixed di = hash( i.uv.xy );
    
    const int numSamples = 8;
    
    fixed img = 0.0;
    fixed acc = 0.0;
    [unroll(100)]
for( int i=0; i<numSamples; i++ )
    {
        fixed nt = (fixed(i)+di)/fixed(numSamples);
            
        fixed time = _Time.y - nt*(1.0/24.0);
        
        fixed si = fmod( floor(time*0.25), 2.0 );

        fixed ftime = pow(clamp(4.0*frac(time),0.0,1.0),4.0);
        fixed itime = floor(time);
        fixed atime = (itime + ftime)*1.0 + time;
        
        fixed2 ce = fixed2(0.0,0.0);
        ce.x = -0.30 + 1.25*(ftime - frac(time));
        ce.y =  0.15 - 0.15*smoothstep(0.0,0.3,abs(frac(time+0.65)-0.5))*(1.0-si);
        
        fixed d = length( p - ce );
        fixed a = atan2( p.x - ce.x , p.y - ce.y) + atime;
        fixed r = 0.7 + 0.1*smoothstep(-0.3,0.3,cos(10.0*a));
        fixed h = r - d;
        
        fixed f = fstep( h );
        f *= fstep( abs(d-0.4) - 0.1 + 0.05*smoothstep(-0.3,0.3,cos(5.0*a)) );
        f *= fstep( abs(d-0.1) - 0.02 );

        fixed2 c = fixed2(d,a);
        fixed pe = 6.2831/10.0;
        c.y = fmod( a+pe*0.5, pe ) - pe*0.5;
        c = c.x*fixed2( cos(c.y), sin(c.y) );
        f *= fstep( abs(length(c-fixed2(0.6,0.0))-0.05)-0.01 );

        a -= si*0.5*clamp(4.0*frac(time*4.0),0.0,1.0);
        c = fixed2(d,a);
        c.y = fmod( a+pe*0.5, pe ) - pe*0.5;
        c = c.x*fixed2( cos(c.y), sin(c.y) );
        f *= fstep( length(c-fixed2(0.2,0.0))-0.02 );

        f = max( f, 1.0*fstep( -0.8-p.y+ce.y + 0.1*smoothstep(-0.3,0.3,sin(1.5+14.0*(p.x-ce.x) +10.0*atime)) ) );
        
        fixed w =1.0 - 0.2*nt;
        img += w * f;
        acc += w;
    }
    img /= acc;
    
    fixed3 bg = fixed3(1.0- 0.6*q.y,1.0- 0.6*q.y,1.0- 0.6*q.y) - 0.15*hash( q) + 0.05*di;
    bg = smoothstep( fixed3(0.2,0.1,0.0), fixed3(0.9,0.9,1.0), bg );
    
    fixed3 fg = fixed3(0.0,0.0,0.0);
    fixed3 col = lerp( bg, fg, img );
    
    col *= pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2);
    col *= smoothstep( 0.0, 3.0, _Time.y );

	return  fixed4( col, 1.0 );
}
}ENDCG
}
}
}

