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

Texture2D ColorPass : register(t0);
Texture2D PositionPass : register(t1);
Texture2D NormalPass : register(t2);
Texture2D ShadowMap : register(t3);
Texture2D LightLinkPass : register(t4);
Texture2D ORMPass : register(t5);
TextureCube CubeMap : register(t6);
SamplerState smp : register(s0);


float randomNumber(float maxNumber)
{
	return 	frac(sin(maxNumber) * 43758.5453123);

}

float4 Ambient;
	
PSOut main(PSInput pin) : SV_TARGET
{
	PSOut pout = (PSOut)0;
	pin.UV.y = 1-pin.UV.y;
	float3 lightPos;
	float4 Diffuse;
	float4 DiffuseResult;
	float4 Specular;
	float4 SpecularResult;
	float4 VolumeResult;
	float4 Color = ColorPass.Sample(smp,pin.UV);
	float4 Position = PositionPass.Sample(smp,pin.UV);
	float3 Normal = NormalPass.Sample(smp,pin.UV);
	float LightLink = LightLinkPass.Sample(smp,pin.UV);
	float4 Env = CubeMap.Sample(smp, Position.xyz - 5) * .1;
	float3 ORM = ORMPass.Sample(smp,pin.UV);
	
		for(int i = 0; i < 10; i++)
	{
		//stop after loop through all lights
		if (lightBuffer[i].Color.a == 0){
			break;
		}
		
		
		if (sign((lightBuffer[i].extraData.a) >= 0))
		{
			if(lightBuffer[i].extraData.a != 0 && lightBuffer[i].extraData.a != round((LightLink)))
			{
				continue;
			}		
		} else
		
		{
			if( lightBuffer[i].extraData.a == -round(LightLink))
			{
				continue;
			}	
		}

		
		
		//build vector
		lightPos = lightBuffer[i].Position.xyz;
		float3 lightVec = normalize(lightPos - Position);
		
		//Diffuse Light
		float NdotL = dot(lightVec, Normal);
		float diffuseLight = saturate(NdotL);
		Diffuse = diffuseLight * lightBuffer[i].Color;
		//BRDF
		float Roughness = 0.3;
		float3 V = normalize(camPos-Position);
		float3 H = normalize(lightVec+V);
		float NdotH = dot(Normal,H);
		float NdotV = dot(Normal,V);
		float VdotH = dot(V,H);
		
		float k = pow(Roughness + 1,2) / 8;
		float G = (NdotV / (NdotV*(1-k) + k));
		
		float ior = 1.3;
		float metallic = 0;
		float3 F0 = abs ((1.0 - ior) / (1.0 + ior));
		F0 = F0 * F0;
		F0 = lerp(F0, Color.rgb, metallic);
		float F = F0 + (1-F0) * pow(2,-5.55473*VdotH-6.98316*VdotH);

		float R2 = Roughness * Roughness;
		float NdotH2 = NdotH * NdotH;
		float D = NdotH2 / (3.14 * pow(NdotH2 * (R2-1) + 1,2));
		Specular = (D*F*G) / (4);
		//Light attenuation
		float falloff = lightBuffer[i].extraData.x;
		float lightFalloff = falloff/(pow(length(lightPos - Position),2));
		float ConeAngle = lightBuffer[i].extraData.y;
		float SpotCone = saturate(pow(dot(lightVec,normalize(-lightBuffer[i].Direction.xyz)),ConeAngle));
		
		//shadowmap
		float texels = 3;
		float3 N = 2*normalize(lightBuffer[i].Direction * -1);
		float3 T = normalize(cross(float3(0,1,0),N));
		float3 B = normalize(cross(N,T));
		float4x4 matLookAt = float4x4 (
		float4(T.x,B.x,N.x,0),
		float4(T.y,B.y,N.y,0),
		float4(T.z,B.z,N.z,0),
		dot(-lightBuffer[i].Position,T),dot(-lightBuffer[i].Position,B),dot(-lightBuffer[i].Position,N),1);
		
		float4 shadowProject = mul(mul(float4(Position.xyz,1),matLookAt),matProject);
		float screenRatio = viewSize.x /viewSize.y;
		shadowProject.xy = shadowProject * float2(screenRatio,1);
		float3 coords = shadowProject.xyz / shadowProject.w;
		coords = coords * .5+.5;
		
		float2 uvMap = coords;
		float offset = i;
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
			float d = 0.005;
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

		//volumetric scattering
		float2 ndcPosition = pin.UV;
		float4 viewLight = mul(float4(lightBuffer[i].Position.xyz,1),matVP);
		viewLight.xyz /= viewLight.w;
		float2 ndcLight = viewLight.xy * 0.5 + 0.5;
		float4 ndcDirection = mul(float4(lightBuffer[i].Direction.xyz,0),matVP);
		ndcDirection.xyz = normalize(ndcDirection.xyz);

		
		float2 pixelVector = normalize(ndcPosition-ndcLight);
		float4 lgtVolume = dot(pixelVector,ndcDirection);
		
		//volume falloff
		float vecDist = distance(float3(ndcPosition,0),float3(ndcLight,0));
		lgtVolume = saturate(pow(lgtVolume,ConeAngle*0.5));
		lgtVolume *= lightBuffer[i].Color * .0002 * falloff/length(ndcPosition-ndcLight);
		lgtVolume = saturate(lgtVolume);
		lgtVolume *= (viewLight.a - 10 > mul(float4(Position.xyz,1),matVP).a) ? 0 : 1;
		
		//combine
		DiffuseResult += saturate(Diffuse * lightFalloff * SpotCone * shadowMap);
		SpecularResult += saturate(Specular * lightFalloff * SpotCone * shadowMap);
		VolumeResult += lgtVolume * lightBuffer[i].extraData.z;

	}
	
	DiffuseResult.a = 1;
	pout.Main =  ((Color * DiffuseResult) + SpecularResult) + Ambient + VolumeResult;
	return pout;
}