// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderToyConverter/Noor"{
Properties{
_MainTex("MainTex", 2D) = "white"{}
_SecondTex("SecondTex", 2D) = "white"{}

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
sampler2D _SecondTex;

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
#define DITHER			//Dithering toggle
#define QUALITY		0	//0- low, 1- medium, 2- high

#define DECAY		.974
#define EXPOSURE	.24
#if (QUALITY==2)
 #define SAMPLES	64
 #define DENSITY	.97
 #define WEIGHT		.25
#else
#if (QUALITY==1)
 #define SAMPLES	32
 #define DENSITY	.95
 #define WEIGHT		.25
#else
 #define SAMPLES	16
 #define DENSITY	.93
 #define WEIGHT		.36
#endif
#endif

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 uv = i.uv.xy / 1;
    
    fixed2 coord = i.uv;
    fixed2 lightpos = tex2D(_MainTex, i.uv).zw;
   	
    fixed occ = tex2D(_MainTex, i.uv).x; //light
    fixed obj = tex2D(_MainTex, i.uv).y; //objects
    fixed dither = tex2D(_SecondTex, i.uv/iChannelResolution[1].xy).r;    
        
    fixed2 dtc = (coord - lightpos) * (1. / fixed(SAMPLES) * DENSITY);
    fixed illumdecay = 1.;
    
    [unroll(100)]
for(int i=0; i<SAMPLES; i++)
    {
        coord -= dtc;
        #ifdef DITHER
        	fixed s = tex2D(_MainTex, coord+(dtc*dither)).x;
        #else
        	fixed s = tex2D(_MainTex, coord).x;
        #endif
        s *= illumdecay * WEIGHT;
        occ += s;
        illumdecay *= DECAY;
    }
        
	return fixed4(fixed3(0., 0., obj*.333)+occ*EXPOSURE,1.0);
}


}ENDCG
}
}
}

