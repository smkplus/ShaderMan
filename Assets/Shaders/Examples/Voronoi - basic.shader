// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Voronoi - basic"{
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
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, fmodify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


fixed2 hash( fixed2 p ) { p=fixed2(dot(p,fixed2(127.1,311.7)),dot(p,fixed2(269.5,183.3))); return frac(sin(p)*18.5453); }

// return distance, and cell id
fixed2 voronoi( in fixed2 x )
{
    fixed2 n = floor( x );
    fixed2 f = frac( x );

	fixed3 m = fixed3( 8.0 , 8.0 , 8.0 );
    [unroll(100)]
for( int j=-1; j<=1; j++ )
    [unroll(100)]
for( int i=-1; i<=1; i++ )
    {
        fixed2  g = fixed2( fixed(i), fixed(j) );
        fixed2  o = hash( n + g );
      //fixed2  r = g - f + o;
	    fixed2  r = g - f + (0.5+0.5*sin(_Time.y+6.2831*o));
		fixed d = dot( r, r );
        if( d<m.x )
            m = fixed3( d, o );
    }

    return fixed2( sqrt(m.x), m.y+m.z );
}

fixed4 frag(v2f i) : SV_Target{

{
    fixed2 p = i.uv.xy/max(1,1);
    
    // computer voronoi patterm
    fixed2 c = voronoi( (14.0+6.0*sin(0.2*_Time.y))*p );

    // colorize
    fixed3 col = 0.5 + 0.5*cos( c.y*6.2831 + fixed3(0.0,1.0,2.0) );	
    col *= clamp(1.0 - 0.4*c.x*c.x,0.0,1.0);
    col -= (1.0-smoothstep( 0.08, 0.09, c.x));
	
    return  fixed4( col, 1.0 );
}
}ENDCG
}
}
}

