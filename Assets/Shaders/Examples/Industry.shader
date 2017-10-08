// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Industry"{
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
// by srtuss, 2013
// a little expression of my love for complex machines and stuff
// was going for some cartoonish 2d look
// still could need some optimisation

// * improved gears
// * improved camera movement

fixed hash(fixed x)
{
	return frac(sin(x) * 43758.5453);
}

fixed2 hash(fixed2 p)
{
    p = fixed2(dot(p, fixed2(127.1, 311.7)), dot(p, fixed2(269.5, 183.3)));
	return frac(sin(p) * 43758.5453);
}

// simulates a resonant lowpass filter
fixed mechstep(fixed x, fixed f, fixed r)
{
	fixed fr = frac(x);
	fixed fl = floor(x);
	return fl + pow(fr, 0.5) + sin(fr * f) * exp(-fr * 3.5) * r;
}

// voronoi cell id noise
fixed3 voronoi(in fixed2 x)
{
	fixed2 n = floor(x);
	fixed2 f = frac(x);

	fixed2 mg, mr;
	
	fixed md = 8.0;
	[unroll(100)]
for(int j = -1; j <= 1; j ++)
	{
		[unroll(100)]
for(int i = -1; i <= 1; i ++)
		{
			fixed2 g = fixed2(fixed(i),fixed(j));
			fixed2 o = hash(n + g);
			fixed2 r = g + o - f;
			fixed d = max(abs(r.x), abs(r.y));
			
			if(d < md)
			{
				md = d;
				mr = r;
				mg = g;
			}
		}
	}
	
	return fixed3(n + mg, mr.x);
}

fixed2 rotate(fixed2 p, fixed a)
{
	return fixed2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}

fixed stepfunc(fixed a)
{
	return step(a, 0.0);
}

fixed fan(fixed2 p, fixed2 at, fixed ang)
{
	p -= at;
	p *= 3.0;
	
	fixed v = 0.0, w, a;
	fixed le = length(p);
	
	v = le - 1.0;
	
	if(v > 0.0)
		return 0.0;
	
	a = sin(atan2( p.x,p.y) * 3.0 + ang);
	
	w = le - 0.05;
	v = max(v, -(w + a * 0.8));
	
	w = le - 0.15;
	v = max(v, -w);
	
	return stepfunc(v);
}

fixed gear(fixed2 p, fixed2 at, fixed teeth, fixed size, fixed ang)
{
	p -= at;
	fixed v = 0.0, w;
	fixed le = length(p);
	
	w = le - 0.3 * size;
	v = w;
	
	w = sin(atan2( p.x,p.y) * teeth + ang);
	w = smoothstep(-0.7, 0.7, w) * 0.1;
	v = min(v, v - w);
	
	w = le - 0.05;
	v = max(v, -w);
	
	return stepfunc(v);
}

fixed car(fixed2 p, fixed2 at)
{
	p -= at;
	fixed v = 0.0, w;
	w = length(p + fixed2(-0.05, -0.31)) - 0.03;
	v = w;
	w = length(p + fixed2(0.05, -0.31)) - 0.03;
	v = min(v, w);
	
	fixed2 box = abs(p + fixed2(0.0, -0.3 - 0.07));
	w = max(box.x - 0.1, box.y - 0.05);
	v = min(v, w);
	return stepfunc(v);
}

fixed layerA(fixed2 p, fixed seed)
{
	fixed v = 0.0, w, a;
	
	fixed si = floor(p.y);
	fixed sr = hash(si + seed * 149.91);
	fixed2 sp = fixed2(p.x, fmod(p.y, 4.0));
	fixed strut = 0.0;
	strut += step(abs(sp.y), 0.3);
	strut += step(abs(sp.y - 0.2), 0.1);
	
	fixed st = _Time.y + sr;
	fixed ct = fmod(st * 3.0, 5.0 + sr) - 2.5;
	
	v = step(2.0, abs(voronoi(p + fixed2(0.35, seed * 194.9)).x));
	
	w = length(sp - fixed2(-2.0, 0.0)) - 0.8;
	v = min(v, 1.0 - step(w, 0.0));
	
	
	a = st;
	w = fan(sp, fixed2(2.5, 0.65), a * 40.0);
	v = min(v, 1.0 - w);
	
	
	return v;
}

