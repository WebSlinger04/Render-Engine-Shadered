//tweakables
Texture2D texCA : register(t0);
SamplerState smp : register(s0);
float2 TextureTile;

//Buffer
struct InputData 

{	float4 Color;
	float3 Position;
	float Strength;
	float3 Direction;
	float Falloff;
};
StructuredBuffer<InputData> lightBuffer : register(u0);

struct PSInput
{
	float4 Position : SV_POSITION;
	float4 wPosition;
	float4 Color : COLOR;
	float3 wNormal;
	float2 UV;
};

struct PSOut
{
	float4 Color;
	float4 Depth;
	
};

PSOut main(PSInput pin)
{
	PSOut pout = (PSOut)0;
	
	//sample maps
	float4 colorMap = texCA.Sample(smp,pin.UV*TextureTile);
	colorMap = (1,1,1,0.5);
	
	float3 lightPos;
	float4 Diffuse;
	float4 DiffuseResult;
	for(int i = 0; i < 10; i++)
	{
		//stop after loop through all lights
		if (lightBuffer[i].Color.a == 0){
			break;
		}
		//build vector
		lightPos = lightBuffer[i].Position.xyz;
		float3 lightVec = normalize(lightPos - pin.wPosition);
		
		//Diffuse Light
		float NdotL = dot(lightVec, pin.wNormal);
		float diffuseLight = saturate(abs(NdotL));
		Diffuse = diffuseLight * lightBuffer[i].Color;
		//Light attenuation
		float falloff = lightBuffer[i].Strength;
		float lightFalloff = 1/(pow(length(lightVec),2)) * falloff;
		float ConeAngle = lightBuffer[i].Falloff;
		float SpotCone = saturate(pow(dot(lightVec,normalize(-lightBuffer[i].Direction.xyz)),ConeAngle));
		DiffuseResult += saturate(Diffuse * lightFalloff * SpotCone);
	}
	pout.Color = colorMap * float4(DiffuseResult.xyz,1);
	pout.Depth = pin.Position.a;
	return pout;
}
