#include "Game/CullingGameMode.h"
#include "Character/CullingCharacter.h"
#include "UI/CullingHUD.h"
#include "UI/CullingVitalsWidget.h"
#include "Arena/CullingMeleeArena.h"
#include "GameFramework/PlayerStart.h"
#include "GameFramework/PlayerController.h"
#include "Blueprint/UserWidget.h"
#include "EngineUtils.h"
#include "Culling.h"

ACullingGameMode::ACullingGameMode()
{
	DefaultPawnClass = ACullingCharacter::StaticClass();
	HUDClass = ACullingHUD::StaticClass(); // fallback canvas; UMG vitals added at runtime
}

void ACullingGameMode::BeginPlay()
{
	Super::BeginPlay();
	EnsureArena();

	// SYS-UI: spawn pure-C++ UMG vitals for each local player
	for (FConstPlayerControllerIterator It = GetWorld()->GetPlayerControllerIterator(); It; ++It)
	{
		if (APlayerController* PC = It->Get())
		{
			if (PC->IsLocalController())
			{
				if (UCullingVitalsWidget* W = CreateWidget<UCullingVitalsWidget>(PC, UCullingVitalsWidget::StaticClass()))
				{
					W->AddToViewport(10);
					UE_LOG(LogCulling, Log, TEXT("Vitals UMG widget added to viewport"));
				}
			}
		}
	}
}

void ACullingGameMode::EnsureArena()
{
	if (Arena || !GetWorld())
	{
		return;
	}

	for (TActorIterator<ACullingMeleeArena> It(GetWorld()); It; ++It)
	{
		Arena = *It;
		break;
	}

	if (!Arena)
	{
		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		Arena = GetWorld()->SpawnActor<ACullingMeleeArena>(ACullingMeleeArena::StaticClass(), FTransform::Identity, Params);
		UE_LOG(LogCulling, Log, TEXT("GameMode spawned procedural MeleeArena"));
	}
}

AActor* ACullingGameMode::ChoosePlayerStart_Implementation(AController* Player)
{
	EnsureArena();
	// Prefer existing PlayerStart if any; else use arena marker via RestartPlayer teleport
	return Super::ChoosePlayerStart_Implementation(Player);
}

void ACullingGameMode::RestartPlayer(AController* NewPlayer)
{
	EnsureArena();
	Super::RestartPlayer(NewPlayer);

	if (Arena && NewPlayer)
	{
		if (APawn* Pawn = NewPlayer->GetPawn())
		{
			const FTransform SpawnXf = Arena->GetPlayerSpawnTransform();
			Pawn->SetActorLocationAndRotation(SpawnXf.GetLocation(), SpawnXf.GetRotation().Rotator(),
				false, nullptr, ETeleportType::ResetPhysics);
			NewPlayer->SetControlRotation(SpawnXf.Rotator());
			UE_LOG(LogCulling, Log, TEXT("Player teleported to MeleeArena south spawn"));
		}
	}
}
