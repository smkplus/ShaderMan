// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/SimpleProceduralSun"{
Properties{
_MainTex("MainTex", 2D) = "white"{}
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
uniform sampler2D  _MainTex;
uniform fixed4     fragColor;
uniform fixed      iChannelTime[4];// channel playback time (in seconds)
uniform fixed3     iChannelResolution[4];// channel resolution (in pixels)
uniform fixed4     iMouse;// mouse pixel coords. xy: current (if MLB down), zw: click
uniform fixed4     iDate;// (year, month, day, time in seconds)
uniform fixed      iSampleRate;// sound sample rate (i.e., 44100)
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
#define urx 1920U
#define ury 1080U
#define pi 3.141592654
//sun
#define sunCenter fixed3(0.0,0.0,0.0)
#define sunRad .25
#define fracalIterations 4
#define fracalScale 10.0
#define fracalFreq 2.0
#define sunBrightness .87
#define redMean .55
#define greenMean .35
#define blueMean .0
//corona
#define coronaCol fixed3(.8, .5, .1)
#define coronaDropOff 15.0

fixed iSphere(fixed3 ray, fixed3 dir, fixed3 center, fixed radius)
{
	fixed3 rc = ray-center;
	fixed c = dot(rc, rc) - (radius*radius);
	fixed b = dot(dir, rc);
	fixed d = b*b - c;
	fixed t = -b - sqrt(abs(d));
	fixed st = step(0.0, min(t,d));
	return lerp(-1.0, t, st);
}


fixed4 iPlane(fixed3 ro, fixed3 rd, fixed3 po, fixed3 pd){
    fixed d = dot(po - ro, pd) / dot(rd, pd);
    return fixed4(d * rd + ro, d);
}

fixed3 r(fixed3 v, fixed2 r){//rodolphito's rotation
    fixed4 t = sin(fixed4(r, r + 1.5707963268));
    fixed g = dot(v.yz, t.yw);
    return fixed3(v.x * t.z - g * t.x,
                v.y * t.w - v.z * t.y,
                v.x * t.x + g * t.z);
}

fixed hash(uint n){//Hugo Elias's hash
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return 1.0 - fixed(n & 0x7fffffffU)/fixed(0x7fffffff);
}

fixed hashNoise3(fixed3 x){
    fixed3 fr = frac(x);
    fr = smoothstep(0.0, 1.0, fr);
    fixed3 p = fixed3(x);
    return lerp(lerp(lerp(hash(p.x + ury * p.y + urx * p.z), 
                        hash(p.x + 1U + ury * p.y + urx * p.z),fr.x),
                   lerp(hash(p.x + ury * (p.y + 1U) + urx * p.z), 
                        hash(p.x + 1U + ury * (p.y + 1U) + urx * p.z),fr.x),fr.y),
               lerp(lerp(hash(p.x + ury * p.y + urx * (p.z + 1U)), 
                        hash(p.x + 1U + ury * p.y + urx * (p.z + 1U)),fr.x),
                   lerp(hash(p.x + ury * (p.y + 1U) + urx * (p.z + 1U)), 
                        hash(p.x + 1U + ury * (p.y + 1U) + urx * (p.z + 1U)),fr.x),fr.y),fr.z);
}

fixed fracalNoise3(fixed3 pos){
    fixed acc = 0.0;
    fixed scale = 1.0;
    [unroll(100)]
for(int n = 0; n < fracalIterations; n++){
        acc += hashNoise3(scale * pos) / scale;
        scale  = mul(        scale ,2.0);
    }
    return acc / 2.0;
}

fixed3 colorSun(fixed x){
    fixed3 result = fixed3(0.0,0.0,0.0);
    result.x += exp(-(x - redMean) * (x - redMean) * 16.0);
    result.y += exp(-(x - greenMean) * (x - greenMean) * 16.0);
    //result.z += exp(-(x - blueMean) * (x - blueMean) * 16.0);
    if(result.y > .5) result.x += result.y;
    return result;
}

fixed3 render(fixed3 rd, fixed3 ro){
    fixed d = iSphere(ro, rd, sunCenter, sunRad);
    if(d > 0.0){
        fixed3 n = normalize(d * rd + ro - sunCenter);
        fixed f = fracalNoise3(fracalScale * n + (.3 + .2 * sin(fracalFreq * _Time.y)
                                      + fracalFreq * fixed3(_Time.y + 13.0,_Time.y + 13.0,_Time.y + 13.0)));
        fixed3 col = colorSun(f);
        return col + dot(rd, n) * (1.0 - sunBrightness);
    }
    else{
        fixed4 intersect = iPlane(ro, rd, sunCenter, normalize(sunCenter - ro));
        return pow(coronaCol, coronaDropOff * (length(intersect.xyz - sunCenter) - sunRad));
    }
}

fixed4 frag(v2f i) : SV_Target{

    fixed2 xy = (2.0 * i.uv - 1) / 1;
    fixed3 cam = fixed3(0.0, 0.0, -1.0);
    fixed3 dir = normalize(fixed3(xy, 2.5));
    fixed2 m = (2.0 * _iMouse.xy - 1) / 1;
    m  = mul(    m ,2.0);
    dir = r(dir, m);
    cam = r(cam, m);
    fragColor.xyz = render(dir, cam);

	return fragColor;
}ENDCG
}
}
}

