// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderToyConverter/TotalNoob"{
Properties{
_MainTex("MainTex", 2D) = "white"{}

}
SubShader{
Pass{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
struct appdata{
float4 vertex : POSITION;
float2 uv : TEXCOORD0;
};
sampler2D _MainTex;
fixed4 fragColor;

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
fixed4 frag(v2f i) : SV_Target{

{
	fixed2 p = (2.0*i.uv.xy-1)/1;
    fixed tau = 3.1415926535*2.0;
    fixed a = atan2(p.y,p.x);
    fixed r = length(p)*0.75;
    fixed2 uv = fixed2(a/tau,r);
	
	//get the color
	fixed xCol = (uv.x - (_Time.y / 3.0)) * 3.0;
	xCol = fmod(xCol, 3.0);
	fixed3 horColour = fixed3(0.25, 0.25, 0.25);
	
	if (xCol < 1.0) {
		
		horColour.r += 1.0 - xCol;
		horColour.g += xCol;
	}
	else if (xCol < 2.0) {
		
		xCol -= 1.0;
		horColour.g += 1.0 - xCol;
		horColour.b += xCol;
	}
	else {
		
		xCol -= 2.0;
		horColour.b += 1.0 - xCol;
		horColour.r += xCol;
	}

	// draw color beam
	uv = (2.0 * uv) - 1.0;
	fixed beamWidth = (0.7+0.5*cos(uv.x*10.0*tau*0.15*clamp(floor(5.0 + 10.0*cos(_Time.y)), 0.0, 10.0))) * abs(1.0 / (30.0 * uv.y));
	fixed3 horBeam = fixed3(beamWidth,beamWidth,beamWidth);
	return fixed4((( horBeam) * horColour), 1.0);
}
}ENDCG
}
}
}

