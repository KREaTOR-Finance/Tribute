#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "CullingImpactFlash.generated.h"

/**
 * SYS-JUICE: shipping-safe impact flash using engine BasicShapes (not DrawDebug / EditorSounds).
 */
UCLASS()
class CULLING_API ACullingImpactFlash : public AActor
{
	GENERATED_BODY()

public:
	ACullingImpactFlash();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	void Configure(float Radius, const FLinearColor& Color, float LifetimeSeconds, bool bHeavy);

protected:
	UPROPERTY(VisibleAnywhere)
	TObjectPtr<UStaticMeshComponent> Mesh;

	UPROPERTY(VisibleAnywhere)
	TObjectPtr<class UPointLightComponent> Light;

	float Age = 0.f;
	float Lifetime = 0.12f;
	float StartScale = 0.2f;
	float EndScale = 0.8f;
	float StartLightIntensity = 4000.f;
	FLinearColor FlashColor = FLinearColor::White;
};
