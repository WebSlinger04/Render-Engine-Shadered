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
	float4x4 matVP;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};



float4 main(PSInput pin) : SV_TARGET
{
	float4 lgtPosition =  mul(float4(lightBuffer[0].Position.xyz,1),matVP);
	float4 viewVector = mul(float4(lightBuffer[0].Direction,1),matVP);
	float3 ndcVector = viewVector.xyz / viewVector.w;
	float2 VectorUV = ndcVector.xy * 0.5 + 0.5;
	VectorUV = normalize(VectorUV);
	
	float3 ndcPos = lgtPosition.xyz / lgtPosition.w;
	float2 lgtUV = ndcPos.xy * 0.5 + 0.5;
	lgtUV.y = 1-lgtUV.y;
	pin.UV.x = 1 - pin.UV.x;
	
	float2 pixelVector = lgtUV-pin.UV;
	float volumetric = dot(pixelVector,viewVector);

	return volumetric;

}