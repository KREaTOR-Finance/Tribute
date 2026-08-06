#include "Loadout/CullingLoadoutComponent.h"
#include "Loadout/CullingPerkDefinition.h"
#include "Combat/CullingCombatComponent.h"

UCullingLoadoutComponent::UCullingLoadoutComponent()
{
	PrimaryComponentTick.bCanEverTick = false;
}

void UCullingLoadoutComponent::BeginPlay()
{
	Super::BeginPlay();
	InitDefaultPerks();
	UnlockedPerkIds.Add(FName(TEXT("berserker")));
	UnlockedPerkIds.Add(FName(TEXT("ironlung")));
	// scavenger unlocked via meta after first kill
	SelectPerkByIndex(0);
}

void UCullingLoadoutComponent::InitDefaultPerks()
{
	AvailablePerks.Reset();

	auto Make = [this](const TCHAR* Id, const TCHAR* Name, const TCHAR* Desc)
	{
		UCullingPerkDefinition* P = NewObject<UCullingPerkDefinition>(this, Id);
		P->PerkId = FName(Id);
		P->DisplayName = FText::FromString(Name);
		P->Description = FText::FromString(Desc);
		return P;
	};

	UCullingPerkDefinition* Berserk = Make(TEXT("berserker"), TEXT("Berserker"), TEXT("+damage, -defense, faster heavies"));
	Berserk->DamageDealtMul = 1.2f;
	Berserk->DamageTakenMul = 1.15f;
	Berserk->HeavyWindupMul = 0.88f;
	AvailablePerks.Add(Berserk);

	UCullingPerkDefinition* Iron = Make(TEXT("ironlung"), TEXT("Iron Lung"), TEXT("+stamina pool and regen"));
	Iron->MaxStaminaMul = 1.25f;
	Iron->StaminaRegenMul = 1.35f;
	AvailablePerks.Add(Iron);

	UCullingPerkDefinition* Scav = Make(TEXT("scavenger"), TEXT("Scavenger"), TEXT("+move speed for spacing"));
	Scav->MoveSpeedMul = 1.12f;
	Scav->StaminaRegenMul = 1.1f;
	AvailablePerks.Add(Scav);
}

bool UCullingLoadoutComponent::SelectPerkByIndex(int32 Index)
{
	if (!AvailablePerks.IsValidIndex(Index) || !AvailablePerks[Index])
	{
		return false;
	}
	UCullingPerkDefinition* P = AvailablePerks[Index];
	if (!UnlockedPerkIds.Contains(P->PerkId))
	{
		return false;
	}
	ActivePerk = P;
	ApplyActivePerkToCombat();
	return true;
}

void UCullingLoadoutComponent::UnlockPerk(FName PerkId)
{
	UnlockedPerkIds.Add(PerkId);
}

void UCullingLoadoutComponent::ApplyActivePerkToCombat()
{
	AActor* Owner = GetOwner();
	if (!Owner)
	{
		return;
	}
	UCullingCombatComponent* Combat = Owner->FindComponentByClass<UCullingCombatComponent>();
	if (!Combat)
	{
		return;
	}

	if (BaseMaxStamina <= 0.f)
	{
		BaseMaxStamina = Combat->MaxStamina;
		BaseStaminaRegen = Combat->StaminaRegenPerSecond;
	}

	const float MaxMul = ActivePerk ? ActivePerk->MaxStaminaMul : 1.f;
	const float RegenMul = ActivePerk ? ActivePerk->StaminaRegenMul : 1.f;
	Combat->MaxStamina = BaseMaxStamina * MaxMul;
	Combat->StaminaRegenPerSecond = BaseStaminaRegen * RegenMul;
	Combat->Stamina = FMath::Min(Combat->Stamina, Combat->MaxStamina);
}

float UCullingLoadoutComponent::GetDamageDealtMul() const
{
	return ActivePerk ? ActivePerk->DamageDealtMul : 1.f;
}

float UCullingLoadoutComponent::GetDamageTakenMul() const
{
	return ActivePerk ? ActivePerk->DamageTakenMul : 1.f;
}

float UCullingLoadoutComponent::GetMoveSpeedMul() const
{
	return ActivePerk ? ActivePerk->MoveSpeedMul : 1.f;
}

float UCullingLoadoutComponent::GetHeavyWindupMul() const
{
	return ActivePerk ? ActivePerk->HeavyWindupMul : 1.f;
}
