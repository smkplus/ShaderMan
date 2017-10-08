// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/Lanterns"{
Properties{
_MainTex("MainTex", 2D) = "white"{}
_SecondTex("SecondTex", 2D) = "white"{}
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
sampler2D _SecondTex;
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
// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Another example of using a 2D grid to accelerate raytracing (of procedural content in 
// this case). The lighting is shadowless this time, that's why it's fast. The ambient 
// occlusion is fixed-procedural, fixed-analytical.
	
// For information on analytical ambient occlusion from spheres, see here:
// http://www.iquilezles.org/www/articles/sphereao/sphereao.htm

#define VIS_SAMPLES 6

fixed hash1( fixed n ) { return frac(43758.5453123*sin(n)); }
fixed hash1( fixed2  n ) { return frac(43758.5453123*sin(dot(n,fixed2(1.0,113.0)))); }
fixed2  hash2( fixed n ) { return frac(43758.5453123*sin(fixed2(n,n+1.0))); }
fixed3  hash3( fixed2  n ) { return frac(43758.5453123*sin(dot(n,fixed2(1.0,113.0))+fixed3(0.0,1.0,2.0))); }
fixed4  hash4( fixed2  n ) { return frac(43758.5453123*sin(dot(n,fixed2(1.0,113.0))+fixed4(0.0,1.0,2.0,3.0))); }

//------------------------------------------------------------

fixed4 makeSphere( fixed2 pos )
{
	fixed3  rr = hash3(pos);
	fixed ha = 0.2 + 1.3*rr.z;
	fixed2  oo = 0.5 + 0.3*(-1.0 + 2.0*rr.xy);
	fixed3  ce = fixed3( pos.x+oo.x, ha, pos.y+oo.y );
	fixed ra = (0.5+0.5*rr.z)*min( min(oo.x,1.0-oo.x), min(oo.y,1.0-oo.y) );
ra  = mul(ra ,0.85+0.15*sin( 1.5*_Time.y + hash1(pos)*130.0 ));
	
	ce.y += 0.3*smoothstep( 0.995, 0.996, sin(0.015*_Time.y+100.0*hash1(hash1(pos))) );
	
	return fixed4( ce, ra );
}

fixed3 palette( fixed id )
{
	return 0.5 + 0.5*sin( 2.0*id + 1.3 + fixed3(0.0,1.0,2.0) );
}

fixed3 makeColor( in fixed2 p )
{
    fixed id  = hash1( p );
    return palette( id );
}

fixed3 makeEmission( in fixed2 p )
{
    fixed id  = hash1( p );
    fixed3 mate =palette( id );
	return mate * smoothstep( 0.995, 0.998, sin(0.015*_Time.y+100.0*hash1(id)) );
}

//------------------------------------------------------------


fixed4 castRay( in fixed3 ro, in fixed3 rd )
{
	fixed2 pos = floor(ro.xz);
	fixed2 ri = 1.0/rd.xz;
	fixed2 rs = sign(rd.xz);
	fixed2 ris = ri*rs;
	fixed2 dis = (pos-ro.xz+ 0.5 + rs*0.5) * ri;
	
	fixed4 res = fixed4( -1.0, 0.0, 0.0, 0.0 );

    // traverse regular grid (in 2D)
	[unroll(100)]
for( int i=0; i<24; i++ ) 
	{
		if( res.x>0.0 ) continue;
		
        // intersect sphere
		fixed4  sph = makeSphere( pos );
			
		fixed3  rc = ro - sph.xyz;
		fixed b = dot( rd, rc );
		fixed c = dot( rc, rc ) - sph.w*sph.w;
		fixed h = b*b - c;
		if( h>0.0 )
		{
			fixed s = -b - sqrt(h);
			res = fixed4( s, 0.0, pos );
		}
        else
		{
            fixed a = dot( rd.xz, rd.xz );
            b = dot( rc.xz, rd.xz );
            c = dot( rc.xz, rc.xz ) - min(0.25*sph.w*sph.w,0.005);
            h = b*b - a*c;
            if( h>=0.0 )
            {
                // cylinder			
                fixed s = (-b - sqrt( h ))/a;
                if( s>0.0 && (ro.y+s*rd.y)<sph.y )
                {
                    res = fixed4( s, 1.0, pos );
                }
            }
		}
			
        // step to next cell		
		fixed2 mm = step( dis.xy, dis.yx ); 
		dis += mm*ris;
        pos += mm*rs;
	}

	return res;
}



fixed3 calcNormal( in fixed3 pos, in fixed ic )
{
	if( ic>1.5 ) return fixed3(0.0,1.0,0.0);
	return normalize(pos*fixed3(1.0,1.0-ic,1.0));
}

fixed occSphere( in fixed4 sph, in fixed3 pos, in fixed3 nor )
{
    fixed3 di = sph.xyz - pos;
    fixed l = length(di);
    return 1.0 - max(0.0,dot(nor,di/l))*sph.w*sph.w/(l*l); 
}

fixed emmSphere( in fixed4 sph, in fixed3 pos, in fixed3 nor )
{
    fixed3 di = sph.xyz - pos;
    fixed l = length(di);
    fixed at = 1.0-smoothstep(0.5,2.0,l);
	return at * pow(max(0.0,0.5+0.5*dot(nor,di/l)),2.0)*sph.w*sph.w/(l*l); 
}

fixed4 texcube( sampler2D sam, in fixed3 p, in fixed3 n )
{
	fixed4 x = tex2D( sam, p.yz );
	fixed4 y = tex2D( sam,p.yz);
	fixed4 z = tex2D( sam, p.xy );
	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

fixed3 cameraPath( fixed t )
{
    // procedural path	
    fixed2 p  = 100.0*sin( 0.02*t*fixed2(1.2,1.2));
	     p +=  50.0*sin( 0.04*t*fixed2(1.1,1.3) + fixed2(1.0,4.5) );
	fixed y = 3.5 + 1.5*sin(0.1*t);

	return fixed3( p.x, y, p.y );
}
fixed4 frag(v2f i) : SV_Target{

{
    // inputs	
	fixed2 q = i.uv.xy / 1;
	
    fixed2 mo = _iMouse.xy / 1;
    if( _iMouse.w<=0.00001 ) mo=fixed2(0.0,0.0);
	
	
	// montecarlo	
	fixed3 tot = fixed3(0.0,0.0,0.0);
    #if VIS_SAMPLES<2
	int a = 0;
	{
        fixed2 p = -1.0 + 2.0*(i.uv.xy) / 1;
        p.x  = mul(        p.x ,1/ 1);
        fixed time = 0.3*_Time.y + 50.0*mo.x;
    #else
	[unroll(100)]
for( int a=0; a<VIS_SAMPLES; a++ )
	{
		fixed4 rr = tex2D( _SecondTex, (i.uv.xy+floor(256.0*hash2(fixed(a))))/iChannelResolution[1].xy );
        fixed2 p = -1.0 + 2.0*(i.uv.xy+rr.xz) / 1;
        fixed time = 0.3*(_Time.y + 1.0*(0.5/24.0)*rr.w) + 50.0*mo.x;
    #endif	

		// camera
        fixed3  ro = cameraPath( time );
        fixed3  ta = cameraPath( time*2.0+15.0 );
		ta = ro + normalize(ta-ro);
		ta.y = ro.y - 0.4;
		
        fixed cr = -0.2*cos(0.1*time);
	
        // build ray
        fixed3 ww = normalize( ta - ro);
        fixed3 uu = normalize(cross( fixed3(sin(cr),cos(cr),0.0), ww ));
        fixed3 vv = normalize(cross(ww,uu));
        fixed r2 = p.x*p.x*0.32 + p.y*p.y;
        p  = mul(        p ,(7.0-sqrt(37.5-11.5*r2))/(r2+1.0));
        fixed3 rd = normalize( p.x*uu + p.y*vv + 3.0*ww );

        // dof
        #if VIS_SAMPLES>2
		fixed fft = (ro.y*2.0+0.0)/dot(rd,ww);
        fixed3 fp = ro + rd * fft;
		fixed2 bo = sqrt(rr.y)*fixed2(cos(6.2831*rr.w),sin(6.2831*rr.w));
        ro += (uu*bo.x + vv*bo.y)*0.005*fft;
        rd = normalize( fp - ro );
        #endif


        // background color	
		fixed3 bgcol = fixed3(0.0,0.0,0.0);

        fixed3 col = bgcol;
		
	
        // raytrace top bounding plane
		fixed tp = (2.3-ro.y)/rd.y;
		if( tp>0.0 ) ro = ro + rd*tp;

        // trace linterns		
		fixed4 res  = castRay(  ro, rd );
			
		fixed tp2 = (0.0-ro.y)/rd.y;
		fixed4 res2 = fixed4(tp2,2.0,floor(ro.xz+tp2*rd.xz));
		if( res.x<0.0 ) res = res2; else if( tp2<res.x ) res = res2;

			
		fixed t = res.x;
		fixed2 vos = res.zw;
		if( t>0.0 )
		{
			fixed3  pos = ro + rd*t;
			fixed id  = hash1( vos );
				
			fixed4 sph = makeSphere( vos );
				
			fixed3 rpos = pos-sph.xyz;
	
			fixed3  nor = calcNormal( rpos, res.y );

            // material			
			fixed3 mate = makeColor( vos );
			if( res.y>1.5 ) mate=fixed3(0.15,0.15,0.15);
			mate  = mul(			mate ,0.5 + 1.5*pow(texcube( _MainTex, pos, nor ).x, 1.5 ));
			
            // procedural occlusion
			fixed occ = (0.5+0.5*nor.y);
			if( res.y<1.5) 
			{
				occ = mul(				occ,0.3+0.7*clamp( pos.y/.24, 0.0, 1.0 ));
				if( res.y>0.5 )occ  = occ *0.6+0.5*clamp( -(pos.y-(sph.y-sph.w))*7.0, 0.0, 1.0 );
				
					
			}
			else
			{
				occ  = mul(				occ ,0.5 + 0.5*smoothstep(0.0,0.3, length(rpos.xz) ));
				occ  = mul(				occ ,0.5);
			}
            // analytic occlusion
			fixed nocc = 1.0;
			nocc  = mul(			nocc ,occSphere( makeSphere(vos+fixed2( 1.0, 0.0)), pos, nor ));
			nocc  = mul(			nocc ,occSphere( makeSphere(vos+fixed2(-1.0, 0.0)), pos, nor ));
			nocc  = mul(			nocc ,occSphere( makeSphere(vos+fixed2( 0.0, 1.0)), pos, nor ));
            nocc  = mul(            nocc ,occSphere( makeSphere(vos+fixed2( 0.0,-1.0)), pos, nor ));
			if( res.y>1.5 ) nocc  = nocc *occSphere( makeSphere(vos+fixed2( 0.0,0.0)), pos, nor );
            occ  = mul(            occ ,nocc*nocc);
 
            // ambient and emmision			
            fixed3 amb = fixed3(0.015,0.015,0.015);
            fixed3 emm = 1.5*makeEmission(vos)*step(res.y,1.5);
			
            // direct lichting			
            fixed3 dir = fixed3(0.0,0.0,0.0);
            fixed ia = 20.0;		
			dir += ia*emmSphere( makeSphere(vos+fixed2( 1.0, 0.0)), pos, nor )*makeEmission(vos+fixed2( 1.0, 0.0));
            dir += ia*emmSphere( makeSphere(vos+fixed2(-1.0, 0.0)), pos, nor )*makeEmission(vos+fixed2(-1.0, 0.0));
            dir += ia*emmSphere( makeSphere(vos+fixed2( 0.0, 1.0)), pos, nor )*makeEmission(vos+fixed2( 0.0, 1.0));
            dir += ia*emmSphere( makeSphere(vos+fixed2( 0.0,-1.0)), pos, nor )*makeEmission(vos+fixed2( 0.0,-1.0));
            dir += ia*emmSphere( makeSphere(vos+fixed2( 1.0, 1.0)), pos, nor )*makeEmission(vos+fixed2( 1.0, 1.0));
            dir += ia*emmSphere( makeSphere(vos+fixed2(-1.0, 1.0)), pos, nor )*makeEmission(vos+fixed2(-1.0, 1.0));
            dir += ia*emmSphere( makeSphere(vos+fixed2( 1.0,-1.0)), pos, nor )*makeEmission(vos+fixed2( 1.0,-1.0));
            dir += ia*emmSphere( makeSphere(vos+fixed2(-1.0,-1.0)), pos, nor )*makeEmission(vos+fixed2(-1.0,-1.0));
            dir += ia*emmSphere( makeSphere(vos+fixed2( 0.0, 0.0)), pos, nor )*makeEmission(vos+fixed2( 0.0, 0.0));

            // lighitng			
            fixed3 lin = fixed3(0.0,0.0,0.0);				
            lin += emm;
            lin += amb*occ;
            lin += dir*occ;
            lin += (amb*0.2+emm+dir) * 40.0 * pow( clamp( 1.0+dot(rd,nor), 0.0, 1.0), 2.0 )*occ*mate;

            if( res.y<1.5 ) lin  = lin *clamp(pos.y,0.0,1.0);
			
            col = mate * lin;

            // fog			
			col  = mul(			col ,exp(-0.005*t*t));
        }
		
        col = clamp(col,0.0,1.0);
		tot += col;
	}
	tot /= fixed(VIS_SAMPLES);

	tot = pow( clamp(tot,0.0,1.0), fixed3(0.44,0.44,0.44) );
		
	return fixed4( tot, 1.0 );
}
}ENDCG
}
}
}

