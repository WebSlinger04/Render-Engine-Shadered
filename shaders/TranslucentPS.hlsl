//tweakables
Texture2D texCA : register(t0);
SamplerState smp : register(s0);

//Buffer
struct InputData 
{
	float4 Color;
	float4 Position;
	float4 Direction;
	float4 extraData;
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

int LightLink;

PSOut main(PSInput pin)
{
	PSOut pout = (PSOut)0;
	
	//sample maps
	float2 uvMap = (pin.UV + float2(0,1)) * float2(0.1667,-0.5);
	float4 colorMap = texCA.Sample(smp,uvMap);
	colorMap.a = 0.3;
	
	float3 lightPos;
	float4 Diffuse;
	float4 DiffuseResult;
	for(int i = 0; i < 10; i++)
	{
		//stop after loop through all lights
		if (lightBuffer[i].Color.a == 0){
			break;
		}
		
		if (sign((lightBuffer[i].extraData.a) >= 0))
		{
			if(lightBuffer[i].extraData.a != 0 && lightBuffer[i].extraData.a != round((LightLink)))
			{
				continue;
			}		
		} else
		
		{
			if( lightBuffer[i].extraData.a == -round(LightLink))
			{
				continue;
			}	
		}
		
		//build vector
		lightPos = lightBuffer[i].Position.xyz;
		float3 lightVec = normalize(lightPos - pin.wPosition);
		
		//Diffuse Light
		float NdotL = dot(lightVec, pin.wNormal);
		float diffuseLight = saturate(abs(NdotL));
		Diffuse = diffuseLight * lightBuffer[i].Color;

		//Light attenuation
		float falloff = lightBuffer[i].extraData.x;
		float lightFalloff = 1/(pow(length(lightPos - pin.wPosition),2)) * falloff;
		float ConeAngle = lightBuffer[i].extraData.y;
		float SpotCone = saturate(pow(dot(lightVec,normalize(-lightBuffer[i].Direction.xyz)),ConeAngle));
		DiffuseResult += saturate(Diffuse * lightFalloff * SpotCone);
	}
	pout.Color = colorMap * float4(DiffuseResult.xyz,1);
	pout.Depth = pin.Position.a;
	return pout;
}
