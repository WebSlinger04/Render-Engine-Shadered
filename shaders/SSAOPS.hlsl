cbuffer cbPerFrame : register(b0)
{
	float2 screenSize;
	float4x4 matView;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

Texture2D Position : register(t0);
Texture2D Normal : register(t1);
Texture2D Noise : register(t2);
SamplerState smp : register(s0);


float randomNumber(float maxNumber)
{
	return 	frac(sin(maxNumber) * 43758.5453123);

}

float4 PP_AO = float4(.3,32,-.1,0);

float main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	float4 PositionPass = Position.Sample(smp, pin.UV);
	float3 Normal = Normal.Sample(smp, pin.UV);
	float3 Noise = Noise.Sample(smp,pin.UV*10);
	Normal = mul(float4(Normal,0),matView);
	Noise = Noise * 2 - 1;
	Noise.z = 0;

	//get viewspace tbn
	float3 N = normalize(Normal);
	float3 T = normalize(Noise - N * dot(Noise, N));
	float3 B = cross(N,T);
	float3x3 TBN = float3x3(T,B,N);
	
	
	//SSAO
	float ao = 0;
	float radius = PP_AO.x;
	float aoSamples = PP_AO.y;
	float bias = PP_AO.z;
	float depth = mul(float4(PositionPass.xyz,1),matView).z + bias;
		
	//hemishpere
	for (int i = 0; i < aoSamples ; i ++)
	{
		float3 random = float3(randomNumber(i) * 2 - 1,
						randomNumber(i + 12.3243463643) * 2 - 1,
						randomNumber(i + 34.1123352));

		//orient to TBN				
		random = mul(normalize(random),TBN);				
		//distribute points closer to center
		random *= randomNumber(i + 123.3434231);
		float scale = float(i)/aoSamples;
		random *= lerp(0.1,1, scale * scale);	
		random *= scale;
		
		//offset by screen pos
		float3 samplePos = random * radius;
		samplePos = samplePos + float3(pin.UV.xy,depth);

		//sample and depth check
		float textureOffset =  mul(float4(Position.Sample(smp, samplePos.xy).xyz,1),matView).z;
		float radiusCheck = smoothstep(0,1,radius/abs(depth-textureOffset));
		ao += ((textureOffset <= samplePos.z) ? 1 :0) * radiusCheck;

	}
	ao = 1-(ao/aoSamples) + PP_AO.w;
	return ao;
}