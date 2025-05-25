struct InputData 
{
	float4 Color;
	float4 Position;
	float4 Direction;
	float4 extraData;
};

StructuredBuffer<InputData> lightBuffer : register(u0);

cbuffer cbPerFrame : register(b0)
{
	float4x4 matGeo;
	float4x4 matProject;
	int lightIndex;
};

struct VSInput
{
	float4 Position : POSITION;

};

struct VSOutput
{
	float4 Position : SV_POSITION;
};

VSOutput main(VSInput vin)
{
	float3 lgtPosition = lightBuffer[lightIndex].Position.xyz;
	float3 lgtVector = lightBuffer[lightIndex].Direction.xyz;
	
	//lookat matrix
	float3 N = 4*normalize(lgtVector * -1);
	float3 T = normalize(cross(float3(0,1,0),N));
	float3 B = normalize(cross(N,T));
	float4x4 matLookAt = float4x4 (
		float4(T.x,B.x,N.x,0),
		float4(T.y,B.y,N.y,0),
		float4(T.z,B.z,N.z,0),
		dot(-lgtPosition,T),dot(-lgtPosition,B),dot(-lgtPosition,N),1
	
	);
	
	VSOutput vout = (VSOutput)0;
	vout.Position = mul(mul(vin.Position,matLookAt), matProject);

	return vout;
}