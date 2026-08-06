#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "CullingLoadoutComponent.generated.h"

class UCullingPerkDefinition;
class UCullingCombatComponent;

UCLASS(ClassGroup = (Culling), meta = (BlueprintSpawnableComponent))
class CULLING_API UCullingLoadoutComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UCullingLoadoutComponent();

	virtual void BeginPlay() override;

	UPROPERTY(BlueprintReadOnly, Category = "Loadout")
	TArray<TObjectPtr<UCullingPerkDefinition>> AvailablePerks;

	UPROPERTY(BlueprintReadOnly, Category = "Loadout")
	TObjectPtr<UCullingPerkDefinition> ActivePerk;

	UPROPERTY(BlueprintReadOnly, Category = "Loadout")
	TSet<FName> UnlockedPerkIds;

	UFUNCTION(BlueprintCallable, Category = "Loadout")
	void InitDefaultPerks();

	UFUNCTION(BlueprintCallable, Category = "Loadout")
	bool SelectPerkByIndex(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "Loadout")
	void UnlockPerk(FName PerkId);

	UFUNCTION(BlueprintCallable, Category = "Loadout")
	void ApplyActivePerkToCombat();

	UFUNCTION(BlueprintPure, Category = "Loadout")
	float GetDamageDealtMul() const;

	UFUNCTION(BlueprintPure, Category = "Loadout")
	float GetDamageTakenMul() const;

	UFUNCTION(BlueprintPure, Category = "Loadout")
	float GetMoveSpeedMul() const;

	UFUNCTION(BlueprintPure, Category = "Loadout")
	float GetHeavyWindupMul() const;

protected:
	UPROPERTY()
	float BaseMaxStamina = 100.f;

	UPROPERTY()
	float BaseStaminaRegen = 18.f;
};
