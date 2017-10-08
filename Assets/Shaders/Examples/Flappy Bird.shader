// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Flappy Bird"{
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
// Flappy Bird (tribute), fragment shader by movAX13h, Feb.2014

fixed rand(fixed n)
{
    return frac(sin(n * 12.9898) * 43758.5453)-0.5;
}

void pipe(inout fixed3 col, fixed2 p, fixed h)
{
	fixed2 ap = abs(p);
	if (ap.y > h)
	{
		fixed dy = ap.y - h;
		if (dy < 60.0) ap.x *= 0.93;
		col = lerp(col, fixed3(0.322, 0.224, 0.290), step(ap.x, 65.0)); // outline
		if (dy > 60.0 || fmod(dy, 55.0) > 5.0) 
		{
			fixed gradient = 0.0;
			if (abs(dy - 57.5) > 7.5) gradient = max(0.0, 0.5*cos(floor((p.x+25.0)/5.0)*5.0*(0.026 - 0.006*step(dy, 10.0))));
			col = lerp(col, fixed3(0.322, 0.506, 0.129) + gradient, step(ap.x, 60.0));
		}
	}
}

// constant-array-index workaround ---
fixed slice(int id) 
{
	// flappy bird character (no worries, I have a tool)
	if (id == 0) return 2359296.0;
	if (id == 1) return 585.0;
	if (id == 2) return 4489216.0;
	if (id == 3) return 46674.0;
	if (id == 4) return 4751360.0;
	if (id == 5) return 2995812.0;
	if (id == 6) return 8945664.0;
	if (id == 7) return 3003172.0;
	if (id == 8) return 9469963.0;
	if (id == 9) return 7248164.0;
	if (id == 10) return 2359385.0;
	if (id == 11) return 10897481.0;
	if (id == 12) return 6554331.0;
	if (id == 13) return 9574107.0;
	if (id == 14) return 2134601.0;
	if (id == 15) return 9492189.0;
	if (id == 16) return 3894705.0;
	if (id == 17) return 9474632.0;
	if (id == 18) return 2396785.0;
	if (id == 19) return 9585152.0;
	if (id == 20) return 14380132.0;
	if (id == 21) return 8683521.0;
	if (id == 22) return 2398500.0;
	if (id == 23) return 1.0;
	if (id == 24) return 4681.0;	
	return 0.0;	
}

fixed3 color(int id)
{
	// flappy bird colors
	if (id == 0) return fixed3(0.0,0.0,0.0);
	if (id == 1) return fixed3(0.320,0.223,0.289);
	if (id == 2) return fixed3(0.996,0.449,0.063);
	if (id == 3) return fixed3(0.965,0.996,0.965);
	if (id == 4) return fixed3(0.996,0.223,0.000);
	if (id == 5) return fixed3(0.836,0.902,0.805);
	return fixed3(0.965,0.707,0.191);
}
// ---

int sprite(fixed2 p)
{
	// this time it's 3 bit/px (8 colors) and 8px/slice, 204px total
	int d = 0;
	p = floor(p);
	p.x = 16.0 - p.x;
	
	if (clamp(p.x, 0.0, 16.0) == p.x && clamp(p.y, 0.0, 11.0) == p.y)
	{
		fixed k = p.x + 17.0*p.y;
		fixed s = floor(k / 8.0);
		fixed n = slice(int(s));
		k = (k - s*8.0)*3.0;
		if (int(fmod(n/(pow(2.0,k)),2.0)) == 1) 		d += 1;
		if (int(fmod(n/(pow(2.0,k+1.0)),2.0)) == 1) 	d += 2;
		if (int(fmod(n/(pow(2.0,k+2.0)),2.0)) == 1) 	d += 4;
	}
	return d;
}

void hero(inout fixed3 col, fixed2 p, fixed angle)
{
	p = fixed2(p.x * cos(angle) - p.y * sin(angle), p.y * cos(angle) + p.x * sin(angle));
	int i = sprite(p*0.2);
	col = lerp(col, color(i), min(1.0, fixed(i)));
}

void ground(inout fixed3 col, fixed2 p)
{
	p = floor(p);
	if (p.y > -280.0) return;
	if (p.y < -285.0) col = color(1);
	if (p.y < -290.0) col = fixed3(0.902, 1.000, 0.549);
	if (p.y < -295.0) col = lerp(fixed3(0.612, 0.906, 0.353), fixed3(0.451, 0.745, 0.192), step(fmod(p.x-floor(p.y/5.0)*5.0, 60.0), 30.0));
	if (p.y < -325.0) col = fixed3(0.322, 0.506, 0.129);
	if (p.y < -330.0) col = fixed3(0.839, 0.667, 0.290);
	if (p.y < -335.0) col = fixed3(0.871, 0.843, 0.580);
}

void sky(inout fixed3 col, fixed2 p)
{
	col = lerp(col, fixed3(1.0,1.0,1.0), 0.3*sin(p.y*0.01));
}

fixed hAt(fixed i)
{
	return 250.0*rand(i*1.232157);
}

fixed4 frag(v2f i) : SV_Target{

{
	fixed s = 2000.0/1;
	fixed2 p = max(1.6666667, s)*(i.uv.xy - 1 * 0.5);
	fixed dx = _Time.y * 320.0;
	p.x += dx;
	
	fixed3 col = fixed3(0.322, 0.745, 0.808);
	sky(col, fixed2(0.0, -100.0)-p);
	
	pipe(col, fixed2(fmod(p.x, 400.0)-200.0, p.y + hAt(floor(p.x / 400.0)) - 80.0), 110.0);
	
	fixed hx = dx - 200.0; // hero x
	fixed sx = hx - 300.0; // sample x
	fixed i = floor(sx/400.0); // instance
	fixed ch = hAt(i); // current height
	fixed nh = hAt(i+1.0); // next height
	fixed bh = abs(60.0*sin(iChannelTime[0]*6.0)); // bounce height
	fixed hy = bh - lerp(ch, nh, min(1.0, fmod(sx, 400.0)*0.005)) + 80.0; // hero y
	fixed angle = -min(0.1, 0.002*(bh));
	hero(col, fixed2(hx, hy)-p, angle);
	
	ground(col, p);
	
	return  fixed4(col,1.0);
}

}ENDCG
}
}
}

