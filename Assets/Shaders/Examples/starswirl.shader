// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderToyConverter/starswirl"{
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
// srtuss, 2014



fixed tri(fixed x)
{
	return abs(frac(x) * 2.0 - 1.0);
}

fixed dt(fixed2 uv, fixed t)
{
	fixed2 p = fmod(uv * 10.0, 2.0) - 1.0;
	fixed v = 1.0 / (dot(p, p) + 0.01);
	p = fmod(uv * 11.0, 2.0) - 1.0;
	v += 0.5 / (dot(p, p) + 0.01);
	return v * (sin(uv.y * 2.0 + t * 8.0) + 1.5);
}

fixed fun(fixed2 uv, fixed a, fixed t)
{
	fixed beat = t * 178.0 / 4.0 / 60.0;
	fixed e = floor(beat) * 0.1 + 1.0;
	beat = frac(beat) * 16.0;
	fixed b1 = 1.0 - fmod(beat, 10.0) / 10.0;
	fixed b2 = fmod(beat, 8.0) / 8.0;
	b1 = exp(b1 * -1.0) * 0.1;
	b2 = exp(b2 * -4.0);
	e = floor(frac(sin(e * 272.0972) * 10802.5892) * 4.0) + 1.0;
	fixed l = length(uv);
	fixed xx = l - 0.5 + sin(fmod(l * 0.5 - beat / 16.0, 1.0) * 3.14159265359 * 2.0);
	a += exp(xx * xx * -10.0) * 0.05;
	fixed2 pp = fixed2(a * e + l * sin(t * 0.4) * 2.0, l);
	pp.y = exp(l * -2.0) * 10.0 + tri(pp.x) + t * 2.0 - b1 * 4.0;
	fixed v = pp.y;
	v = sin(v) + sin(v * 0.5) + sin(v * 3.0) * 0.2;
	v = frac(v) + b2 * 0.2;
	v += exp(l * -4.5);
	v += dt(pp * fixed2(0.5, 1.0), t) * 0.01;
	return v;
}

fixed4 frag(v2f i) : SV_Target{

{
	fixed t = _Time.y;
	fixed2 uv = i.uv.xy / 1 * 2.0 - 1.0;
	uv.x *= 0.7 * 1 / 1;
	fixed an = atan2( uv.x,uv.y) / 3.14159265359;
	fixed a = 0.02;
	fixed v =
		fun(uv, an, t + a * -3.) +
		fun(uv, an, t + a * -2.) * 6. +
		fun(uv, an, t + a * -1.) * 15. +
		fun(uv, an, t + a *  0.) * 20. +
		fun(uv, an, t + a *  1.) * 15. +
		fun(uv, an, t + a *  2.) * 6. +
		fun(uv, an, t + a *  3.);
	v /= 64.0;
	fixed3 col;
	col = clamp(col, fixed3(0.0,0.0,0.0), fixed3(1.0,1.0,1.0));
	col = pow(fixed3(v, v, v), fixed3(0.5, 2.0, 1.5) * 8.0) * 3.0;
	col = pow(col, fixed3(1.0 / 2.2,1.0 / 2.2,1.0 / 2.2));
	return fixed4(col, 1.0);
}
}ENDCG
}
}
}

