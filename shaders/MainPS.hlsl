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
};

struct PSOut
{
	float4 Position;
	float3 Normal;
	float LightLink;
	float3 Color;
	float3 ORM;
	float4 Emissive;
	float4 SpecTest;
};

int atlasSize = 1;

PSOut main(PSInput pin)
{
	PSOut pout = (PSOut)0;
	//sample maps
	float2 uvMap = (pin.UV) * float2(1/float(atlasSize),-1);
	float4 colorMap = texCA.Sample(smp,uvMap);
	float4 ormMap =  texORM.Sample(smp,uvMap);
	float3 NormalMap = normalize(texNormal.Sample(smp,uvMap)*2-1);
	float4 EmissiveMap = texEmissive.Sample(smp,uvMap);
	
	
	//Color Map
	float3 cMap = colorMap.xyz*ormMap.x;
	//ORM
	pout.ORM = ormMap;
	
	//Normal Map
	float3 wTangent = cross(pin.wNormal,float3(0,1,0));
	float3 wBitangent = cross(pin.wNormal,wTangent);
	float3 N = (pin.wNormal * NormalMap.z) + (wBitangent * -NormalMap.y) + (wTangent * -NormalMap.x);
	N = normalize(N);
	
	pout.Color = cMap;
	pout.Position = pin.wPosition;
	pout.Position.a = pin.Position.a;
	pout.Normal  = N;
	pout.LightLink = LightLinkID;
	pout.Emissive = EmissiveMap;
	return pout;
}
