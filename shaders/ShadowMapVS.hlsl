cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
	float4x4 matProject;
};

struct VSInput
{
	float4 Position : POSITION;
		
	float4 lgtColor;
	float3 lgtPosition;
	float1 fill1;
	float3 lgtVector;
	

};

struct VSOutput
{
	float4 Position : SV_POSITION;
};

VSOutput main(VSInput vin)
{
	float3 lgtNormal = -normalize(vin.lgtVector.xyz * float3(-1,1,1));
	float3 lgtTangent = -normalize(cross(lgtNormal,float3(1,0,0)));
	float3 lgtBitangent = -normalize(cross(lgtNormal,lgtTangent));
	float4x4 newView = 
	{
		lgtBitangent.x,lgtBitangent.y,lgtBitangent.z,0,
		lgtTangent.x,lgtTangent.y,lgtTangent.z,0,
		lgtNormal.x,lgtNormal.y,lgtNormal.z,0,
		0,0,0,1
	};

	
	VSOutput vout = (VSOutput)0;
	newView = mul(newView,matProject);
	vout.Position = mul(vin.Position-float4(vin.lgtPosition.x,vin.lgtPosition.y,vin.lgtPosition.z,0),newView);
	return vout;
}