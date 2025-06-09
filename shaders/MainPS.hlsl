Texture2D texCA : register(t0);
Texture2D texORM : register(t1);
Texture2D texNormal : register(t2);
Texture2D texEmissive : register(t3);
SamplerState smp : register(s0);
int LightLinkID;

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV;
	float4 wPosition;
	float3 wNormal;
	float3 wTangent;
	float3 wBitangent;
};

struct PSOut
{
	float4 Position;
	float3 Normal;
	float LightLink;
	float3 Color;
	float3 ORM;
	float4 Emissive;
};

PSOut main(PSInput pin)
{
	PSOut pout = (PSOut)0;
	//sample maps
	float2 uvMap = (pin.UV + float2(0,1)) * float2(0.1667,-0.5);
	float4 colorMap = texCA.Sample(smp,uvMap);
	float4 ormMap =  texORM.Sample(smp,uvMap);
	float4 NormalMap =  texNormal.Sample(smp,uvMap)*2-1;
	float4 EmissiveMap = texEmissive.Sample(smp,uvMap);

	
	
	//Color Map
	float3 cMap = colorMap.xyz*ormMap.x;
	//ORM
	pout.ORM = ormMap;
	//Normal Map
	float3 N = (pin.wNormal * NormalMap.z) + (pin.wBitangent * -NormalMap.y) + (pin.wTangent * -NormalMap.x);
	N = pin.wNormal;
	
	
	pout.Color = cMap;
	pout.Position = pin.wPosition;
	pout.Position.a = pin.Position.a;
	pout.Normal  = N;
	pout.LightLink = LightLinkID;
	pout.Emissive = EmissiveMap;
	return pout;
}
