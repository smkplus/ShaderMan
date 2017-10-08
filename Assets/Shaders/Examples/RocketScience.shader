// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/RocketScience"{
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
/*by musk License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.*/

//#define EXHAUST_LIGHT

#define time (_Time.y+99.0)
#define pi 3.14159265359

void angularRepeat(const fixed a, inout fixed2 v)
{
    fixed an = atan2(v.x,v.y);
    fixed len = length(v);
    an = fmod(an+a*.5,a)-a*.5;
    v = fixed2(cos(an),sin(an))*len;
}


void angularRepeat(const fixed a, const fixed offset, inout fixed2 v)
{
    fixed an = atan2(v.x,v.y);
    fixed len = length(v);
    an = fmod(an+a*.5,a)-a*.5;
    an+=offset;
    v = fixed2(cos(an),sin(an))*len;
}

fixed mBox(fixed3 p, fixed3 b)
{
	return max(max(abs(p.x)-b.x,abs(p.y)-b.y),abs(p.z)-b.z);
}

fixed mSphere(fixed3 p, fixed r)
{
    return length(p)-r;
}


fixed2 frot(const fixed a, in fixed2 v)
{
    fixed cs = cos(a), ss = sin(a);
    fixed2 u = v;
    v.x = u.x*cs + u.y*ss;
    v.y = u.x*-ss+ u.y*cs;
    return v;
}

void rotate(const fixed a, inout fixed2 v)
{
    fixed cs = cos(a), ss = sin(a);
    fixed2 u = v;
    v.x = u.x*cs + u.y*ss;
    v.y = u.x*-ss+ u.y*cs;
}

#define rocketRotation (sin(time)*.1)

fixed dfRocketBody(fixed3 p)
{
    rotate(rocketRotation,p.yz);
    
    fixed3 p2 = p;
    fixed3 pWindow = p;
    
    angularRepeat(pi*.25,p2.zy);
    fixed d = p2.z;
    d = max(d, frot(pi*-.125, p2.xz+fixed2(-.7,0)).y);
    d = max(d, frot(pi*-.25*.75, p2.xz+fixed2(-0.95,0)).y);
    d = max(d, frot(pi*-.125*.5, p2.xz+fixed2(-0.4,0)).y);
    d = max(d, frot(pi*.125*.25, p2.xz+fixed2(+0.2,0)).y);
    d = max(d, frot(pi*.125*.8, p2.xz+fixed2(.55,0)).y);
    d = max(d,-.8-p.x);
    d -= .5;
    
    fixed3 pThruster = p2;
    pThruster -= fixed3(-1.46,.0,.0);
    rotate(pi*-.2,pThruster.xz);
    d = min(d,mBox(pThruster,fixed3(.1,.4,.27)));
    d = min(d,mBox(pThruster-fixed3(-.09,.0,.0),fixed3(.1,.3,.07)));
    
    
    pWindow -= fixed3(.1,.0,.0);
    angularRepeat(pi*.25,pWindow.xy);
    pWindow -= fixed3(.17,.0,.0);
    d = min(d,mBox(pWindow,fixed3(.03,.2,.55)));
    
  	return d;
}

fixed dfRocketFins(fixed3 p)
{
    rotate(rocketRotation,p.yz);
    
    fixed3 pFins = p;
    angularRepeat(pi*.5,pFins.zy);
    pFins -= fixed3(-1.0+cos(p.x+.2)*.5,.0,.0);
    rotate(pi*.25,pFins.xz);
    fixed scale = 1.0-pFins.z*.5;
    fixed d =mBox(pFins,fixed3(.17,.03,3.0)*scale)*.5;
    return d;
}

fixed dfRocket(fixed3 p)
{
    fixed proxy = mBox(p,fixed3(2.5,.8,.8));
    if (proxy>1.0)
    	return proxy;
    return min(dfRocketBody(p),dfRocketFins(p));
}

