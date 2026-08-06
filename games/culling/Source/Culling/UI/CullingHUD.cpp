#include "UI/CullingHUD.h"
#include "Engine/Canvas.h"

void ACullingHUD::DrawVitalsBar(float, float, float, float, float, const FLinearColor&, const FString&)
{
	// Vitals live on UCullingVitalsWidget (UMG). Canvas path retired to avoid dual-stack.
}

void ACullingHUD::DrawHUD()
{
	Super::DrawHUD();
	// Keep empty: UMG vitals are authoritative (SYS-UI critic residual closed).
}
