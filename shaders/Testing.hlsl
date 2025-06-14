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
	float2 UV : TEXCOORD
};

float4 main(PSInput pin) : SV_TARGET
{
	float4 Result;
	int maxLights = 16;
	for(int i = 0; i < maxLights; i++)
	{

		Result += //calculate lighting;
	}

	return Result;
}




