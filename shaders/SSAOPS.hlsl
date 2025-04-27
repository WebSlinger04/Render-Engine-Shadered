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

Texture2D PositionPass : register(t0);
Texture2D randomNoise : register(t6);
SamplerState smp : register(s0);

float randomNumber(float maxNumber)
{
	return 	frac(sin(maxNumber) * 43758.5453123);

}

float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	float4 Position = PositionPass.Sample(smp, pin.UV);
	float4 Noise = randomNoise.Sample(smp,pin.UV*3);

	 //SSAO
	float ao = 0;
	float radius = 0.5 * Position.a;
	float aoSamples = 256;
		
	//random numbers
	float3 randomperKernel = Noise* 2 -1;
	randomperKernel = normalize(randomperKernel);

	for (int i = 0; i < aoSamples ; i ++)
	{
		float3 random = float3(randomNumber(i) * 2 - 1,
						randomNumber(i + 12.3243463643) * 2 - 1,
						randomNumber(i + 34.1123352) * 2 - 1);
						
	//distribute points closer to center
		random = normalize(random);
		//random = reflect(random,randomperKernel);
		random *= randomNumber(i + 123.3434231);
		float scale = float(i)/aoSamples;
		random *= lerp(0.1,1, scale * scale);	
		random *= scale;
		
		float3 samplePos = random * radius;
		samplePos = samplePos + float3(pin.UV.xy,Position.a);

		float textureOffset =  PositionPass.Sample(smp, samplePos.xy).a;
		ao += ((textureOffset >= samplePos.z) ? 1 :0);
		ao -= (distance(textureOffset, samplePos.z) > radius) ? 1 : 0;

	}
	ao = saturate(1 - (ao/aoSamples));
	ao = ao +.5;
	ao = saturate( pow(ao,10) );
	return ao;
}