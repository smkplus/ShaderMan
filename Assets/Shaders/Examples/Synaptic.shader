// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/Synaptic"{
Properties{
_MainTex("MainTex", 2D) = "white"{}
_SecondTex("SecondTex", 2D) = "white"{}
iFrame("iFrame", Range(0,100)) = 1
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
sampler2D _SecondTex;
fixed iFrame;

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
//Velocity handling

const fixed initalSpeed = 10.;
#define time _Time.y

fixed3 hash3(fixed3 p)
{
    p = frac(p * fixed3(443.8975,397.2973, 491.1871));
    p += dot(p.zxy, p.yxz+19.1);
    return frac(fixed3(p.x * p.y, p.z*p.x, p.y*p.z))-0.5;
}

fixed3 update(in fixed3 vel, fixed3 pos, in fixed id)
{   
    vel.xyz = vel.xyz*.999 + (hash3(vel.xyz + time)*2.)*7.;
    
    fixed d = pow(length(pos)*1.2, 0.75);
    vel.xyz = lerp(vel.xyz, -pos*d, sin(-time*.55)*0.5+0.5);
    
    return vel;
}

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 q = i.uv.xy / 1;
    
    fixed4 col= fixed4(0,0,0,0);
    fixed2 w = 1./1;
    
    fixed3 pos = tex2D(_MainTex, fixed2(q.x,q.y)).xyz;
    fixed3 velo = tex2D(_MainTex, fixed2(q.x,q.y)).xyz;
    velo = update(velo, pos, q.x);
    
    if (i.uv.y < 30.)
    {
    	col.rgb = velo;
    }
    else
    {
        pos.rgb += velo*0.002;
        col.rgb = pos.rgb;
    }
	
    //Init
    if (iFrame < 10) 
    {
        if (i.uv.y < 30.)
        	col = ((tex2D(_SecondTex, q*1.9))-.5)*10.;
        else
        {
            col = ((tex2D(_SecondTex,i.uv)))*.5;
        }
    }
    
	return col;
}
}ENDCG
}
}
}

