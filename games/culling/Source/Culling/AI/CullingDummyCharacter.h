#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "Combat/CullingCombatComponent.h"
#include "CullingDummyCharacter.generated.h"

class UCullingCombatComponent;
class UCullingCombatFeedback;
class UCullingWeaponProfile;
class UStaticMeshComponent;

/**
 * SYS-AI: Training dummy / sparring partner for MeleeTest.
 * Shares combat component so player hits are real.
 */
UCLASS()
class CULLING_API ACullingDummyCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	ACullingDummyCharacter();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling")
	TObjectPtr<UCullingCombatComponent> Combat;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling")
	TObjectPtr<UCullingCombatFeedback> Feedback;

	/** Hostile silhouette (engine sphere, red MID). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling")
	TObjectPtr<UStaticMeshComponent> BodyMesh;

	/** If true, periodically throws slow telegraphed lights for sparring. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|AI")
	bool bAutoSpar = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|AI")
	float SparIntervalSeconds = 2.4f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|AI")
	bool bResetOnDeath = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Culling|AI")
	float ResetDelaySeconds = 2.0f;

	UFUNCTION(BlueprintCallable, Category = "Culling|AI")
	void ResetDummy();

	UFUNCTION()
	void HandleMeleeStateChanged(ECullingMeleeState NewState);

protected:
	void ApplyStateTelegraph(ECullingMeleeState NewState);

	float SparCountdown = 0.f;
	float ResetCountdown = -1.f;
	int32 SparStep = 0;
	FVector SpawnLocation;
	FRotator SpawnRotation;
	FVector BodyBaseScale = FVector(0.7f, 0.7f, 1.6f);
};