fixed dfTrailPart(fixed3 p, fixed t)
{
    fixed3 pm = p;
    pm.x = fmod(p.x+1.0+t,2.0)-1.0;
    fixed index = p.x-pm.x;
    
    fixed rpos =(-1.7-index);
    
    
    fixed i2 = rpos;
    
    fixed rs = .5;
    
    fixed rtime1 = (t*.32 + i2*0.2)*rs;
	fixed rtime2 = (t*.47 + i2*0.3)*rs;
	fixed rtime3 = (t*.53 + i2*0.1)*rs;
	fixed3x3 rot = fixed3x3(cos(rtime1),0,sin(rtime1),0,1,0,-sin(rtime1),0,cos(rtime1))*
    fixed3x3(cos(rtime2),sin(rtime2),.0,-sin(rtime2),cos(rtime2),.0,0,0,1)*
    fixed3x3(1,0,0,0,cos(rtime3),sin(rtime3),0,-sin(rtime3),cos(rtime3));
    
    //p -= fixed3(-2.0,.0,.0);
    fixed size = .6-.5/(1.0+rpos);
    size = min(size,.6-.5/(17.0-rpos));
    size = max(size,.0);
    return mBox(mul(pm,rot),fixed3(size,size,size));
}

fixed dfTrail(fixed3 p)
{
    fixed clip = max(p.x+1.7, -1.7-16.0-p.x);
    fixed proxy = max(abs(p.y)-1.0, abs(p.z)-1.0);
    fixed proxy2 = max(clip,proxy);
    if (proxy2>0.5) return proxy2;
    
    fixed d = 999.0;
    for (int i=0; i<3; i++)
    {
        d=min(d,dfTrailPart(p,time*6.0+fixed(i)*21.33));
    }
        
    return max(d,clip);
}

fixed dfTerraHills(fixed3 p)
{
    p.y+=sin(p.x*.05)*2.0+1.0;
    fixed3 pm = p;
    pm.xz = fmod(pm.xz+fixed2(8.0,8.0),16.0)-fixed2(8.0,8.0);
    pm = abs(pm);
    return p.y*.8+3.0+pm.x*.1+pm.z*.1;
}

fixed dfTerra(fixed3 p)
{
    p.x+=time*4.0;
    fixed3 p2 = p;
    
    fixed height = (sin(p.x*.1)+sin(p.z*.1));
    rotate(.6,p2.xz);
    return max(dfTerraHills(p2),dfTerraHills(p))+height;
}

fixed df(fixed3 p)
{
    return min(min(dfRocket(p),dfTrail(p)),dfTerra(p));
}

