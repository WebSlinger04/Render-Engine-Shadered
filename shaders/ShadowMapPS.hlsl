struct PSInput
{
	float4 Position : SV_POSITION;
};

struct PSOut
{
	float SM : SV_Target0;
};

PSOut main(PSInput pin)
{
	PSOut pout;
	pout.SM = pin.Position.a;
	return pout;
}
