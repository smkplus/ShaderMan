// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Simple Eye Blower"{
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
fixed4 frag(v2f i) : SV_Target{

{
	// Fragment coords relative to the center of viewport, in a 1 by 1 coords sytem.
	fixed2 uv = i.uv;

	// But I want circles, not ovales, so I adjust y with x resolution.
	fixed2 homoCoords = fixed2( uv.x, 2.0* uv.y/1 );

	// Sin of distance from a moving origin to current fragment will give us..... 
	fixed2 movingOrigin1 = fixed2(sin(_Time.y*.7),+sin(_Time.y*1.7));
	
	// ...numerous... 
	fixed frequencyBoost = 50.0; 
	
	// ... awesome concentric circles.
	fixed wavePoint1 = sin(distance(movingOrigin1, homoCoords)*frequencyBoost);
	
	// I want sharp circles, not blurry ones.
	fixed blackOrWhite1 = sign(wavePoint1);
	
	// That was cool ! Let's do it again ! (No, I dont want to write a function today, I'm tired).
	fixed2 movingOrigin2 = fixed2(-cos(_Time.y*2.0),-sin(_Time.y*3.0));
	fixed wavePoint2 = sin(distance(movingOrigin2, homoCoords)*frequencyBoost);
	fixed blackOrWhite2 = sign(wavePoint2);
	
	// I love pink.
	fixed3 pink = fixed3(1.0, .5, .9 );
	fixed3 darkPink = fixed3(0.5, 0.1, 0.3);
	
	// XOR virtual machine.
	fixed composite = blackOrWhite1 * blackOrWhite2;
	
	// Pinkization
	return  fixed4(max( pink * composite, darkPink), 1.0);
}
}ENDCG
}
}
}

