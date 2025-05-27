Texture2D PositionPass : register(t0);
Texture2D NormalPass : register(t1);
Texture2D ColorPass : register(t2);
Texture2D ORMPass : register(t3);
Texture2D ShadowMap : register(t4);
Texture2D LightLinkPass : register(t5);
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

struct PSOut
{
	float4 Main : SV_Target1;
};

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
		
	float metallic;
	float Roughness;
	float ior;

	float4 Calculate()
	{
		return (_Diffuse() + _Specular()) * _Shadow() + _Volumetric();
	}

	float4 _Diffuse()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float NdotL = dot(lgtVec, gNormal);
		float4 diffuseLight = saturate(NdotL);
		diffuseLight = diffuseLight * lgtColor;
			
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
		float k = pow((1-Roughness) + 1,2) / 8;
		float G = NdotV / (NdotV * (1-k) + k);
		float G2 = NdotL / (NdotL*(1-k) + k);
		G *= G2;
		
		//F Reflectance due to Fresnel
		float F0 = pow(1-ior,2) / pow(1 + ior,2);
		F0 = lerp(F0, gColor.xyz, metallic);
		float3 F = F0 + (1-F0) * pow(1-VdotH,5);
	
		//D Reflectance due to Normal distribution
		float R2 = Roughness * Roughness;
		float NdotH2 = NdotH * NdotH;
		float D = R2 / (3.14 * pow(NdotH2 * (R2-1) + 1,2));
		
		//Cook-Torance
		float3 Specular = (D*F*G) / (4*max(NdotL,0.001),max(NdotV,0.001));
		return float4(Specular,1) * _attenuation() * lgtColor;
	}
	
	float4 _Volumetric()
	{
		//get light values in view space
		float4 viewLgtPos = mul(float4(lgtPos.xyz,1),matVP);
		viewLgtPos.xyz /= viewLgtPos.w;
		float2 ndcLgtPos = viewLgtPos.xy * 0.5 + 0.5;
		
		float3 ndcLgtDir = mul(float4(lgtDir.xyz,0),matVP).xyz;
		ndcLgtDir.xyz = normalize(ndcLgtDir.xyz);

		//volumetric
		float2 viewVector = normalize(UV-ndcLgtPos);
		float4 Volumetric = saturate(dot(viewVector,ndcLgtDir));
		
		//volume falloff
		float falloff = lgtXtra.x;
		float ConeAngle = lgtXtra.y;
		float vecDist = distance(float3(UV,0),float3(ndcLgtPos,0));
		float VolumeFalloff = .0002 * falloff/length(UV-ndcLgtPos);
		float VolumeCone = pow(Volumetric,ConeAngle);
		//depth check
		Volumetric *= saturate( (mul(float4(gPos.xyz,1),matVP).a - viewLgtPos.a ) / 5 + 1);
		
		return Volumetric * lgtColor * VolumeFalloff * VolumeCone * lgtXtra.z;
	
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
		
		return 1 * lightFalloff * SpotCone;
	}
	
	float _Shadow()
	{
		if(lgtColor.a != 1)
		{
			return 1;
		}
		
		//construct lightView
		float texels = 4;
		float3 N = 4*normalize(-lgtDir);
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

		//fetch shadowMap from atlas
		float offset = lgtIndex;
		float x = offset%texels * 1/texels;
		float y = -floor(offset/texels) * 1/texels + 1-1/texels;
		float2 clipUv = (uvMap / texels) + float2(x,y);;
		
		float shadowMap;
		//if outside range set to 1 else calculate shadow;
		if ((clipUv.x < x) || (clipUv.x > x + 1/texels) || (clipUv.y < y) ||  (clipUv.y > y + 1/texels))
		{
			shadowMap = 1;
		} else
		{
			int ShadowSamples = 32;
			float d = 0.0075;
			for (int i = 0; i < ShadowSamples; i++)
			{
				float2 offset = float2(randomNumber(i*3.1232)*2-1,randomNumber(i*1.63434)*2-1);
				offset *= d;
				float shadowTex = ShadowMap.Sample(smp,clipUv.xy + offset).x;
				shadowMap += ( 1/shadowProject.w >  shadowTex - .001 );
			}
			shadowMap /= ShadowSamples;
		}
		return shadowMap;
	}
};


float4 Ambient;
	
PSOut main(PSInput pin) : SV_TARGET
{
	PSOut pout;
	pin.UV.y = 1-pin.UV.y;
	
	float4 Result;
	
	float4 Position = PositionPass.Sample(smp,pin.UV);
	float3 Normal = NormalPass.Sample(smp,pin.UV);
	float4 Color = ColorPass.Sample(smp,pin.UV);
	float3 ORM = ORMPass.Sample(smp,pin.UV);
	float LightLink = LightLinkPass.Sample(smp,pin.UV);

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
		lighting.metallic = 0;
		lighting.Roughness = .2;
		lighting.ior = 1.5;


		Result += lighting.Calculate();

	}
		
	pout.Main = Result + Ambient;
	return pout;
}