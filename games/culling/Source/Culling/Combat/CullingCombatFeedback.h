#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "CullingCombatFeedback.generated.h"

/**
 * Minimal SYS-JUICE hooks used by SYS-MELEE on connect.
 * Hitstop via custom time dilation on owner world settings / local slow;
 * camera trauma is stored for the camera boom consumer.
 */
UCLASS(ClassGroup = (Culling), meta = (BlueprintSpawnableComponent))
class CULLING_API UCullingCombatFeedback : public UActorComponent
{
	GENERATED_BODY()

public:
	UCullingCombatFeedback();

	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
		FActorComponentTickFunction* ThisTickFunction) override;

	/** Apply hitstop + trauma. Call only on confirmed hit. */
	UFUNCTION(BlueprintCallable, Category = "Culling|Juice")
	void PlayHitImpact(float HitstopSeconds, float CameraTrauma);

	UPROPERTY(BlueprintReadOnly, Category = "Culling|Juice")
	float CameraTrauma = 0.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|Juice")
	float TraumaDecayPerSecond = 1.2f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|Juice")
	float MaxTrauma = 1.f;

protected:
	bool bHitstopActive = false;
	float HitstopEndRealTime = 0.f;
	float CachedTimeDilation = 1.f;
	float LastRealTime = 0.f;
};
