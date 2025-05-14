RWStructuredBuffer<float4> PositionBuffer : register(u0);

cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
	float4x4 matView;
};

struct VSInput
{
	float3 Position : POSITION;
	float3 Normal : NORMAL;
	float3 Tangent : TANGENT;
	float3 Bitangent : BITANGENT;
	float2 UV : TEXCOORD;
};

struct VSOutput
{
	float4 Position : SV_POSITION;
	float4 wPosition;
	float4 Color : COLOR;
	float3 wNormal;
	float3 wTangent;
	float3 wBitangent;
	float2 UV;
	
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
	vout.Color = 1;

	PositionBuffer.Append(vout.wPosition);
	return vout;
}