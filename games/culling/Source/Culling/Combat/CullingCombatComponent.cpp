#include "Combat/CullingCombatComponent.h"
#include "Combat/CullingWeaponProfile.h"
#include "Combat/CullingCombatFeedback.h"
#include "Loadout/CullingLoadoutComponent.h"
#include "Meta/CullingMatchStats.h"
#include "Culling.h"
#include "GameFramework/Actor.h"
#include "GameFramework/Character.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Engine/World.h"

UCullingCombatComponent::UCullingCombatComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void UCullingCombatComponent::BeginPlay()
{
	Super::BeginPlay();
	Health = MaxHealth;
	Stamina = MaxStamina;
	SetMeleeState(ECullingMeleeState::Idle);
	if (!Feedback && GetOwner())
	{
		Feedback = GetOwner()->FindComponentByClass<UCullingCombatFeedback>();
	}
	// Runtime fallback profile so combat is not dead without Content DA (slice bootstrap).
	if (!WeaponProfile)
	{
		WeaponProfile = NewObject<UCullingWeaponProfile>(this, TEXT("RuntimeDefaultFist"));
		WeaponProfile->WeaponId = FName(TEXT("fist"));
		WeaponProfile->LightDamage = 12.f;
		WeaponProfile->HeavyDamage = 28.f;
		WeaponProfile->LightRange = 140.f;
		WeaponProfile->HeavyRange = 155.f;
		WeaponProfile->HeavyWindupSeconds = 0.42f;
		WeaponProfile->LightHitstopSeconds = 0.045f;
		WeaponProfile->HeavyHitstopSeconds = 0.09f;
		WeaponProfile->LightCameraTrauma = 0.22f;
		WeaponProfile->HeavyCameraTrauma = 0.48f;
		WeaponProfile->HitSphereRadius = 34.f;
	}
}

void UCullingCombatComponent::TickComponent(float DeltaTime, ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (!IsAlive())
	{
		return;
	}

	AdvanceStateTimer(DeltaTime);

	// Block drains stamina while held
	if (MeleeState == ECullingMeleeState::Blocking && WeaponProfile)
	{
		const float Drain = WeaponProfile->BlockStaminaPerSecond * DeltaTime;
		Stamina = FMath::Max(0.f, Stamina - Drain);
		TimeSinceStaminaSpend = 0.f;
		if (Stamina <= 0.f)
		{
			TrySetBlocking(false);
		}
	}

	// Active frames: continuous trace so short windows still connect
	if (MeleeState == ECullingMeleeState::LightActive)
	{
		PerformHitTrace(false);
	}
	else if (MeleeState == ECullingMeleeState::HeavyActive)
	{
		PerformHitTrace(true);
	}

	// Stamina regen after delay when idle-ish
	TimeSinceStaminaSpend += DeltaTime;
	const bool bBusy = MeleeState == ECullingMeleeState::LightActive
		|| MeleeState == ECullingMeleeState::HeavyWindup
		|| MeleeState == ECullingMeleeState::HeavyActive
		|| MeleeState == ECullingMeleeState::Blocking
		|| MeleeState == ECullingMeleeState::Shoving;

	if (!bBusy && TimeSinceStaminaSpend >= StaminaRegenDelay)
	{
		Stamina = FMath::Min(MaxStamina, Stamina + StaminaRegenPerSecond * DeltaTime);
	}
}

void UCullingCombatComponent::SetMeleeState(ECullingMeleeState NewState)
{
	if (MeleeState == NewState)
	{
		return;
	}
	MeleeState = NewState;
	OnMeleeStateChanged.Broadcast(NewState);
}

bool UCullingCombatComponent::CanAct() const
{
	return IsAlive()
		&& (MeleeState == ECullingMeleeState::Idle
			|| MeleeState == ECullingMeleeState::LightRecovery
			|| MeleeState == ECullingMeleeState::HeavyRecovery);
}

bool UCullingCombatComponent::ConsumeStamina(float Cost)
{
	if (Stamina < Cost)
	{
		return false;
	}
	Stamina -= Cost;
	TimeSinceStaminaSpend = 0.f;
	return true;
}

bool UCullingCombatComponent::TryLightAttack()
{
	if (!WeaponProfile || !CanAct())
	{
		return false;
	}
	if (!ConsumeStamina(WeaponProfile->LightStaminaCost))
	{
		return false;
	}

	HitActorsThisSwing.Reset();
	SetMeleeState(ECullingMeleeState::LightActive);
	StateTimeRemaining = WeaponProfile->LightActiveSeconds;
	return true;
}

