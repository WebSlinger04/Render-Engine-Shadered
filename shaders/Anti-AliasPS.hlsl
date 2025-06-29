struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float2 screenSize;
};


Texture2D FinalPass : register(t0);
SamplerState smp : register(s0);



float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	return FinalPass.Sample(smp,pin.UV);
	float ReduceMul = 1/32;
	float ReduceMin = 1/128;
	float SpanMax = 8;

	float3 ConstantLuma = float3(0.299,0.587,0.114);
	float luma[5];
	float2 texel = 1/screenSize;
	float2 weights[5] = 
	{
		float2(0,0),
		float2(-0.5,-0.5),
		float2(0.5,-0.5),
		float2(-0.5,0.5),
		float2(0.5,0.5)
	};
	
	for(int i = 0; i<5; i++)
	{
		float3 Tex = FinalPass.Sample(smp,pin.UV + texel * weights[i]);
		luma[i] = dot(Tex,ConstantLuma);
	}
	
	float2 dir = float2( (luma[2]+luma[4]) - (luma[1] + luma[2]), (luma[1] + luma[3]) - (luma[2] + luma[4]) );
	float dirReduce = max( (luma[1] + luma[2] + luma[3] + luma[4]) * ReduceMin, ReduceMul);
	float rcpDir = 1 / (min(abs(dir.x),abs(dir.y)) + dirReduce);
	dir = clamp(dir * rcpDir, -SpanMax,SpanMax) * texel;
	
    float4 A = 0.5 * (
       FinalPass.Sample(smp, pin.UV - dir * (1.0/6.0)) +
       FinalPass.Sample(smp,pin.UV + dir * (1.0/6.0)));
       
    float4 B = A * 0.5 + 0.25 * (
        FinalPass.Sample(smp, pin.UV - dir * (0.5)) +
        FinalPass.Sample(smp, pin.UV + dir * (0.5)));
        
	float lumaMin = min(luma[0], min( min(luma[1],luma[2]), min(luma[3],luma[4])));
	float lumaMax = max(luma[0], max( max(luma[1],luma[2]), max(luma[3],luma[4])));
	
	float lumaB = dot(B.rgb,ConstantLuma);
	return ( (lumaB < lumaMin) || (lumaB > lumaMax)) ? A : B;
}