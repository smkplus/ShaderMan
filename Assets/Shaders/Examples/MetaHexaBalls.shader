// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/MetaHexaBalls"{
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

#define occlusion_enabled
#define occlusion_quality 4
//#define occlusion_preview

#define noise_use_smoothstep

#define light_color fixed3(0.1,0.4,0.6)
#define light_direction normalize(fixed3(.2,1.0,-0.2))
#define light_speed_fmodifier 1.0

#define object_color fixed3(0.9,0.1,0.1)
#define object_count 9
#define object_speed_fmodifier 1.0

#define render_steps 33

fixed hash(fixed x)
{
	return frac(sin(x*.0127863)*17143.321);
}

fixed hash(fixed2 x)
{
	return frac(cos(dot(x.xy,fixed2(2.31,53.21))*124.123)*412.0); 
}

fixed3 cc(fixed3 color, fixed factor,fixed factor2) //a wierd color fmodifier
{
	fixed w = color.x+color.y+color.z;
	return lerp(color,fixed3(w,w,w)*factor,w*factor2);
}

fixed hashlerp(fixed x0, fixed x1, fixed interp)
{
	x0 = hash(x0);
	x1 = hash(x1);
	#ifdef noise_use_smoothstep
	interp = smoothstep(0.0,1.0,interp);
	#endif
	return lerp(x0,x1,interp);
}

fixed noise(fixed p) // 1D noise
{
	fixed pm = fmod(p,1.0);
	fixed pd = p-pm;
	return hashlerp(pd,pd+1.0,pm);
}

fixed3 rotate_y(fixed3 v, fixed angle)
{
	fixed ca = cos(angle); fixed sa = sin(angle);
	return mul(v,fixed3x3(
		+ca, +.0, -sa,
		+.0,+1.0, +.0,
		+sa, +.0, +ca));
}

fixed3 rotate_x(fixed3 v, fixed angle)
{
	fixed ca = cos(angle); fixed sa = sin(angle);
	return mul(v,fixed3x3(
		+1.0, +.0, +.0,
		+.0, +ca, -sa,
		+.0, +sa, +ca));
}

fixed max3(fixed a, fixed b, fixed c)//returns the maximum of 3 values
{
	return max(a,max(b,c));
}

fixed3 bpos[object_count];//position for each metaball

fixed dist(fixed3 p)//distance function
{
	fixed d=1024.0;
	fixed nd;
	for (int i=0 ;i<object_count; i++)
	{
		fixed3 np = p+bpos[i];
		fixed shape0 = max3(abs(np.x),abs(np.y),abs(np.z))-1.0;
		fixed shape1 = length(np)-1.0;
		nd = shape0+(shape1-shape0)*2.0;
		d = lerp(d,nd,smoothstep(-1.0,+1.0,d-nd));
	}
	return d;
}

fixed3 normal(fixed3 p,fixed e) //returns the normal, uses the distance function
{
	fixed d=dist(p);
	return normalize(fixed3(dist(p+fixed3(e,0,0))-d,dist(p+fixed3(0,e,0))-d,dist(p+fixed3(0,0,e))-d));
}

fixed3 light = light_direction; //global variable that holds light direction

fixed3 background(fixed3 d)//render background
{
	fixed t=_Time.y*0.5*light_speed_fmodifier;
	fixed qq = dot(d,light)*.5+.5;
	fixed bgl = qq;
	fixed q = (bgl+noise(bgl*6.0+t)*.85+noise(bgl*12.0+t)*.85);
	q+= pow(qq,32.0)*2.0;
	fixed3 sky = fixed3(0.1,0.4,0.6)*q;
	return sky;
}

fixed occlusion(fixed3 p, fixed3 d)//returns how much a point is visible from a given direction
{
	fixed occ = 1.0;
	p=p+d;
	for (int i=0; i<occlusion_quality; i++)
	{
		fixed dd = dist(p);
		p+=d*dd;
		occ = min(occ,dd);
	}
	return max(.0,occ);
}

fixed3 object_material(fixed3 p, fixed3 d)
{
	fixed3 color = normalize(object_color*light_color);
	fixed3 n = normal(p,0.1);
	fixed3 r = reflect(d,n);	
	
	fixed reflectance = dot(d,r)*.5+.5;reflectance=pow(reflectance,2.0);
	fixed diffuse = dot(light,n)*.5+.5; diffuse = max(.0,diffuse);
	
	#ifdef occlusion_enabled
		fixed oa = occlusion(p,n)*.4+.6;
		fixed od = occlusion(p,light)*.95+.05;
		fixed os = occlusion(p,r)*.95+.05;
	#else
		fixed oa=1.0;
		fixed ob=1.0;
		fixed oc=1.0;
	#endif
	
	#ifndef occlusion_preview
		color = 
		color*oa*.2 + //ambient
		color*diffuse*od*.7 + //diffuse
		background(r)*os*reflectance*.7; //reflection
	#else
		color=fixed3((oa+od+os)*.3);
	#endif
	
	return color;
}

#define offset1 4.7
#define offset2 4.6

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 uv = i.uv.xy / 1 - 0.5;
	i.uv.x  = mul(	i.uv.x ,1/1); //fix aspect ratio
	fixed3 mouse = fixed3(_iMouse.xy/1 - 0.5,_iMouse.z-.5);
	
	fixed t = _Time.y*.5*object_speed_fmodifier + 2.0;
	
	for (int i=0 ;i<object_count; i++) //position for each metaball
	{
		bpos[i] = 1.3*fixed3(
			sin(t*0.967+fixed(i)*42.0),
			sin(t*.423+fixed(i)*152.0),
			sin(t*.76321+fixed(i)));
	}
	
	//setup the camera
	fixed3 p = fixed3(.0,0.0,-4.0);
	p = rotate_x(p,mouse.y*9.0+offset1);
	p = rotate_y(p,mouse.x*9.0+offset2);
	fixed3 d = fixed3(uv,1.0);
	d.z -= length(d)*.5; //lens distort
	d = normalize(d);
	d = rotate_x(d,mouse.y*9.0+offset1);
	d = rotate_y(d,mouse.x*9.0+offset2);
	
	//and action!
	fixed dd;
	fixed3 color;
	for (int i=0; i<render_steps; i++) //raymarch
	{
		dd = dist(p);
		p+=d*dd*.7;
		if (dd<.04 || dd>4.0) break;
	}
	
	if (dd<0.5) //close enough
		color = object_material(p,d);
	else
		color = background(d);
	
	//post procesing
	color  = mul(	color ,.85);
	color = lerp(color,color*color,0.3);
	color -= hash(color.xy+uv.xy)*.015;
	color -= length(uv)*.1;
	color =cc(color,.5,.6);
	return fixed4(color,1.0);
}
}ENDCG
}
}
}

