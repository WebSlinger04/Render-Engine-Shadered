//tweakables
Texture2D texCA : register(t0);
SamplerState smp : register(s0);
int LightLink;
float4 Ambient;

//Buffer
struct InputData 
{
	float4 Color;
	float4 Position;
	float4 Direction;
	float4 extraData;
};
StructuredBuffer<InputData> lightBuffer : register(u0);

struct PSInput
{
	float4 Position : SV_POSITION;
	float4 wPosition;
	float4 Color : COLOR;
	float3 wNormal;
	float2 UV;
};

struct PSOut
{
	float4 Translucent;
	float Depth;
};

struct Lighting
{
	//init
	float4 lgtColor;
	float3 lgtPos;
	float3 lgtDir;
	float4 lgtXtra;
	
	float3 gPos;
	float4 gColor;
	float3 gNormal;

	float4 _Diffuse()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float NdotL = dot(lgtVec, gNormal);
		float4 diffuseLight = saturate(NdotL);
		diffuseLight = diffuseLight * lgtColor;
			
		return diffuseLight * gColor * _attenuation();
	}
	
	float _attenuation()
	{
		float3 lgtVec = normalize(lgtPos - gPos);
		float falloff = lgtXtra.x;
		float ConeAngle = lgtXtra.y;
		float lightFalloff = falloff/(pow(length(lgtPos - gPos),2));
		float SpotCone = pow(saturate(dot(lgtVec,normalize(-lgtDir))),ConeAngle);
		
		return 1 * lightFalloff * SpotCone;
	}
};

PSOut main(PSInput pin)
{
	PSOut pout = (PSOut)0;
	//sample maps
	float2 uvMap = (pin.UV + float2(0,1)) * float2(0.1667,-0.5);
	float4 Color = texCA.Sample(smp,uvMap);
	
	float4 Result;
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
		lighting.lgtColor = lightBuffer[i].Color;
		lighting.lgtPos = lightBuffer[i].Position;
		lighting.lgtDir = lightBuffer[i].Direction;
		lighting.lgtXtra = lightBuffer[i].extraData;
		lighting.gPos = pin.wPosition;
		lighting.gColor = Color;
		lighting.gNormal = pin.wNormal;
		Result += lighting._Diffuse();
	}
	Result = Result + Ambient;
	Result = .4;
	pout.Translucent = Result;
	pout.Depth = pin.Position.a;
	return pout;
}
