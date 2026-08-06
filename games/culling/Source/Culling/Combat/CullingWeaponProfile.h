#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "CullingWeaponProfile.generated.h"

/**
 * Data-driven melee weapon profile.
 * Gauntlet SYS-MELEE / SYS-WEAPON — logic reads this; presentation does not own numbers.
 */
UCLASS(BlueprintType)
class CULLING_API UCullingWeaponProfile : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Identity")
	FName WeaponId = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Identity")
	FText DisplayName;

	// --- Light ---
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light")
	float LightDamage = 12.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light")
	float LightRange = 150.f; // cm

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light")
	float LightActiveSeconds = 0.12f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light")
	float LightRecoverySeconds = 0.28f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light")
	float LightStaminaCost = 8.f;

	// --- Heavy (committed windup) ---
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Heavy")
	float HeavyDamage = 32.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Heavy")
	float HeavyRange = 170.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Heavy")
	float HeavyWindupSeconds = 0.45f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Heavy")
	float HeavyActiveSeconds = 0.15f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Heavy")
	float HeavyRecoverySeconds = 0.55f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Heavy")
	float HeavyStaminaCost = 22.f;

	// --- Block / shove ---
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Defense")
	float BlockDamageMultiplier = 0.25f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Defense")
	float BlockStaminaPerSecond = 12.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Defense")
	float ShoveImpulse = 600.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Defense")
	float ShoveStaminaCost = 18.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Defense")
	float ShoveRange = 120.f;

	// --- Feedback hooks (magnitudes; SYS-JUICE consumes) ---
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Juice")
	float LightHitstopSeconds = 0.04f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Juice")
	float HeavyHitstopSeconds = 0.09f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Juice")
	float LightCameraTrauma = 0.2f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Juice")
	float HeavyCameraTrauma = 0.45f;
};
