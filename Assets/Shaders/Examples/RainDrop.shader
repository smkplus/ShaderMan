Shader"Hidden/RainDrop"{
Properties{
_MainTex("MainTex", 2D) = "white"{}
_SecondTex("SecondTex", 2D) = "white"{}
_Intensity("Intensity",Range(0,5)) = 1
}

SubShader{
Cull Off 
ZWrite Off 
ZTest Always
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
sampler2D _SecondTex;
float _Intensity;

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
	fixed2 u = i.uv,
         n = tex2D(_SecondTex, u).rg; 
    
    float4 f = tex2D(_MainTex, u);

    for (fixed r = 4 ; r > 0. ; r--) {
        fixed2 x = _ScreenParams.xy * r * .015,  
             p = 6.28 * u * x + (n - .5) * 2.,
             s = sin(p);

        fixed4 d = tex2D(_SecondTex, round(u * x - 0.25) / x);

        fixed t = (s.x+s.y) * max(0., 1. - frac(_Intensity *_Time.y * (d.b + .1) + d.g) * 2.);;

        if (d.r < (5.-r)*.08 && t > .5) {
            fixed3 v = normalize(-fixed3(cos(p), lerp(.2, 2., t-.5)));

            return tex2D(_MainTex, u - v.xy * .3);
        }
    }
    return f;
}


}ENDCG
}
}
}