fixed3 nf(fixed3 p)
{
    fixed2 e = fixed2(0,0.005);
    return normalize(fixed3(df(p+e.yxx),df(p+e.xyx),df(p+e.xxy)));
}

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 uv = i.uv;
    fixed2 mouse = (_iMouse.xy-_ScreenParams*.5) / _ScreenParams;
    
    fixed3 pos = fixed3(.1,.1,-5);
    //fixed3 dir = normalize(fixed3(uv,1.0));
    fixed3 dir = normalize(fixed3(uv,1.0));
    
    fixed rx = -mouse.x*8.0 + time*.04 -2.7;
    fixed ry = mouse.y*8.0 + time*.024+1.2;
     
    rotate(ry,pos.yz);
    rotate(ry,dir.yz);
    rotate(-rx,pos.xz);
    rotate(-rx,dir.xz);  
    rotate(.1,pos.xy);
    rotate(.1,dir.xy);  
    pos = mul(    pos,(pos.y*.25+1.5)*.6);
    
    fixed dist,tdist = .0;
    
    for (int i=0; i<100; i++)
    {
     	dist = df(pos);
       	pos += dist*dir;
        tdist+=dist;
        if (dist<0.000001||dist>20.0)break;
    }
    
    fixed3 light = normalize(fixed3(1,2,3));
    
    
    fixed3 skyColor = fixed3(.1,.3,.7)*.7;
    
    fixed3 ambientColor = skyColor*.07;
    fixed3 materialColor = fixed3(.5,.5,.5);
    fixed3 emissiveColor = fixed3(.0,.0,.0);
    
    fixed dTerra = dfTerra(pos);
    fixed dTrail = dfTrail(pos);
    fixed dRocketBody = dfRocketBody(pos);
    fixed dRocketFins = dfRocketFins(pos);
    fixed dRocket = min(dRocketBody, dRocketFins);
    fixed dRocketTrail = min(dRocket, dTrail);
    
    
    if (dTerra<dRocketTrail)
    {
        materialColor = fixed3(.3,.4,.1);
    }
    else if (dTrail<dRocket)
    {
    	materialColor = fixed3(.1,.1,.1);
        fixed tpos = (-pos.x-1.7)/16.0;
        emissiveColor = fixed3(1.9,.9,.2)*pow((1.0-tpos),8.0);
    }
    else 
    {
        //rocket
        ambientColor = lerp(skyColor,fixed3(.3,.1,.3)*.4,.5);
        if (dfRocketBody(pos)<dfRocketFins(pos))
        {
            if (pos.x<-.85 || pos.x>1.0){
                if (pos.x<-1.31)
                    materialColor = fixed3(.25,.25,.25);
                else
                    materialColor = fixed3(.9,.1,.1);
            }else
            {
                materialColor = fixed3(.8,.8,.8);
            }
        }
        else
            materialColor = fixed3(.9,.1,.1);
    }
    
    fixed value = 
        df(pos+light)+
        df(pos+light*.5)*2.0+
        df(pos+light*.25)*4.0+
        df(pos+light*.125)*8.0+
        df(pos+light*.06125)*16.0;
    
    value=value*.2+.04;
    value=min(value,1.0);
    value=max(.0,value);
    
    fixed3 normal = nf(pos);
   
    fixed3 ref = reflect(dir,nf(pos));
    //fixed ro = min(max(min(min(df(pos+ref),df(pos+ref*0.25)*4.0), df(pos+ref*.5)*2.0)*.5,.0),1.0);
   	fixed ro=1.0;
    
    fixed ao = df(pos+normal*.125)*8.0 +
        df(pos+normal*.5)*2.0 +
    	df(pos+normal*.25)*4.0 +
    	df(pos+normal*.06125)*16.0;
    
    ao=ao*.125+.5;
    
    fixed fres = pow((dot(dir,normal)*.5+.5),2.0);
    fixed3 color = fixed3(.0,.0,.0); 
    #ifdef EXHAUST_LIGHT
    fixed3 exhaustLightDir = fixed3(-1.9+sin(time*14.0)*.02,+cos(time*20.0)*.02,+sin(time*20.0)*.02)-pos;
    fixed exhaustLightDistance = length(exhaustLightDir);
    exhaustLightDir/=exhaustLightDistance;
    //compute exhaust direct light
    fixed exhaustLightDiffuse = max(.0,dot(normal,exhaustLightDir)*.8+.2)/(0.5+exhaustLightDistance*exhaustLightDistance);
    exhaustLightDiffuse = mul(    exhaustLightDiffuse,max(.0,min(df(pos+exhaustLightDir*.1)*10.0*.8+.2,df(pos+exhaustLightDir*.05)*20.0*.8+.2)*.8+.2)); //occlude exhaust light
    color += exhaustLightDiffuse*fixed3(1.9,.9,.2)*.7;
    #endif
    
   
    color +=(value*fixed3(dot(nf(pos),light)*.5+.5*.5+ambientColor*ao))*materialColor +fres*.25;
    color += emissiveColor;
   
    fixed3 cSky = skyColor + pow(dot(dir,light)*.5+.5,8.0);
    if (dist>1.0) color = cSky;
    else color = lerp(cSky,color,1.0/(1.0+tdist*.005));
    
    color = mul(    color,1.3); //boost
    color -= pow(length(uv),2.0)*.07;
    color = lerp(color,fixed3(length(color),length(color),length(color)),length(color)*.5);
    
	return  fixed4(pow(color,fixed3(1.0/2.2,1.0/2.2,1.0/2.2)),1.0);
    //return  fixed4(ro,ro,ro,ro);
    //return  fixed4(ao,ao,ao,ao);
    //return  fixed4(value,value,value,value);
}
}ENDCG
}
}
}

