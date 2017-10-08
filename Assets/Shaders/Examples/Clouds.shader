// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Clouds"{
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
// ----------------------------------------------------------------------------------------
//	"Toon Cloud" by Antoine Clappier - March 2015
//
//	Licensed under:
//  A Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
//	http://creatifixedommons.org/licenses/by-nc-sa/4.0/
// ----------------------------------------------------------------------------------------

#define TAU 6.28318530718


const fixed3 BackColor	= fixed3(0.0, 0.4, 0.58);
const fixed3 CloudColor	= fixed3(0.18,0.70,0.87);


fixed Func(fixed pX)
{
	return 0.6*(0.5*sin(0.1*pX) + 0.5*sin(0.553*pX) + 0.7*sin(1.2*pX));
}


fixed FuncR(fixed pX)
{
	return 0.5 + 0.25*(1.0 + sin(fmod(40.0*pX, TAU)));
}


fixed Layer(fixed2 pQ, fixed pT)
{
	fixed2 Qt = 3.5*pQ;
	pT *= 0.5;
	Qt.x += pT;

	fixed Xi = floor(Qt.x);
	fixed Xf = Qt.x - Xi -0.5;

	fixed2 C;
	fixed Yi;
	fixed D = 1.0 - step(Qt.y,  Func(Qt.x));

	// Disk:
	Yi = Func(Xi + 0.5);
	C = fixed2(Xf, Qt.y - Yi ); 
	D =  min(D, length(C) - FuncR(Xi+ pT/80.0));

	// Previous disk:
	Yi = Func(Xi+1.0 + 0.5);
	C = fixed2(Xf-1.0, Qt.y - Yi ); 
	D =  min(D, length(C) - FuncR(Xi+1.0+ pT/80.0));

	// Next Disk:
	Yi = Func(Xi-1.0 + 0.5);
	C = fixed2(Xf+1.0, Qt.y - Yi ); 
	D =  min(D, length(C) - FuncR(Xi-1.0+ pT/80.0));

	return min(1.0, D);
}



fixed4 frag(v2f i) : SV_Target{

{
	// Setup:
	fixed2 UV = 2.0*(i.uv.xy - 1/2.0) / min(1, 1);	
	
	// Render:
	fixed3 Color= BackColor;

	[unroll(100)]
for(fixed J=0.0; J<=1.0; J+=0.2)
	{
		// Cloud Layer: 
		fixed Lt =  _Time.y*(0.5  + 2.0*J)*(1.0 + 0.1*sin(226.0*J)) + 17.0*J;
		fixed2 Lp = fixed2(0.0, 0.3+1.5*( J - 0.5));
		fixed L = Layer(UV + Lp, Lt);

		// Blur and color:
		fixed Blur = 4.0*(0.5*abs(2.0 - 5.0*J))/(11.0 - 5.0*J);

		fixed V = lerp( 0.0, 1.0, 1.0 - smoothstep( 0.0, 0.01 +0.2*Blur, L ) );
		fixed3 Lc=  lerp( CloudColor, fixed3(1.0,1.0,1.0), J);

		Color =lerp(Color, Lc,  V);
	}

	return  fixed4(Color, 1.0) + fixed4(0,0.5,0.5,0);
}



}ENDCG
}
}
}

