// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/CRT"{
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
// CRT Effect Pulled from : "[SIG15] Mario World 1-1" by Krzysztof Narkowicz @knarkowicz
// 
// 
#define SPRITE_DEC( x, i ) 	fmod( floor( i / pow( 4.0, fmod( x, 8.0 ) ) ), 4.0 )
#define SPRITE_DEC2( x, i ) fmod( floor( i / pow( 4.0, fmod( x, 11.0 ) ) ), 4.0 )
#define RGB( r, g, b ) fixed3( fixed( r ) / 255.0, fixed( g ) / 255.0, fixed( b ) / 255.0 )

fixed2 CRTCurveUV( fixed2 uv )
{
    uv = uv * 2.0 - 1.0;
    fixed2 offset = abs( uv.yx ) / fixed2( 6.0, 4.0 );
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

void DrawVignette( inout fixed3 color, fixed2 uv )
{    
    fixed vignette = uv.x * uv.y * ( 1.0 - uv.x ) * ( 1.0 - uv.y );
    vignette = clamp( pow( 16.0 * vignette, 0.3 ), 0.0, 1.0 );
    color  = mul(    color ,vignette);
}

void DrawScanline( inout fixed3 color, fixed2 uv )
{
    fixed scanline 	= clamp( 0.95 + 0.05 * cos( 3.14 * ( uv.y + 0.008 * _Time.y ) * 240.0 * 1.0 ), 0.0, 1.0 );
    fixed grille 	= 0.85 + 0.15 * clamp( 1.5 * cos( 3.14 * uv.x * 640.0 * 1.0 ), 0.0, 1.0 );    
    color  = mul(    color ,scanline * grille * 1.2);
}

fixed4 frag(v2f i) : SV_Target{

{
    // we want to see at least 224x192 (overscan) and we want multiples of pixel size
    fixed resMultX  = floor( 1 / 224.0 );
    fixed resMultY  = floor( 1 / 192.0 );
    fixed resRcp	= 1.0 / max( min( resMultX, resMultY ), 1.0 );
    
    fixed time			= _Time.y;
    fixed screenWidth	= floor( 1 * resRcp );
    fixed screenHeight	= floor( 1 * resRcp );
    fixed pixelX 		= floor( i.uv.x * resRcp );
    fixed pixelY 		= floor( i.uv.y * resRcp );

    fixed3 color = RGB( 92, 148, 252 );
 	 
     

    
    // CRT effects (curvature, vignette, scanlines and CRT grille)
    fixed2 uv    = i.uv.xy / 1;
    fixed2 crtUV = CRTCurveUV( i.uv );
    if ( crtUV.x < 0.0 || crtUV.x > 1.0 || crtUV.y < 0.0 || crtUV.y > 1.0 )
    {
        color = fixed3( 0.0, 0.0, 0.0 );
    }
    DrawVignette( color, crtUV );
    DrawScanline( color, i.uv );
    
	fragColor.xyz 	= color;
    fragColor.w		= 1.0;
    return fragColor;
}
}ENDCG
}
}
}

