// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/Clip"{
Properties{
_MainTex("MainTex", 2D) = "white"{}
_SecondTex("_SecondTex",2D) = "white"{}
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
fixed noise(fixed2 p)
{
    fixed sample = tex2D(_SecondTex,fixed2(1.,2.*cos(_Time.y))*_Time.y*8. + p*1.).x;
    sample  = mul(    sample ,sample);
    return sample;
}

fixed onOff(fixed a, fixed b, fixed c)
{
    return step(c, sin(_Time.y + a*cos(_Time.y*b)));
}

fixed ramp(fixed y, fixed start, fixed end)
{
    fixed inside = step(start,y) - step(end,y);
    fixed fact = (y-start)/(end-start)*inside;
    return (1.-fact) * inside;

}

fixed stripes(fixed2 uv)
{

    fixed noi = noise(uv*fixed2(0.5,1.) + fixed2(1.,3.));
    return ramp(fmod(uv.y*4. + _Time.y/2.+sin(_Time.y + sin(_Time.y*0.63)),1.),0.5,0.6)*noi;
}

fixed3 getVideo(fixed2 uv)
{
    fixed2 look = uv;
    fixed window = 1./(1.+20.*(look.y-fmod(_Time.y/4.,1.))*(look.y-fmod(_Time.y/4.,1.)));
    look.x = look.x + sin(look.y*10. + _Time.y)/50.*onOff(4.,4.,.3)*(1.+cos(_Time.y*80.))*window;
    fixed vShift = 0.4*onOff(2.,3.,.9)*(sin(_Time.y)*sin(_Time.y*20.) + 
                                         (0.5 + 0.1*sin(_Time.y*200.)*cos(_Time.y)));
    look.y = fmod(look.y + vShift, 1.);
    fixed3 video = fixed3(tex2D(_MainTex,look).xyz);
    return video;
}

fixed2 screenDistort(fixed2 uv)
{
    uv -= fixed2(.5,.5);
    uv = uv*1.2*(1./1.2+2.*uv.x*uv.x*uv.y*uv.y);
    uv += fixed2(.5,.5);
    return uv;
}

fixed4 frag(v2f i) : SV_Target{

{
    fixed2 uv = i.uv;
    uv = screenDistort(uv);
    fixed3 video = getVideo(uv);
    fixed vigAmt = 3.+.3*sin(_Time.y + 5.*cos(_Time.y*5.));
    fixed vignette = (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));

    video += stripes(uv);
    video += noise(uv*2.)/2.;
    video  = mul(    video ,vignette);
    video  = mul(    video ,(12.+fmod(uv.y*30.+_Time.y,1.))/13.);

    return  fixed4(video,1.0);
}
}ENDCG
}
}
}

