	cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
	float4x4 matView;
};

struct VSInput
{
	float3 Position : POSITION;
	float2 UV : TEXCOORD;
	float3 Normal : NORMAL;
	float3 Tangent : TANGENT;
	float3 Bitangent : BITANGENT;
};

struct VSOutput
{
	float4 Position : SV_POSITION;
	float2 UV;
	float4 wPosition;
	float3 wNormal;
	float3 wTangent;
	float3 wBitangent;
	
};

VSOutput main(VSInput vin)
{
	VSOutput vout = (VSOutput)0;
	
	vout.wPosition = mul(float4(vin.Position,1),matGeo);
	vout.Position = mul(mul(float4(vin.Position, 1.0f), matGeo), matVP);
	vout.wNormal = mul(vin.Normal,matGeo);
	vout.wTangent = mul(vin.Tangent,matGeo);
	vout.wBitangent = mul(vin.Bitangent,matGeo);
	vout.UV = vin.UV;

	return vout;
}