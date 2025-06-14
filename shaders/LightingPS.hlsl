Texture2D Position : register(t0);
Texture2D Normal : register(t1);
Texture2D SceneLightLink : register(t2);
Texture2D ShadowMapAtlas : register(t3);
Texture2D SceneColor : register(t4);
Texture2D SceneORM : register(t5);
Texture2D envMap : register(t6);
SamplerState smp : register(s0);

//Buffer
struct InputData 
{
	float4 Color;
	float4 Position;
	float4 Direction;
	float4 extraData;
};
StructuredBuffer<InputData> lightBuffer : register(u0);


cbuffer cbPerFrame : register(b0)
{
	float4 camPos;
	float4x4 matProject;
	float2 viewSize;
	float4x4 matVP;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

float randomNumber(float maxNumber)
{
	return 	frac(sin(maxNumber) * 43758.5453123);

}

float HDRStrength;
int ShadowSamples;

struct Lighting
{
	//init
	int lgtIndex;
	float4 lgtColor;
	float3 lgtPos;
	float3 lgtDir;
	float4 lgtXtra;
	
	float2 UV;
	float3 gPos;
	float4 gColor;
	float3 gNormal;
	float3 camPos;
		
	float metallic;
	float Roughness;
	float ior;
	float HDRStrength;

	float4 Calculate()
	{
		return (_Diffuse() + _Specular()) * _Shadow() + _Volumetric();
	}

	float4 _Diffuse()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float NdotL = dot(lgtVec, gNormal);
		float4 diffuseLight = saturate(NdotL) / 3.14;
		diffuseLight = diffuseLight * lgtColor;
		diffuseLight *= 1-metallic;
		return diffuseLight * gColor * _attenuation();
	}
	
	float4 _Specular()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float3 V = normalize(camPos-gPos);
		float3 H = normalize(lgtVec+V);
		float NdotL = saturate(dot(gNormal,lgtVec));
		float NdotH = saturate(dot(gNormal,H));
		float NdotV = saturate(dot(gNormal,V));
		float VdotH = saturate(dot(V,H));
		
		//G Reflectance due to Geometry
		float k = pow(Roughness+1,2) / 2;
		float G = NdotV / (NdotV * (1-k) + k);
		float G2 = NdotL / (NdotL*(1-k) + k);
		G *= G2;

		//F Reflectance due to Fresnel
		float3 F0 = pow(1-ior,2) / pow(1 + ior,2);
		F0 = lerp(F0, gColor.xyz, metallic);
		float3 F = F0 + (1-F0) * pow(1-VdotH,5);
	
		//D Reflectance due to Normal distribution
		float R2 = Roughness * Roughness;
		float NdotH2 = NdotH * NdotH;
		float D = R2 / (3.14 * pow(NdotH2 * (R2-1) + 1,2));
		
		//Cook-Torance
		float3 Specular = (D*F*G) / (4*NdotL*NdotV);
		Specular = saturate(Specular);
		return float4(Specular,1) * _attenuation() * lgtColor;
	}
	
	float4 _Volumetric()
	{
		//get light values in view space
		float4 viewLgtPos = mul(float4(lgtPos.xyz,1),matVP);
		viewLgtPos.xyz /= viewLgtPos.w;
		float3 ndcLgtPos = viewLgtPos.xyz * 0.5 + 0.5;
		
		float2 ndcLgtDir = mul(float4(lgtDir.xyz,0),matVP).xy;
		ndcLgtDir = normalize(ndcLgtDir);
		
		//volumetric
		float2 viewVector = normalize(UV-ndcLgtPos.xy);
		float4 Volumetric = saturate(dot(viewVector,ndcLgtDir));
		
		//volume falloff
		float falloff = lgtXtra.x;
		float ConeAngle = lgtXtra.y * 20;
		float vecDist = distance(float3(UV,0),float3(ndcLgtPos.xy,0));
		float VolumeFalloff = saturate(1-distance(camPos,lgtPos) / 50);
		VolumeFalloff = pow(VolumeFalloff,2) * .5;
		float VolumeCone = pow(Volumetric,ConeAngle);
		
		//raymarch
		float cullCheck = 1;
		float2 ray = normalize(ndcLgtPos.xy-UV);
		float2 startPos = UV;
		int slices = 16;
		float stepSize = distance(ndcLgtPos.xy,startPos.xy) / slices;
		for (int i = 0; i < slices; i++)
		{
			if(Volumetric.x == 0)
			{
				break;
			}
			
			float offset = stepSize * i;	
			float2 marchUV = offset * ray + startPos;	
			float4 sampleDepth = Position.Sample(smp,marchUV);
			
			if (length(sampleDepth.xyz-lgtPos.xyz) < length(gPos.xyz-lgtPos.xyz)-70)
			{
				cullCheck = 0;
				break;
			}
		}

		
		return saturate(Volumetric * lgtColor * VolumeFalloff * VolumeCone * cullCheck) * lgtXtra.z ;
	
	}
	
	float _attenuation()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float falloff = lgtXtra.x;
		float ConeAngle = lgtXtra.y;
		float lightFalloff = falloff/(pow(length(lgtPos - gPos),2));
		float SpotCone = 1;
		if(lgtColor.a == 1)
		{
			SpotCone = pow(saturate(dot(lgtVec,normalize(-lgtDir))),ConeAngle);
		}
		
		return lightFalloff * SpotCone;
	}
	
	float _Shadow()
	{
		if(lgtColor.a != 1)
		{
			return 1;
		}
		
		//construct lightView
		float texels = 3;
		float3 N = 3*normalize(-lgtDir);
		float3 T = normalize(cross(float3(0,1,0),N));
		float3 B = normalize(cross(N,T));
		float4x4 matLookAt = float4x4 (
		float4(T.x,B.x,N.x,0),
		float4(T.y,B.y,N.y,0),
		float4(T.z,B.z,N.z,0),
		dot(-lgtPos,T),dot(-lgtPos,B),dot(-lgtPos,N),1);
		
		//create UV from light data
		float4 shadowProject = mul(mul(float4(gPos,1),matLookAt),matProject);
		float screenRatio = viewSize.x /viewSize.y;
		shadowProject.xy *= float2(screenRatio,1);
		shadowProject.xy /= shadowProject.w;
		shadowProject.xy = shadowProject.xy * .5+.5;
		float2 uvMap = shadowProject.xy;

		//fetch ShadowMapAtlas from atlas
		float offset = lgtIndex;
		float x = offset%texels * 1/texels;
		float y = -floor(offset/texels) * 1/texels + 1-1/texels;
		float2 clipUv = (uvMap / texels) + float2(x,y);;
		
		float Shadow;
		//if outside range set to 1 else calculate shadow;
		if ((clipUv.x < x) || (clipUv.x > x + 1/texels) || (clipUv.y < y) ||  (clipUv.y > y + 1/texels))
		{
			Shadow = 1;
		} else
		{
			float d = 0.0007;
			for (int i = 0; i < ShadowSamples; i++)
			{
				float2 offset = float2(randomNumber(i*3.1232)*2-1,randomNumber(i*1.63434)*2-1);
				offset *= d;
				float shadowTex = ShadowMapAtlas.Sample(smp,clipUv.xy + offset).x;
				Shadow += ( 1/shadowProject.w >  shadowTex - d);
			}
			Shadow /= ShadowSamples;
		}
		return Shadow;
	}
	
	float4 HDRI()
	{
		float2 uv;
		//diffuse
		float3 dir = gNormal;
	    uv.x = atan2(dir.z,dir.x) / (2.0 * 3.14159265) + 0.5;
	    uv.y = asin(clamp(dir.y, -1.0, 0.99)) / 3.14159265 + 0.5;
	    float3 Diffuse = envMap.SampleLevel(smp,uv,10) * gColor;
	    Diffuse /= 3.14;
	    Diffuse *= 1-metallic;
		
		//specular
		dir = reflect(-normalize(camPos-gPos),gNormal);
	    uv.x = atan2(dir.z,dir.x) / (2.0 * 3.14159265) + 0.5;
	    uv.y = asin(clamp(dir.y, -1.0, 0.99)) / 3.14159265 + 0.5;
	    uv.x *=2;
	    float3 Specular = envMap.SampleLevel(smp,uv,Roughness*10);
	    
	    float3 F0 = pow(1-ior,2) / pow(1 + ior,2);
		F0 = lerp(F0, gColor.xyz, metallic);
	    Specular = Specular * (F0);
	    
		float3 HDRI = Diffuse + Specular;
		return float4(HDRI, 1.0)*HDRStrength;
	}
};


