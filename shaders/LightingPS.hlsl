//Buffer
struct InputData 
{
	float4 Color;
	float3 Position;
	float Strength;
	float3 Direction;
	float Falloff;
};
StructuredBuffer<InputData> lightBuffer : register(u0);

cbuffer cbPerFrame : register(b0)
{
	float4 camPos;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

Texture2D ColorPass : register(t0);
Texture2D PositionPass : register(t1);
Texture2D NormalPass : register(t2);
SamplerState smp : register(s0);

float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	float3 lightPos;
	float4 Diffuse;
	float4 DiffuseResult;
	float4 Specular;
	float4 SpecularResult;
	float4 Ambient;
	float4 Color = ColorPass.Sample(smp,pin.UV);
	float4 Position = PositionPass.Sample(smp,pin.UV);
	float3 Normal = NormalPass.Sample(smp,pin.UV);
	
		for(int i = 0; i < 10; i++)
	{
		//stop after loop through all lights
		if (lightBuffer[i].Color.a == 0){
			break;
		}
		
		//build vector
		lightPos = lightBuffer[i].Position.xyz;
		float3 lightVec = normalize(lightPos - Position);
		
		//Diffuse Light
		float NdotL = dot(lightVec, Normal);
		float diffuseLight = saturate(NdotL);
		Diffuse = diffuseLight * lightBuffer[i].Color;
		//BRDF
		float Roughness = .5;
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
		float falloff = lightBuffer[i].Strength;
		float lightFalloff = 1/(pow(length(lightVec),2)) * falloff;
		float ConeAngle = lightBuffer[i].Falloff;
		float SpotCone = saturate(pow(dot(lightVec,normalize(-lightBuffer[i].Direction.xyz)),ConeAngle));
		//combine
		DiffuseResult += saturate(Diffuse * lightFalloff * SpotCone);
		SpecularResult += saturate(Specular * lightFalloff * SpotCone);
		
		/*shadowmap
		 float3 lgtNormal = -normalize(lightBuffer[i].Direction.xyz * float3(-1,1,1));
		 float3 lgtTangent = -normalize(cross(lgtNormal,float3(1,0,0)));
		 float3 lgtBitangent = -normalize(cross(lgtNormal,lgtTangent));
		 float4x4 newView = 
		{
			lgtBitangent.x,lgtBitangent.y,lgtBitangent.z,0,
			lgtTangent.x,lgtTangent.y,lgtTangent.z,0,
			lgtNormal.x,lgtNormal.y,lgtNormal.z,0,
			0,0,0,1
		};
			newView = mul(newView,matProject);
			float4 shadowUV = mul(pin.wPosition-float4(lightBuffer[i].Position.x,lightBuffer[i].Position.y,lightBuffer[i].Position.z,0),newView);
			float shadowMap;
			if (abs(shadowUV).x *.05+.65 < 1 && abs(shadowUV).y *.05+.5 < 1)
			{
				shadowMap = saturate(ShadowMap.Sample(smp,shadowUV*.05-float2(0.5,0.65)).x*2);
				shadowMap = 1-saturate(shadowUV.z * .1 - (1-shadowMap));
			} else
			{
				shadowMap = 1;
			}*/
	}
	
	DiffuseResult.a = 1;
	return Color * (DiffuseResult + SpecularResult + Ambient);
}