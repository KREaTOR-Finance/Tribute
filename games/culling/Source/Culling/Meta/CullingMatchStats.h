#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "CullingMatchStats.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FCullingMatchStatChanged, FName, StatName);

/** SYS-META: session stats for MeleeTest / future BR. */
UCLASS(ClassGroup = (Culling), meta = (BlueprintSpawnableComponent))
class CULLING_API UCullingMatchStats : public UActorComponent
{
	GENERATED_BODY()

public:
	UCullingMatchStats();

	UPROPERTY(BlueprintReadOnly, Category = "Meta")
	float DamageDealt = 0.f;

	UPROPERTY(BlueprintReadOnly, Category = "Meta")
	float DamageTaken = 0.f;

	UPROPERTY(BlueprintReadOnly, Category = "Meta")
	int32 Kills = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Meta")
	int32 Deaths = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Meta")
	int32 HitsLanded = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Meta")
	float MatchTimeSeconds = 0.f;

	UPROPERTY(BlueprintAssignable, Category = "Meta")
	FCullingMatchStatChanged OnStatChanged;

	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
		FActorComponentTickFunction* ThisTickFunction) override;

	UFUNCTION(BlueprintCallable, Category = "Meta")
	void RecordDamageDealt(float Amount);

	UFUNCTION(BlueprintCallable, Category = "Meta")
	void RecordDamageTaken(float Amount);

	UFUNCTION(BlueprintCallable, Category = "Meta")
	void RecordKill();

	UFUNCTION(BlueprintCallable, Category = "Meta")
	void RecordDeath();

	UFUNCTION(BlueprintCallable, Category = "Meta")
	void RecordHit();

	UFUNCTION(BlueprintPure, Category = "Meta")
	FString BuildSummaryLine() const;
};
