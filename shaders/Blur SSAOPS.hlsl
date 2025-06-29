cbuffer cbPerFrame : register(b0)
{
	float2 screenSize;
	float4x4 matVP;
	float4x4 matView;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

Texture2D SceneAoNoise : register(t0);
SamplerState smp : register(s0);

float gaussian(float x, float sigma)
{
    return exp(-0.5 * (x * x) / (sigma * sigma));
}

float main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	float4 AO;

	//blur AO
	int size = 2;
	float2 texelSize = 1/screenSize;
	for (int y = -size ; y < size; y++)
	{
		for (int x = -size ; x < size; x++)
		{
		float2 offset = float2(x,y) * texelSize;;
		AO += (SceneAoNoise.Sample(smp, pin.UV + offset));
		}
	}

	return AO/pow(size*2,2);
}