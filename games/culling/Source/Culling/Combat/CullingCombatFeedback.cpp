#include "Combat/CullingCombatFeedback.h"
#include "Combat/CullingImpactFlash.h"
#include "Perf/CullingPerfBudgets.h"
#include "GameFramework/Actor.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "Kismet/GameplayStatics.h"
#include "Sound/SoundBase.h"

UCullingCombatFeedback::UCullingCombatFeedback()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void UCullingCombatFeedback::BeginLocalHitstop(AActor* Actor, float /*Seconds*/)
{
	if (!Actor)
	{
		return;
	}

	if (!CachedDilations.Contains(Actor))
	{
		CachedDilations.Add(Actor, Actor->CustomTimeDilation);
	}
	Actor->CustomTimeDilation = HitstopDilation;
	DilatedActors.AddUnique(Actor);
}

void UCullingCombatFeedback::EndLocalHitstop(AActor* Actor)
{
	if (!Actor)
	{
		return;
	}
	if (const float* Cached = CachedDilations.Find(Actor))
	{
		Actor->CustomTimeDilation = *Cached;
		CachedDilations.Remove(Actor);
	}
	else
	{
		Actor->CustomTimeDilation = 1.f;
	}
}

void UCullingCombatFeedback::PlayHitImpact(float HitstopSeconds, float InTrauma, AActor* OptionalVictim)
{
	CameraTrauma = FMath::Min(MaxTrauma, CameraTrauma + InTrauma);
	const bool bHeavy = InTrauma >= 0.35f;
	OnImpactFx(bHeavy, InTrauma);

	AActor* Owner = GetOwner();
	UWorld* World = GetWorld();
	if (World && Owner)
	{
		// Shipping-safe impact payload: mesh flash + light (engine BasicShapes, not DrawDebug/EditorSounds)
		const FVector ImpactLoc = OptionalVictim
			? OptionalVictim->GetActorLocation() + FVector(0.f, 0.f, 50.f)
			: Owner->GetActorLocation() + Owner->GetActorForwardVector() * 80.f + FVector(0.f, 0.f, 50.f);
		const float FlashR = bHeavy ? 55.f : 32.f;
		const FLinearColor FlashC = bHeavy
			? FLinearColor(1.f, 0.25f, 0.08f, 1.f)
			: FLinearColor(1.f, 0.85f, 0.25f, 1.f);

		// Enforce concurrent flash budget
		int32 LiveFlashes = 0;
		for (TActorIterator<ACullingImpactFlash> It(World); It; ++It)
		{
			++LiveFlashes;
		}
		if (LiveFlashes < CullingPerfBudgets::MaxConcurrentImpactFlashes)
		{
			FActorSpawnParameters Params;
			Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
			if (ACullingImpactFlash* Flash = World->SpawnActor<ACullingImpactFlash>(ACullingImpactFlash::StaticClass(), ImpactLoc, FRotator::ZeroRotator, Params))
			{
				const float Life = CullingPerfBudgets::ClampedFlashTime(
					bHeavy ? CullingPerfBudgets::DefaultHeavyFlashLife : CullingPerfBudgets::DefaultLightFlashLife);
				Flash->Configure(FlashR, FlashC, Life, bHeavy);
			}
		}

		// Prefer non-editor engine audio if present; skip silently if missing
		static const TCHAR* SoundCandidates[] = {
			TEXT("/Engine/VREditor/Sounds/UI/Collide_No_01.Collide_No_01"),
			TEXT("/Engine/EngineSounds/BaseSound.BaseSound"),
		};
		for (const TCHAR* Path : SoundCandidates)
		{
			if (USoundBase* Cue = LoadObject<USoundBase>(nullptr, Path))
			{
				UGameplayStatics::PlaySoundAtLocation(World, Cue, ImpactLoc, bHeavy ? 1.0f : 0.65f, bHeavy ? 0.75f : 1.15f);
				break;
			}
		}
	}

	if (HitstopSeconds <= 0.f || !World)
	{
		return;
	}

	HitstopEndRealTime = World->GetRealTimeSeconds() + HitstopSeconds;
	bHitstopActive = true;
	BeginLocalHitstop(Owner, HitstopSeconds);
	if (OptionalVictim && OptionalVictim != Owner)
	{
		BeginLocalHitstop(OptionalVictim, HitstopSeconds);
	}
}

void UCullingCombatFeedback::TickComponent(float DeltaTime, ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	float RealDt = DeltaTime;
	if (UWorld* World = GetWorld())
	{
		const float Now = World->GetRealTimeSeconds();
		if (LastRealTime > 0.f)
		{
			RealDt = FMath::Max(0.f, Now - LastRealTime);
		}
		LastRealTime = Now;

		if (bHitstopActive && Now >= HitstopEndRealTime)
		{
			bHitstopActive = false;
			for (const TWeakObjectPtr<AActor>& Weak : DilatedActors)
			{
				if (AActor* A = Weak.Get())
				{
					EndLocalHitstop(A);
				}
			}
			DilatedActors.Reset();
			CachedDilations.Reset();
		}
	}

	if (CameraTrauma > 0.f)
	{
		CameraTrauma = FMath::Max(0.f, CameraTrauma - TraumaDecayPerSecond * RealDt);
	}
}
