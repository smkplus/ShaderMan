// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/gravity field - 2"{
Properties{
_ThirdTex("ThirdTex", 2D) = "white"{}
_iMouse("iMouse", Vector) = (0,0,0,0)
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
sampler2D _ThirdTex;
float4 _iMouse;

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
#define POINTS 100  		 // number of stars

// --- GUI utils

fixed t;

bool keyToggle(int ascii) {
	return (tex2D(_ThirdTex,fixed2((.5+fixed(ascii))/256.,0.75)).x > 0.);
}


// --- math utils

fixed dist2(fixed2 P0, fixed2 P1) { fixed2 D=P1-P0; return dot(D,D); }

fixed hash (fixed i) { return 2.*frac(sin(i*7467.25)*1e5) - 1.; }
fixed2  hash2(fixed i) { return fixed2(hash(i),hash(i-.1)); }
fixed4  hash4(fixed i) { return fixed4(hash(i),hash(i-.1),hash(i-.3),hash(i+.1)); }
	


// === main ===================

// motion of stars
fixed2 P(fixed i) {
	fixed4 c = hash4(i);
	return fixed2(   cos(t*c.x-c.z)+.5*cos(2.765*t*c.y+c.w),
				 ( sin(t*c.y-c.w)+.5*sin(1.893*t*c.x+c.z) )/1.5	 );
}

// ---

fixed4 frag(v2f i) : SV_Target{

{
    t = _Time.y;
	fixed2 uv    = i.uv;
	fixed m = (_iMouse.z<=0.) ? .1*t/6.283 : .5*_iMouse.x/1;
	fixed my = (_iMouse.z<=0.) ? .5*pow(.5*(1.-cos(.1*t)),3.) : _iMouse.y/1;
	int MODE = int(fmod( (_iMouse.z<=0.) ? 100.*m : 6.*m ,3.));
	fixed fMODE = (1.-cos(6.283*m))/2.;

	const int R = 1;
	
	fixed v=0.; fixed2 V=fixed2(0.,0.);
	for (int i=1; i<POINTS; i++) { // sums stars
		fixed2 p = P(fixed(i));
		for (int y=-R; y<=R; y++)  // ghost echos in cycling universe
			for (int x=-R; x<=R; x++) {
				fixed2 d = p+2.*fixed2(fixed(x),fixed(y)) -uv;
				fixed r2 = dot(d,d);
//				r2 = clamp(r2,5e-2*my,1e3,1);
				V +=  d / r2;  // gravity force field
			}
		}
	
	v = length(V);
	v *= 1./(9.*fixed(POINTS));
	//v = clamp(v,0.,.1);
	
	v *= 2.+100.*fMODE;
	if (MODE==0) return  fixed4(.2*v,.2*v,.2*v,.2*v)+smoothstep(.05,.0,abs(v-5.*my))*fixed4(1,0,0,0);
	if (MODE==1) return  fixed4(.5+.5*sin(2.*v),.5+.5*sin(2.*v),.5+.5*sin(2.*v),.5+.5*sin(2.*v));
	 return  fixed4(sin(v),sin(v/2.),sin(v/4.),1.);


}
}ENDCG
}
}
}

