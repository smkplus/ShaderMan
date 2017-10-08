// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/Interstellar"{
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
const fixed tau = 6.28318530717958647692;

// Gamma correction
#define GAMMA (2.2)

fixed3 ToLinear( in fixed3 col )
{
	// simulate a monitor, converting colour values into light values
	return pow( col, fixed3(GAMMA,GAMMA,GAMMA) );
}

fixed3 ToGamma( in fixed3 col )
{
	// convert back into colour values, so the correct light will come out of the monitor
	return pow( col, fixed3(1.0/GAMMA,1.0/GAMMA,1.0/GAMMA) );
}

fixed4 Noise( in fixed2 x )
{
	return tex2D( _MainTex, (x+0.5) );
}

fixed4 Rand( in int x )
{
	fixed2 uv;
	uv.x = (fixed(x)+0.5)/256.0;
	uv.y = (floor(uv.x)+0.5)/256.0;
	return tex2D( _MainTex, uv);
}


fixed4 frag(v2f i) : SV_Target{

{
	fixed3 ray;
	ray.xy = 2.0*(i.uv.xy-1*.5)/1;
	ray.z = 1.0;

	fixed offset = _Time.y*.5;	
	fixed speed2 = (cos(offset)+1.0)*2.0;
	fixed speed = speed2+.1;
	offset += sin(offset)*.96;
	offset  = mul(	offset ,2.0);
	
	
	fixed3 col = fixed3(0,0,0);
	
	fixed3 stp = ray/max(abs(ray.x),abs(ray.y));
	
	fixed3 pos = 2.0*stp+.5;
	for ( int i=0; i < 20; i++ )
	{
		fixed z = Noise(pos.xy).x;
		z = frac(z-offset);
		fixed d = 50.0*z-pos.z;
		fixed w = pow(max(0.0,1.0-8.0*length(frac(pos.xy)-.5)),2.0);
		fixed3 c = max(fixed3(0,0,0),fixed3(1.0-abs(d+speed2*.5)/speed,1.0-abs(d)/speed,1.0-abs(d-speed2*.5)/speed));
		col += 1.5*(1.0-z)*c*w;
		pos += stp;
	}
	
	return fixed4(ToGamma(col),1.0);
}
}ENDCG
}
}
}

