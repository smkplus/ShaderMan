// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Noise animation - Lava"{
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
//Noise animation - Lava
//by nimitz (twitter: @stormoid)


//Somewhat inspired by the concepts behind "flow noise"
//every octave of noise is fmodulated separately
//with displacement using a rotated fixedtor field

//This is a more standard use of the flow noise
//unlike my normalized fixedtor field version (https://www.shadertoy.com/view/MdlXRS)
//the noise octaves are actually displaced to create a directional flow

//Sinus ridged fbm is used for better effect.

#define time _Time.y*0.1

fixed hash21(in fixed2 n){ return frac(sin(dot(n, fixed2(12.9898, 4.1414))) * 43758.5453); }
fixed2x2 makem2(in fixed theta){fixed c = cos(theta);fixed s = sin(theta);return fixed2x2(c,-s,s,c);}
fixed noise( in fixed2 x ){return tex2D(_MainTex, x*.01).x;}

fixed2 gradn(fixed2 p)
{
	fixed ep = .09;
	fixed gradx = noise(fixed2(p.x+ep,p.y))-noise(fixed2(p.x-ep,p.y));
	fixed grady = noise(fixed2(p.x,p.y+ep))-noise(fixed2(p.x,p.y-ep));
	return fixed2(gradx,grady);
}

fixed flow(in fixed2 p)
{
	fixed z=2.;
	fixed rz = 0.;
	fixed2 bp = p;
	for (fixed i= 1.;i < 7.;i++ )
	{
		//primary flow speed
		p += time*.6;
		
		//secondary flow speed (speed of the perceived flow)
		bp += time*1.9;
		
		//displacement field (try changing time multiplier)
		fixed2 gr = gradn(i*p*.34+time*1.);
		
		//rotation of the displacement field
		gr= mul(gr,makem2(time*6.-(0.05*p.x+0.03*p.y)*40.));
		
		//displace the system
		p += gr*.5;
		
		//add noise octave
		rz+= (sin(noise(p)*7.)*0.5+0.5)/z;
		
		//blend factor (blending displaced system with base system)
		//you could call this adfixedtion factor (.5 being low, .95 being high)
		p = lerp(bp,p,.77);
		
		//intensity scaling
		z *= 1.4;
		//octave scaling
		p *= 2.;
		bp *= 1.9;
	}
	return rz;	
}

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 p = i.uv.xy / 1-0.5;
	p.x *= 1/1;
	p*= 3.;
	fixed rz = flow(p);
	
	fixed3 col = fixed3(.2,0.07,0.01)/rz;
	col=pow(col,fixed3(1.4,1.4,1.4));
	return  fixed4(col,1.0);
}
}ENDCG
}
}
}

