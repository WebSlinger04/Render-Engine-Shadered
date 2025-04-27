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
	float3 Normal = normalize(vin.lgtVector);
	float3 Tangent = normalize( cross(float3(0,1,0),Normal) );
	float3 Bitangent = normalize( cross(Normal,Tangent) );

	float4x4 TBN = float4x4(
	
	    float4(Tangent, 0),
	    float4(Bitangent, 0),
	    float4(Normal, 0),
	    float4(0, 0, 0, 1)
	
	); 

	
	VSOutput vout = (VSOutput)0;
	TBN = mul(TBN,matProject);
	vout.Position = mul(vin.Position - float4(vin.lgtPosition.xyz,0),TBN);

	return vout;
}