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

struct PSOut
{
	float4 Main : SV_Target1;
};

Texture2D PositionPass : register(t0);
Texture2D NormalPass : register(t1);
Texture2D ColorPass : register(t2);
Texture2D ORMPass : register(t3);
Texture2D ShadowMap : register(t4);
Texture2D LightLinkPass : register(t5);
SamplerState smp : register(s0);


float randomNumber(float maxNumber)
{
	return 	frac(sin(maxNumber) * 43758.5453123);

}

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
		
	float metallic = 0;
	float Roughness = 1;
	float ior = 1;

	float4 Diffuse()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float NdotL = dot(lgtVec, gNormal);
		float4 diffuseLight = saturate(NdotL);
		diffuseLight = diffuseLight * lgtColor;
			
		return diffuseLight * gColor * _attenuation() * _Shadow();
	}
	
	float4 Specular()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float3 V = normalize(camPos-gPos);
		float3 H = normalize(lgtVec+V);
		float NdotL = saturate(dot(gNormal,lgtVec));
		float NdotH = saturate(dot(gNormal,H));
		float NdotV = saturate(dot(gNormal,V));
		float VdotH = saturate(dot(V,H));
		
		//G Reflectance due to Geometry
		float k = pow(Roughness + 1,2) / 8;
		float G = (NdotV / (NdotV * (1-k) + k));
		G *= (NdotL / (NdotL*(1-k) + k));
		
		//F Reflectance due to Fresnel
		float3 F0 = abs( (1.0 - ior) / (1.0 + ior) );
		F0 = lerp(F0, gColor.xyz, metallic);
		float3 F = F0 + (1-F0) * pow(1-VdotH,5);
	
		//D Reflectance due to Normal distribution
		float R2 = Roughness * Roughness;
		float NdotH2 = NdotH * NdotH;
		float D = R2 / (3.14 * pow(NdotH2 * (R2-1) + 1,2));
		
		//Cook-Torance
		float3 Specular = (D*F*G) / (4*max(NdotL,.001),max(NdotV,.001));
		return float4(Specular,1) * _attenuation() * _Shadow();
	}
	
	float4 Volumetric()
	{
		//get light values in view space
		float4 viewLgtPos = mul(float4(lgtPos.xyz,1),matVP);
		viewLgtPos.xyz /= viewLgtPos.w;
		float2 ndcLgtPos = viewLgtPos.xy * 0.5 + 0.5;
		
		float3 ndcLgtDir = mul(float4(lgtDir.xyz,0),matVP).xyz;
		ndcLgtDir.xyz = normalize(ndcLgtDir.xyz);

		//volumetric
		float2 viewVector = normalize(UV-ndcLgtPos);
		float4 lgtVolume = dot(viewVector,ndcLgtDir);
		
		//volume falloff
		float vecDist = distance(float3(UV,0),float3(ndcLgtPos,0));
		float4 Volumetric = saturate(pow(lgtVolume,lgtXtra.y*0.5));
		Volumetric *= lgtColor * .0002 * lgtXtra.x/length(UV-ndcLgtPos);
		Volumetric = saturate(Volumetric);
		Volumetric *= (viewLgtPos.a - 10 > mul(float4(gPos.xyz,1),matVP).a) ? 0 : 1;
		
		return Volumetric * lgtXtra.z;
	
	}
	
	float _attenuation()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float falloff = lgtXtra.x;
		float ConeAngle = lgtXtra.y;
		float lightFalloff = falloff/(pow(length(lgtPos - gPos),2));
		float SpotCone = saturate(pow(dot(lgtVec,normalize(-lgtDir)),ConeAngle));
		
		return 1 * lightFalloff * SpotCone;
	}
	
	float _Shadow()
	{
		float texels = 3;
		float3 N = 4*normalize(-lgtDir);
		float3 T = normalize(cross(float3(0,1,0),N));
		float3 B = normalize(cross(N,T));
		float4x4 matLookAt = float4x4 (
		float4(T.x,B.x,N.x,0),
		float4(T.y,B.y,N.y,0),
		float4(T.z,B.z,N.z,0),
		dot(-lgtPos,T),dot(-lgtPos,B),dot(-lgtPos,N),1);
		
		float4 shadowProject = mul(mul(float4(gPos,1),matLookAt),matProject);
		float screenRatio = viewSize.x /viewSize.y;
		shadowProject.xy = shadowProject * float2(screenRatio,1);
		float3 coords = shadowProject.xyz / shadowProject.w;
		coords = coords * .5+.5;
		
		float2 uvMap = coords;
		float offset = lgtIndex;
		float x = offset%texels * 1/texels;
		float y = -floor(offset/texels) * 1/texels + + 1-1/texels;
		float2 clipUv = (uvMap / texels) + float2(x,y);;
		
		float shadowMap;
		if ((clipUv.x < x) || (clipUv.x > x + 1/texels) || (clipUv.y < y) ||  (clipUv.y > y + 1/texels))
		{
			shadowMap = 1;
		} else
		{
			float size = 64;
			float d = 0.0075;
			for (int i = 0 ; i < size ; i++)
			{
				float2 offset = float2(randomNumber(i*3.1232)*2-1,randomNumber(i*1.63434)*2-1);
				offset *= d;
				float shadowTex = ShadowMap.Sample(smp,clipUv.xy + offset).x;
				 shadowMap += ( 1/shadowProject.w >  shadowTex - .001 );
			}
			shadowMap /= size;
			shadowMap = saturate(shadowMap*2);
		}
		return shadowMap;
	}
};


float4 Ambient;
	
PSOut main(PSInput pin) : SV_TARGET
{
	PSOut pout;
	pin.UV.y = 1-pin.UV.y;
	
	float4 DiffuseResult;
	float4 SpecularResult;
	float4 VolumeResult;
	
	float4 Position = PositionPass.Sample(smp,pin.UV);
	float3 Normal = NormalPass.Sample(smp,pin.UV);
	float4 Color = ColorPass.Sample(smp,pin.UV);
	float3 ORM = ORMPass.Sample(smp,pin.UV);
	float LightLink = LightLinkPass.Sample(smp,pin.UV);

	for(int i = 0; i < 9; i++)
	{
		//stop after loop through all lights
		if (lightBuffer[i].Color.a == 0){
			break;
		}
		
		//light linking
		int objLink = round(LightLink);
		int lgtLink = lightBuffer[i].extraData.a;
		if ((lgtLink >= 0 && lgtLink != 0 && lgtLink != objLink) || (lgtLink < 0 && lgtLink == -objLink))
		{
			continue;
		}

		//set data
		Lighting lighting;
		lighting.lgtIndex = i;
		lighting.lgtColor = lightBuffer[i].Color;
		lighting.lgtPos = lightBuffer[i].Position;
		lighting.lgtDir = lightBuffer[i].Direction;
		lighting.lgtXtra = lightBuffer[i].extraData;
		lighting.UV = pin.UV;
		lighting.gPos = Position;
		lighting.gColor = Color;
		lighting.gNormal = Normal;
		lighting.camPos = camPos;


		DiffuseResult += lighting.Diffuse();
		VolumeResult += lighting.Volumetric();
		SpecularResult += lighting.Specular();

	}
		
	pout.Main =  DiffuseResult + SpecularResult + Ambient + VolumeResult;
	return pout;
}