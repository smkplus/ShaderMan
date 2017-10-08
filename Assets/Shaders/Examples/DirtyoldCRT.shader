// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/DirtyoldCRT"{
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
fixed scanline(fixed2 uv) {
	return sin(1 * uv.y * 0.7 - _Time.y * 10.0);
}

fixed slowscan(fixed2 uv) {
	return sin(1 * uv.y * 0.02 + _Time.y * 6.0);
}

fixed2 colorShift(fixed2 uv) {
	return fixed2(
		uv.x,
		uv.y + sin(_Time.y)*0.02
	);
}

fixed noise(fixed2 uv) {
	return clamp(tex2D(_SecondTex, uv.xy + _Time.y*6.0).r +tex2D(_SecondTex,uv),0,1);

}

// from https://www.shadertoy.com/view/4sf3Dr
// Thanks, Jasper
fixed2 crt(fixed2 coord, fixed bend)
{
	// put in symmetrical coords
	coord = (coord - 0.5) * 2.0;

	coord  = mul(	coord ,0.5);	
	
	// deform coords
	coord.x  = mul(	coord.x ,1.0 + pow((abs(coord.y) / bend), 2.0));
	coord.y  = mul(	coord.y ,1.0 + pow((abs(coord.x) / bend), 2.0));

	// transform back to 0.0 - 1.0 space
	coord  = (coord / 1.0) + 0.5;

	return coord;
}

fixed2 colorshift(fixed2 uv, fixed amount, fixed rand) {
	
	return fixed2(
		uv.x,
		uv.y + amount * rand // * sin(uv.y * 1 * 0.12 + _Time.y)
	);
}

fixed2 scandistort(fixed2 uv) {
	fixed scan1 = clamp(cos(uv.y * 2.0 + _Time.y), 0.0, 1.0);
	fixed scan2 = clamp(cos(uv.y * 2.0 + _Time.y + 4.0) * 10.0, 0.0, 1.0) ;
	fixed amount = scan1 * scan2 * uv.x; 
	
	uv.x -= 0.05 * lerp(tex2D(_SecondTex, fixed2(uv)),0.5,0.5);

	return uv;
	 
}

fixed vignette(fixed2 uv) {
	uv = (uv - 0.5) * 0.98;
	return clamp(pow(cos(uv.x * 3.1415), 1.2) * pow(cos(uv.y * 3.1415), 1.2) * 50.0, 0.0, 1.0);
}

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 uv = i.uv.xy / 1;
	fixed2 sd_uv = scandistort(i.uv);
	fixed2 crt_uv = crt(sd_uv, 2.0);
	
	fixed4 color = (0,0,0,0);
	
	//fixed rand_r = sin(_Time.y * 3.0 + sin(_Time.y)) * sin(_Time.y * 0.2);
	//fixed rand_g = clamp(sin(_Time.y * 1.52 * i.uv.y + sin(_Time.y)) * sin(_Time.y* 1.2), 0.0, 1.0);
	fixed4 rand = tex2D(_SecondTex, fixed2(_Time.y * 0.01,_Time.y * 0.01));
	
	color.r = tex2D(_MainTex, crt(colorshift(sd_uv, 0.025, rand.r), 2.0)).r;
	color.g = tex2D(_MainTex, crt(colorshift(sd_uv, 0.01, rand.g), 2.0)).g;
	color.b = tex2D(_MainTex, crt(colorshift(sd_uv, 0.024, rand.b), 2.0)).b;
		
	fixed4 scanline_color = fixed4(scanline(crt_uv),scanline(crt_uv),scanline(crt_uv),scanline(crt_uv));
	fixed4 slowscan_color = fixed4(slowscan(crt_uv),scanline(crt_uv),scanline(crt_uv),scanline(crt_uv));
	
	return lerp(color, lerp(scanline_color, slowscan_color, 0.5), 0.05) * vignette(i.uv) * noise(i.uv);
		


	//return fixed4(vignette(i.uv));
	//fixed2 scan_dist = scandistort(i.uv);
	//return fixed4(scan_dist.x, scan_dist.y,0.0, 1.0);
}
}ENDCG
}
}
}