fixed layerB(fixed2 p, fixed seed)
{
	fixed v = 0.0, w, a;
	
	fixed si = floor(p.y / 3.0) * 3.0;
	fixed2 sp = fixed2(p.x, fmod(p.y, 3.0));
	fixed sr = hash(si + seed * 149.91);
	sp.y -= sr * 2.0;
	
	fixed strut = 0.0;
	strut += step(abs(sp.y), 0.3);
	strut += step(abs(sp.y - 0.2), 0.1);
	
	fixed st = _Time.y + sr;
	
	fixed cs = 2.0;
	if(hash(sr) > 0.5)
		cs *= -1.0;
	fixed ct = fmod(st * cs, 5.0 + sr) - 2.5;

	
	v = step(2.0, abs(voronoi(p + fixed2(0.35, seed * 194.9)).x) + strut);
	
	w = length(sp - fixed2(-2.3, 0.6)) - 0.15;
	v = min(v, 1.0 - step(w, 0.0));
	w = length(sp - fixed2(2.3, 0.6)) - 0.15;
	v = min(v, 1.0 - step(w, 0.0));
	
	if(v > 0.0)
		return 1.0;
	
	
	w = car(sp, fixed2(ct, 0.0));
	v = w;
	
	if(hash(si + 81.0) > 0.5)
		a = mechstep(st * 2.0, 20.0, 0.4) * 3.0;
	else
		a = st * (sr - 0.5) * 30.0;
	w = gear(sp, fixed2(-2.0 + 4.0 * sr, 0.5), 8.0, 1.0, a);
	v = max(v, w);
	
	w = gear(sp, fixed2(-2.0 + 0.65 + 4.0 * sr, 0.35), 7.0, 0.8, -a);
	v = max(v, w);
	if(hash(si - 105.13) > 0.8)
	{
		w = gear(sp, fixed2(-2.0 + 0.65 + 4.0 * sr, 0.35), 7.0, 0.8, -a);
		v = max(v, w);
	}
	if(hash(si + 77.29) > 0.8)
	{
		w = gear(sp, fixed2(-2.0 - 0.55 + 4.0 * sr, 0.30), 5.0, 0.5, -a + 0.7);
		v = max(v, w);
	}
	
	return v;
}

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 uv = i.uv;
	uv = uv * 2.0 - 1.0;
	fixed2 p = uv;
	p.x *= 1 / 1;
	
	fixed t = _Time.y;
	
	fixed2 cam = fixed2(sin(t) * 0.2, t);
	
	// for future use
	/*fixed quake = exp(-frac(t) * 5.0) * 0.5;
	if(quake > 0.001)
	{
		cam.x += (hash(t) - 0.5) * quake;
		cam.y += (hash(t - 118.29) - 0.5) * quake;
	}*/
	
	p = rotate(p, sin(t) * 0.02);
	
	fixed2 o = fixed2(0.0, t);
	fixed v = 0.0, w;
	
	
	fixed z = 3.0 - sin(t * 0.7) * 0.1;
	[unroll(100)]
for(int i = 0; i < 5; i ++)
	{
		fixed f = 1.0;
		
		fixed zz = 0.3 + z;
		
		f = zz * 2.0 * 0.9;
		
		
		if(i == 3 || i == 1)
			w = layerA(fixed2(p.x, p.y) * f + cam, fixed(i));
		else
			w = layerB(fixed2(p.x, p.y) * f + cam, fixed(i));
		v = lerp(v, exp(-abs(zz) * 0.3 + 0.1), w);
		
		
		z -= 0.6;
	}
	
	
	
	
	v = 1.0 - v;// * pow(1.0 - abs(uv.x), 0.1);
	
	return  fixed4(v, v, v, 1.0);
}
}ENDCG
}
}
}