bool UCullingCombatComponent::TryStartHeavy()
{
	if (!WeaponProfile || !CanAct())
	{
		return false;
	}
	if (!ConsumeStamina(WeaponProfile->HeavyStaminaCost))
	{
		return false;
	}

	bHeavyHeld = true;
	HitActorsThisSwing.Reset();
	SetMeleeState(ECullingMeleeState::HeavyWindup);
	float Windup = WeaponProfile->HeavyWindupSeconds;
	if (const UCullingLoadoutComponent* Loadout = GetOwner() ? GetOwner()->FindComponentByClass<UCullingLoadoutComponent>() : nullptr)
	{
		Windup *= Loadout->GetHeavyWindupMul();
	}
	StateTimeRemaining = Windup;
	return true;
}

void UCullingCombatComponent::ReleaseHeavy()
{
	bHeavyHeld = false;
	// v0: no early cancel mid-windup — commitment is the Culling fantasy
}

bool UCullingCombatComponent::TrySetBlocking(bool bBlock)
{
	if (!IsAlive() || !WeaponProfile)
	{
		return false;
	}

	if (bBlock)
	{
		if (MeleeState != ECullingMeleeState::Idle && MeleeState != ECullingMeleeState::LightRecovery
			&& MeleeState != ECullingMeleeState::HeavyRecovery)
		{
			return false;
		}
		if (Stamina <= 0.f)
		{
			return false;
		}
		SetMeleeState(ECullingMeleeState::Blocking);
		StateTimeRemaining = 0.f;
		return true;
	}

	if (MeleeState == ECullingMeleeState::Blocking)
	{
		SetMeleeState(ECullingMeleeState::Idle);
	}
	return true;
}

bool UCullingCombatComponent::TryShove()
{
	if (!WeaponProfile || !CanAct())
	{
		return false;
	}
	if (!ConsumeStamina(WeaponProfile->ShoveStaminaCost))
	{
		return false;
	}

	HitActorsThisSwing.Reset();
	SetMeleeState(ECullingMeleeState::Shoving);
	StateTimeRemaining = 0.2f;

	// Simple forward impulse query
	AActor* Owner = GetOwner();
	if (!Owner)
	{
		return true;
	}

	const FVector Start = Owner->GetActorLocation();
	const FVector End = Start + Owner->GetActorForwardVector() * WeaponProfile->ShoveRange;
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(CullingShove), false, Owner);
	if (GetWorld()->LineTraceSingleByChannel(Hit, Start, End, ECC_Pawn, Params))
	{
		if (AActor* Other = Hit.GetActor())
		{
			const FVector Launch = Owner->GetActorForwardVector() * WeaponProfile->ShoveImpulse * 0.35f + FVector(0.f, 0.f, 120.f);
			if (ACharacter* OtherChar = Cast<ACharacter>(Other))
			{
				OtherChar->LaunchCharacter(Launch, true, true);
			}
			else if (UPrimitiveComponent* Root = Cast<UPrimitiveComponent>(Other->GetRootComponent()))
			{
				Root->AddImpulse(Owner->GetActorForwardVector() * WeaponProfile->ShoveImpulse, NAME_None, true);
			}
		}
	}
	return true;
}

void UCullingCombatComponent::ForceRevive()
{
	Health = MaxHealth;
	Stamina = MaxStamina;
	HitActorsThisSwing.Reset();
	StateTimeRemaining = 0.f;
	SetMeleeState(ECullingMeleeState::Idle);
}

void UCullingCombatComponent::ApplyDamage(float Amount, AActor* InstigatorActor, bool bFromHeavy)
{
	if (!IsAlive())
	{
		return;
	}

	float Final = Amount;
	if (MeleeState == ECullingMeleeState::Blocking && WeaponProfile)
	{
		Final *= WeaponProfile->BlockDamageMultiplier;
	}
	if (const UCullingLoadoutComponent* SelfLoadout = GetOwner() ? GetOwner()->FindComponentByClass<UCullingLoadoutComponent>() : nullptr)
	{
		Final *= SelfLoadout->GetDamageTakenMul();
	}

	Health = FMath::Max(0.f, Health - Final);
	if (UCullingMatchStats* Stats = GetOwner() ? GetOwner()->FindComponentByClass<UCullingMatchStats>() : nullptr)
	{
		Stats->RecordDamageTaken(Final);
	}
	if (Health <= 0.f)
	{
		SetMeleeState(ECullingMeleeState::Dead);
		StateTimeRemaining = 0.f;
		if (UCullingMatchStats* Stats = GetOwner() ? GetOwner()->FindComponentByClass<UCullingMatchStats>() : nullptr)
		{
			Stats->RecordDeath();
		}
	}
}

