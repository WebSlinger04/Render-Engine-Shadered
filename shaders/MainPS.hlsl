//tweakables
Texture2D texCA : register(t0);
Texture2D texNormal : register(t1);
Texture2D texORM : register(t2);
SamplerState smp : register(s0);
float2 TextureTile;

cbuffer cbPerFrame : register(b0)
{
	float4x4 invMatGeo;
};


struct PSInput
{
	float4 Position : SV_POSITION;
	float4 wPosition;
	float4 Color : COLOR;
	float3 wNormal;
	float3 wTangent;
	float3 wBitangent;
	float2 UV;
};

struct PSOut
{
	float3 Color;
	float4 Position;
	float3 Normal;
};

PSOut main(PSInput pin)
{
	PSOut pout = (PSOut)0;
	//sample maps
	float2 uvMap = pin.UV * TextureTile;
	float4 colorMap = texCA.Sample(smp,uvMap);
	float4 ormMap =  texORM.Sample(smp,uvMap);
	float4 NormalMap =  texNormal.Sample(smp,uvMap)*2-1;
	float aoMap = ormMap.x;
	float MetallicMap = ormMap.y;
	float RoughnessMap = ormMap.z;
	
	//Color Map
	float4 cMap = colorMap; //*aoMap;
	cMap = 1;
	//metalic map
	
	//roughness map
	
	//Normal Map
	float3 N = (pin.wNormal * NormalMap.z) + (pin.wBitangent * -NormalMap.y) + (pin.wTangent * -NormalMap.x);
	N = pin.wNormal;
	
	
	pout.Color = cMap;
	pout.Position = pin.wPosition;
	pout.Position.a = pin.Position.a;
	pout.Normal = mul(N,invMatGeo);
	return pout;
}
