#include "Game/CullingGameMode.h"
#include "Character/CullingCharacter.h"

ACullingGameMode::ACullingGameMode()
{
	DefaultPawnClass = ACullingCharacter::StaticClass();
}
