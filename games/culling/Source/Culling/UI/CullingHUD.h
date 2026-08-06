#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "CullingHUD.generated.h"

/**
 * SYS-UI: Minimal combat HUD — HP / Stamina / weapon / state.
 * Canvas draw for zero-asset vertical slice; replace with UMG later without changing data sources.
 */
UCLASS()
class CULLING_API ACullingHUD : public AHUD
{
	GENERATED_BODY()

public:
	virtual void DrawHUD() override;

protected:
	void DrawVitalsBar(float X, float Y, float W, float H, float Alpha, const FLinearColor& Fill, const FString& Label);
};
