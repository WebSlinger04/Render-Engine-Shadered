struct PSInput
{
	float4 Position : SV_POSITION;
};

float4 main(PSInput pin)
{
	return pin.Position.w;
}
