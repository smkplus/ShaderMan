// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/301's Fire ShaderRemix 3"{
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
// I started working a bit on the colors of Relerp 2, ended up with something like this. :)
// Relerp 2 here: https://www.shadertoy.com/view/MtcGD7
// Relerp 1 here: https://www.shadertoy.com/view/llc3DM
// Original here: https://www.shadertoy.com/view/XsXXRN

fixed rand(fixed2 n) {
    return frac(sin(cos(dot(n, fixed2(12.9898,12.1414)))) * 83758.5453);
}

fixed noise(fixed2 n) {
    const fixed2 d = fixed2(0.0, 1.0);
    fixed2 b = floor(n), f = smoothstep(fixed2(0.0,0.0), fixed2(1.0,1.0), frac(n));
    return lerp(lerp(rand(b), rand(b + d.yx), f.x), lerp(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

fixed fbm(fixed2 n) {
    fixed total = 0.0, amplitude = 1.0;
    for (int i = 0; i <5; i++) {
        total += noise(n) * amplitude;
        n += n*1.7;
        amplitude  = mul(        amplitude ,0.47);
    }
    return total;
}

fixed4 frag(v2f i) : SV_Target{


    const fixed3 c1 = fixed3(0.5, 0.0, 0.1);
    const fixed3 c2 = fixed3(0.9, 0.1, 0.0);
    const fixed3 c3 = fixed3(0.2, 0.1, 0.7);
    const fixed3 c4 = fixed3(1.0, 0.9, 0.1);
    const fixed3 c5 = fixed3(0.1,0.1,0.1);
    const fixed3 c6 = fixed3(0.9,0.9,0.9);

    fixed2 speed = fixed2(0.1, 0.9);
    fixed shift = 1.327+sin(_Time.y*2.0)/2.4;
    fixed alpha = 1.0;
    
	fixed dist = 3.5-sin(_Time.y*0.4)/1.89;
    
    fixed2 uv = i.uv.xy / 1;
    fixed2 p = i.uv.xy * dist / 1;
    p += sin(p.yx*4.0+fixed2(.2,-.3)*_Time.y)*0.04;
    p += sin(p.yx*8.0+fixed2(.6,+.1)*_Time.y)*0.01;
    
    p.x -= _Time.y/1.1;
    fixed q = fbm(p - _Time.y * 0.3+1.0*sin(_Time.y+0.5)/2.0);
    fixed qb = fbm(p - _Time.y * 0.4+0.1*cos(_Time.y)/2.0);
    fixed q2 = fbm(p - _Time.y * 0.44 - 5.0*cos(_Time.y)/2.0) - 6.0;
    fixed q3 = fbm(p - _Time.y * 0.9 - 10.0*cos(_Time.y)/15.0)-4.0;
    fixed q4 = fbm(p - _Time.y * 1.4 - 20.0*sin(_Time.y)/14.0)+2.0;
    q = (q + qb - .4 * q2 -2.0*q3  + .6*q4)/3.8;
    fixed2 r = fixed2(fbm(p + q /2.0 + _Time.y * speed.x - p.x - p.y), fbm(p + q - _Time.y * speed.y));
    fixed3 c = lerp(c1, c2, fbm(p + r)) + lerp(c3, c4, r.x) - lerp(c5, c6, r.y);
    fixed3 color = fixed3(1.0/(pow(c+1.61,fixed3(4.0,4.0,4.0))) * cos(shift * i.uv.y / 1));
    
    color=fixed3(1.0,.2,.05)/(pow((r.y+r.y)* max(.0,p.y)+0.1, 4.0));;
    color += (tex2D(_MainTex,i.uv*0.6+fixed2(.5,0.5)));
    color = color/(1.0+max(fixed3(0,0,0),color));
    return fixed4(color.x, color.y, color.z, alpha);

}ENDCG
}
}
}

