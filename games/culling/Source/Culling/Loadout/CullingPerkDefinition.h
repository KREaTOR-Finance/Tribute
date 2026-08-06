#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "CullingPerkDefinition.generated.h"

/** SYS-LOADOUT: data-driven perk modifiers. */
UCLASS(BlueprintType)
class CULLING_API UCullingPerkDefinition : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FName PerkId = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FText DisplayName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FText Description;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mods")
	float MaxStaminaMul = 1.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mods")
	float StaminaRegenMul = 1.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mods")
	float DamageDealtMul = 1.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mods")
	float DamageTakenMul = 1.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mods")
	float HeavyWindupMul = 1.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mods")
	float MoveSpeedMul = 1.f;
};