void UCullingCombatComponent::PerformHitTrace(bool bHeavy)
{
	AActor* Owner = GetOwner();
	if (!Owner || !WeaponProfile)
	{
		return;
	}

	const float Range = bHeavy ? WeaponProfile->HeavyRange : WeaponProfile->LightRange;
	float Damage = bHeavy ? WeaponProfile->HeavyDamage : WeaponProfile->LightDamage;
	if (const UCullingLoadoutComponent* Loadout = Owner->FindComponentByClass<UCullingLoadoutComponent>())
	{
		Damage *= Loadout->GetDamageDealtMul();
	}
	const FVector Start = Owner->GetActorLocation() + FVector(0, 0, 40.f);
	const FVector End = Start + Owner->GetActorForwardVector() * Range;

	TArray<FHitResult> Hits;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(CullingMelee), false, Owner);
	const float Radius = WeaponProfile->HitSphereRadius > 0.f ? WeaponProfile->HitSphereRadius : 40.f;
	GetWorld()->SweepMultiByChannel(Hits, Start, End, FQuat::Identity, ECC_Pawn,
		FCollisionShape::MakeSphere(Radius), Params);

	for (const FHitResult& Hit : Hits)
	{
		AActor* Other = Hit.GetActor();
		if (!Other || Other == Owner)
		{
			continue;
		}
		if (HitActorsThisSwing.Contains(Other))
		{
			continue;
		}
		HitActorsThisSwing.Add(Other);

		if (UCullingCombatComponent* OtherCombat = Other->FindComponentByClass<UCullingCombatComponent>())
		{
			OtherCombat->ApplyDamage(Damage, Owner, bHeavy);
		}
		OnHitLanded.Broadcast(Other, Damage, bHeavy);

		// SYS-MELEE + SYS-JUICE: hit feedback on connect with local hitstop on attacker + victim
		if (Feedback && WeaponProfile)
		{
			const float Hitstop = bHeavy ? WeaponProfile->HeavyHitstopSeconds : WeaponProfile->LightHitstopSeconds;
			const float Trauma = bHeavy ? WeaponProfile->HeavyCameraTrauma : WeaponProfile->LightCameraTrauma;
			Feedback->PlayHitImpact(Hitstop, Trauma, Other);
		}
	}
}

void UCullingCombatComponent::AdvanceStateTimer(float DeltaTime)
{
	if (MeleeState == ECullingMeleeState::Idle
		|| MeleeState == ECullingMeleeState::Blocking
		|| MeleeState == ECullingMeleeState::Dead
		|| MeleeState == ECullingMeleeState::Stunned)
	{
		return;
	}

	StateTimeRemaining -= DeltaTime;
	if (StateTimeRemaining > 0.f)
	{
		return;
	}

	switch (MeleeState)
	{
	case ECullingMeleeState::LightActive:
		SetMeleeState(ECullingMeleeState::LightRecovery);
		StateTimeRemaining = WeaponProfile ? WeaponProfile->LightRecoverySeconds : 0.2f;
		break;
	case ECullingMeleeState::LightRecovery:
		SetMeleeState(ECullingMeleeState::Idle);
		StateTimeRemaining = 0.f;
		break;
	case ECullingMeleeState::HeavyWindup:
		SetMeleeState(ECullingMeleeState::HeavyActive);
		StateTimeRemaining = WeaponProfile ? WeaponProfile->HeavyActiveSeconds : 0.1f;
		HitActorsThisSwing.Reset();
		break;
	case ECullingMeleeState::HeavyActive:
		SetMeleeState(ECullingMeleeState::HeavyRecovery);
		StateTimeRemaining = WeaponProfile ? WeaponProfile->HeavyRecoverySeconds : 0.4f;
		break;
	case ECullingMeleeState::HeavyRecovery:
		SetMeleeState(ECullingMeleeState::Idle);
		StateTimeRemaining = 0.f;
		break;
	case ECullingMeleeState::Shoving:
		SetMeleeState(ECullingMeleeState::Idle);
		StateTimeRemaining = 0.f;
		break;
	default:
		break;
	}
}
