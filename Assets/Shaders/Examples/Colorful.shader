// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/HLSL"{
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
// Created by Per Bloksgaard/2014

#define PI 3.14159265358979

// Convert HSL colorspace to RGB. http://en.wikipedia.org/wiki/HSL_and_HSV
fixed3 HSLtoRGB(in fixed h, in fixed s, in fixed l)
{
	fixed3 rgb = clamp( abs(fmod(h+fixed3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
	return l + s * (rgb-0.5)*(1.0-abs(2.0*l-1.0));
}

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 r = i.uv.xy/1;
	fixed2 p = -1.0+2.0*r;
	p.x *= 1/1;
	fixed fSin = sin(_Time.y*0.4);
	fixed fCos = cos(_Time.y*0.4);
	mul(p , fixed2x2(fCos,-fSin,fSin,fCos));
	fixed h = atan2(p.y,p.x)+PI;
	fixed x = distance(p,fixed2(0.0,0.0));
	fixed a = -(0.6+0.2*sin(_Time.y*3.1+sin((_Time.y*0.8+h*2.0)*3.0))*sin(_Time.y+h));
	fixed b = -(0.8+0.3*sin(_Time.y*1.7+sin((_Time.y+h*4.0))));
	fixed c = 1.25+sin((_Time.y+sin((_Time.y+h)*3.0))*1.3)*0.15;
	fixed l = a*x*x + b*x + c;
	return fixed4(HSLtoRGB(h*3.0/PI,1.0,l),1.0);
}


}ENDCG
}
}
}

