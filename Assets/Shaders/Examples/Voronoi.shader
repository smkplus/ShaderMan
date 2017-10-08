// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Voronoi"{
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
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, fmodify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// I've not seen anybody out there computing correct cell interior distances for Voronoi
// patterns yet. That's why they cannot shade the cell interior correctly, and why you've
// never seen cell boundaries rendered correctly. 

// However, here's how you do mathematically correct distances (note the equidistant and non
// degenerated grey isolines inside the cells) and hence edges (in yellow):

// http://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm

#define ANIMATE

fixed2 hash2( fixed2 p )
{
	// tex2D based white noise
	return tex2Dlod( _MainTex,float4( (p+0.5)/256.0, 0.0 ,0)).xy;
	
    // procedural white noise	
	//return frac(sin(fixed2(dot(p,fixed2(127.1,311.7)),dot(p,fixed2(269.5,183.3))))*43758.5453);
}

fixed3 voronoi( in fixed2 x )
{
    fixed2 n = floor(x);
    fixed2 f = frac(x);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
	fixed2 mg, mr;

    fixed md = 8.0;
    [unroll(100)]
for( int j=-1; j<=1; j++ )
    [unroll(100)]
for( int i=-1; i<=1; i++ )
    {
        fixed2 g = fixed2(fixed(i),fixed(j));
		fixed2 o = hash2( n + g );
		#ifdef ANIMATE
        o = 0.5 + 0.5*sin( _Time.y + 6.2831*o );
        #endif	
        fixed2 r = g + o - f;
        fixed d = dot(r,r);

        if( d<md )
        {
            md = d;
            mr = r;
            mg = g;
        }
    }

    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    md = 8.0;
    [unroll(100)]
for( int j=-2; j<=2; j++ )
    [unroll(100)]
for( int i=-2; i<=2; i++ )
    {
        fixed2 g = mg + fixed2(fixed(i),fixed(j));
		fixed2 o = hash2( n + g );
		#ifdef ANIMATE
        o = 0.5 + 0.5*sin( _Time.y + 6.2831*o );
        #endif	
        fixed2 r = g + o - f;

        if( dot(mr-r,mr-r)>0.00001 )
        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
    }

    return fixed3( md, mr );
}

fixed4 frag(v2f i) : SV_Target{

{
    fixed2 p = i.uv/1;

    fixed3 c = voronoi( 8.0*p );

	// isolines
    fixed3 col = c.x*(0.5 + 0.5*sin(64.0*c.x))*fixed3(1.0,1.0,1.0);
    // borders	
    col = lerp( fixed3(1.0,0.6,0.0), col, smoothstep( 0.04, 0.07, c.x ) );
    // feature points
	fixed dd = length( c.yz );
	col = lerp( fixed3(1.0,0.6,0.1), col, smoothstep( 0.0, 0.12, dd) );
	col += fixed3(1.0,0.6,0.1)*(1.0-smoothstep( 0.0, 0.04, dd));

	return  fixed4(col,1.0);
}

}ENDCG
}
}
}

