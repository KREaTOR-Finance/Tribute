#include "Combat/CullingCombatFeedback.h"
#include "GameFramework/WorldSettings.h"
#include "Engine/World.h"

UCullingCombatFeedback::UCullingCombatFeedback()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void UCullingCombatFeedback::PlayHitImpact(float HitstopSeconds, float InTrauma)
{
	CameraTrauma = FMath::Min(MaxTrauma, CameraTrauma + InTrauma);

	if (HitstopSeconds <= 0.f)
	{
		return;
	}

	if (UWorld* World = GetWorld())
	{
		HitstopEndRealTime = World->GetRealTimeSeconds() + HitstopSeconds;
		if (AWorldSettings* Settings = World->GetWorldSettings())
		{
			if (!bHitstopActive)
			{
				CachedTimeDilation = Settings->TimeDilation;
				bHitstopActive = true;
			}
			Settings->SetTimeDilation(0.12f);
		}
	}
}

void UCullingCombatFeedback::TickComponent(float DeltaTime, ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// Decay trauma using real time so slow-mo does not freeze juice recovery forever
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
			if (AWorldSettings* Settings = World->GetWorldSettings())
			{
				Settings->SetTimeDilation(CachedTimeDilation > 0.f ? CachedTimeDilation : 1.f);
			}
		}
	}

	if (CameraTrauma > 0.f)
	{
		CameraTrauma = FMath::Max(0.f, CameraTrauma - TraumaDecayPerSecond * RealDt);
	}
}
