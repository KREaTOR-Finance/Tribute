#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "CullingGameMode.generated.h"

class ACullingMeleeArena;

/**
 * Tribune MeleeTest GameMode — pawn, HUD, procedural arena.
 */
UCLASS()
class CULLING_API ACullingGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	ACullingGameMode();

	virtual void BeginPlay() override;
	virtual AActor* ChoosePlayerStart_Implementation(AController* Player) override;
	virtual void RestartPlayer(AController* NewPlayer) override;

protected:
	void EnsureArena();

	UPROPERTY()
	TObjectPtr<ACullingMeleeArena> Arena;
};
