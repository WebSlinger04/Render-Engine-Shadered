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
};

struct VSOutput
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR;
	float2 UV;
	
	float3 wPosition;
	
};

VSOutput main(VSInput vin)
{
	VSOutput vout = (VSOutput)0;
	vout.Position = mul(mul(float4(vin.Position, 1.0f), matGeo), matVP);
	vout.wPosition = mul(float4(vin.Position,1),matGeo).xyz;
	vout.UV = vin.UV;
	vout.Color = 1;
	return vout;
}