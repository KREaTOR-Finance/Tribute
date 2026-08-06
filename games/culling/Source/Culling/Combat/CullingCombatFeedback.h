#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "CullingCombatFeedback.generated.h"

/**
 * SYS-JUICE: Local hitstop + camera trauma (not permanent global world dilation).
 * Applies CustomTimeDilation on owner (+ optional target) for multiplayer-safer feel.
 */
UCLASS(ClassGroup = (Culling), meta = (BlueprintSpawnableComponent))
class CULLING_API UCullingCombatFeedback : public UActorComponent
{
	GENERATED_BODY()

public:
	UCullingCombatFeedback();

	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
		FActorComponentTickFunction* ThisTickFunction) override;

	/** Hitstop + trauma on confirmed connect. Optionally slow the victim too. */
	UFUNCTION(BlueprintCallable, Category = "Culling|Juice")
	void PlayHitImpact(float HitstopSeconds, float CameraTrauma, AActor* OptionalVictim = nullptr);

	UPROPERTY(BlueprintReadOnly, Category = "Culling|Juice")
	float CameraTrauma = 0.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|Juice")
	float TraumaDecayPerSecond = 1.2f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|Juice")
	float MaxTrauma = 1.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|Juice")
	float HitstopDilation = 0.12f;

	/** Hook for audio — null-safe. */
	UFUNCTION(BlueprintImplementableEvent, Category = "Culling|Juice")
	void OnImpactFx(bool bHeavy, float Trauma);

protected:
	void BeginLocalHitstop(AActor* Actor, float Seconds);
	void EndLocalHitstop(AActor* Actor);

	bool bHitstopActive = false;
	float HitstopEndRealTime = 0.f;
	float LastRealTime = 0.f;

	UPROPERTY()
	TArray<TWeakObjectPtr<AActor>> DilatedActors;

	TMap<TWeakObjectPtr<AActor>, float> CachedDilations;
};