float4 AmbientColor;
	
float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	
	float4 Result;
	
	float4 Position = Position.Sample(smp,pin.UV);
	float3 Normal = Normal.Sample(smp,pin.UV);
	float4 Color = SceneColor.Sample(smp,pin.UV);
	float3 ORM = SceneORM.Sample(smp,pin.UV);
	float LightLink = SceneLightLink.Sample(smp,pin.UV);
	Lighting lighting;
	for(int i = 0; i < 16; i++)
	{
		//stop after loop through all lights
		if (lightBuffer[i].Color.a == 0){
			break;
		}
		
		//light linking
		int objLink = round(LightLink);
		int lgtLink = lightBuffer[i].extraData.a;
		if ((lgtLink > 0 && lgtLink != objLink) || (lgtLink < 0 && lgtLink == -objLink))
		{
			continue;
		}

		//set data
		lighting.lgtIndex = i;
		lighting.lgtColor = lightBuffer[i].Color;
		lighting.lgtPos = lightBuffer[i].Position;
		lighting.lgtDir = lightBuffer[i].Direction;
		lighting.lgtXtra = lightBuffer[i].extraData;
		lighting.UV = pin.UV;
		lighting.gPos = Position;
		lighting.gColor = Color;
		lighting.gNormal = normalize(Normal);
		lighting.camPos = camPos;
		lighting.metallic = ORM.z;
		lighting.Roughness = max(ORM.y,0.05);
		lighting.ior = 1.5;
		lighting.HDRStrength = HDRStrength;


		Result += lighting.Calculate();
	}
	return Result + lighting.HDRI() + AmbientColor;
}