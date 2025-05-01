cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
	float4x4 matView;
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
	//lookat matrix
	float3 N = normalize(vin.lgtVector * -1);
	float3 T = normalize(cross(float3(0,1,0),N));
	float3 B = normalize(cross(N,T));
	float4x4 matLookAt = float4x4 (
		float4(T.x,B.x,N.x,0),
		float4(T.y,B.y,N.y,0),
		float4(T.z,B.z,N.z,0),
		dot(-vin.lgtPosition,T),dot(-vin.lgtPosition,B),dot(-vin.lgtPosition,N),1
	
	);


	//ortho projection matrix
	float width = 5;
	float height = 5;
	float nearPlane = 0;
	float farPlane = 100;
	float4x4 matCustomOrtho = 
	{
		1/width,0,0,0,
		0,1/height,0,0,
		0,0,-2/(farPlane-nearPlane),0,
		0,0,-(farPlane+nearPlane)/(farPlane-nearPlane),1
	
	};
	
	VSOutput vout = (VSOutput)0;
	vout.Position = mul( mul( vin.Position,matLookAt ) , matCustomOrtho);
	vout.Position = mul(mul(vin.Position,matLookAt),matProject);

	return vout;
}