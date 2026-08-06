#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "CullingMeleeArena.generated.h"

class ACullingDummyCharacter;

/**
 * SYS-MAP: Procedural MeleeTest greybox — floor, walls, cover, dummy spawn.
 * Source-controlled; no binary .umap required for vertical slice.
 */
UCLASS()
class CULLING_API ACullingMeleeArena : public AActor
{
	GENERATED_BODY()

public:
	ACullingMeleeArena();

	virtual void OnConstruction(const FTransform& Transform) override;
	virtual void BeginPlay() override;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Arena")
	float FloorSizeCm = 2400.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Arena")
	float WallHeightCm = 400.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Arena")
	bool bSpawnDummy = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Arena")
	FVector PlayerSpawnLocal = FVector(0.f, -900.f, 100.f);

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Arena")
	FVector DummySpawnLocal = FVector(0.f, 900.f, 100.f);

	UFUNCTION(BlueprintCallable, Category = "Arena")
	FTransform GetPlayerSpawnTransform() const;

	UFUNCTION(BlueprintCallable, Category = "Arena")
	FTransform GetDummySpawnTransform() const;

protected:
	void BuildGeometry();
	void SpawnDummyIfNeeded();
	UStaticMeshComponent* AddBox(const FName& Name, const FVector& RelativeLoc, const FVector& Scale, const FLinearColor& Color);

	UPROPERTY()
	TObjectPtr<USceneComponent> Root;

	UPROPERTY()
	TArray<TObjectPtr<UStaticMeshComponent>> Pieces;

	UPROPERTY()
	TObjectPtr<ACullingDummyCharacter> SpawnedDummy;

	bool bBuilt = false;
};
