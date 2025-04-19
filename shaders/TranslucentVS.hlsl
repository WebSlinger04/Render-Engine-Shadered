cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
};

struct VSInput
{
	float3 Position : POSITION;
	float3 Normal : NORMAL;
	float2 UV : TEXCOORD;
};

struct VSOutput
{
	float4 Position : SV_POSITION;
	float4 wPosition;
	float4 Color : COLOR;
	float3 wNormal;
	float2 UV;
	

	float3 camVec;
};

VSOutput main(VSInput vin)
{
	VSOutput vout = (VSOutput)0;

	vout.wPosition = mul(float4(vin.Position,1),matGeo);
	vout.Position = mul(mul(float4(vin.Position, 1.0f), matGeo), matVP);
	vout.wNormal = vin.Normal;
	vout.UV = vin.UV;
	vout.Color = 1;
	return vout;
}