#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "CullingGameMode.generated.h"

/**
 * Slice GameMode — guarantees ACullingCharacter possession (SYS-MOVE gap fix).
 */
UCLASS()
class CULLING_API ACullingGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	ACullingGameMode();
};
