cbuffer cbPerFrame : register(b0)
{
	float2 screenSize;
	float4x4 matVP;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

Texture2D PositionPass : register(t0);
Texture2D NormalPass : register(t1);
Texture2D NoisePass : register(t2);
SamplerState smp : register(s0);


float randomNumber(float maxNumber)
{
	return 	frac(sin(maxNumber) * 43758.5453123);

}

float main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	float4 Position = PositionPass.Sample(smp, pin.UV);
	float3 Normal = NormalPass.Sample(smp, pin.UV);
	float3 Noise = (NoisePass.Sample(smp,pin.UV*10));
	Normal = mul(Normal,matVP);
	Noise = Noise * 2 - 1;
	Noise.z = 0;
	float3 N = normalize(Normal);
	float3 T = normalize(Noise - N * dot(Noise, N));
	//T = cross(N,float3(0,1,0));
	float3 B = cross(N,T);
	
	float3x3 TBN = float3x3(T,B,N);
	
	
	 //SSAO
	float ao = 0;
	float radius = .1;
	float aoSamples = 124;
	float bias = -.01;
	float depth = mul(Position,matVP).z + bias;
		
	//random numbers

	for (int i = 0; i < aoSamples ; i ++)
	{
		float3 random = float3(randomNumber(i) * 2 - 1,
						randomNumber(i + 12.3243463643) * 2 - 1,
						randomNumber(i + 34.1123352));
						
		//distribute points closer to center
		random = mul(random,TBN);
		random = normalize(random);
		random *= randomNumber(i + 123.3434231);
		float scale = float(i)/aoSamples;
		random *= lerp(0.1,1, scale * scale);	
		random *= scale;
		
		float3 samplePos = random * radius;
		samplePos = samplePos + float3(pin.UV.xy,depth);



		float textureOffset =  mul(PositionPass.Sample(smp, samplePos.xy),matVP).z;
		float radiusCheck = smoothstep(0,1,radius/abs(depth-textureOffset));
		ao += ((textureOffset <= samplePos.z) ? 1 :0) * radiusCheck;

	}
	ao = 1-saturate(ao/aoSamples);
	ao = saturate( pow(ao,1.3) );
	return ao;
}