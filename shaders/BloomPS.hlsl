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

Texture2D EmissivePass : register(t0);
Texture2D LightingPass : register(t1);
SamplerState smp : register(s0);

float gaussian(float x, float sigma)
{
    return exp(-0.5 * (x * x) / (sigma * sigma));
}

float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;

	//Bloom
	float4 Emissive;
	float4 EmissiveLighting;

	float weightsum;
	int size = 1;
	float2 texelSize = 1/screenSize;
	float threshold = 0.8;

	//blur
	for (int y = -size ; y < size; y++)
	{
		for (int x = -size ; x < size; x++)
		{
		float2 offset = float2(x,y) * texelSize;
		float circle = length(float2(x,y));
		float weight = gaussian(circle,size);

		//Bloom due to emissive
		Emissive += (EmissivePass.Sample(smp, pin.UV + offset)) * weight;

		//Bloom due to screen luminosity
		EmissiveLighting = (LightingPass.Sample(smp,pin.UV + offset)) * weight;
		float Luminosity = (EmissiveLighting.x + EmissiveLighting.y + EmissiveLighting.z );
		Luminosity = Luminosity > threshold ? Luminosity : 0;
		Emissive += EmissiveLighting * Luminosity * .2; 
		weightsum += weight;
		}
	}

	return Emissive/weightsum * 3;
}