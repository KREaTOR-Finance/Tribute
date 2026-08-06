#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "CullingCombatComponent.generated.h"

class UCullingWeaponProfile;
class UCullingCombatFeedback;

UENUM(BlueprintType)
enum class ECullingMeleeState : uint8
{
	Idle,
	LightActive,
	LightRecovery,
	HeavyWindup,
	HeavyActive,
	HeavyRecovery,
	Blocking,
	Shoving,
	Stunned,
	Dead
};

DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FCullingHitLanded, AActor*, Target, float, Damage, bool, bHeavy);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FCullingMeleeStateChanged, ECullingMeleeState, NewState);

/**
 * Core melee state machine — SYS-MELEE.
 * Presentation listens to delegates; does not own damage numbers.
 */
UCLASS(ClassGroup = (Culling), meta = (BlueprintSpawnableComponent))
class CULLING_API UCullingCombatComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UCullingCombatComponent();

	virtual void BeginPlay() override;
	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
		FActorComponentTickFunction* ThisTickFunction) override;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
	TObjectPtr<UCullingWeaponProfile> WeaponProfile;

	/** Optional; if null, searched on owner at BeginPlay. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
	TObjectPtr<UCullingCombatFeedback> Feedback;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Vitals")
	float MaxHealth = 100.f;

	UPROPERTY(BlueprintReadOnly, Category = "Vitals")
	float Health = 100.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Vitals")
	float MaxStamina = 100.f;

	UPROPERTY(BlueprintReadOnly, Category = "Vitals")
	float Stamina = 100.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Vitals")
	float StaminaRegenPerSecond = 18.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Vitals")
	float StaminaRegenDelay = 0.35f;

	UPROPERTY(BlueprintReadOnly, Category = "Combat")
	ECullingMeleeState MeleeState = ECullingMeleeState::Idle;

	UPROPERTY(BlueprintAssignable, Category = "Combat|Events")
	FCullingHitLanded OnHitLanded;

	UPROPERTY(BlueprintAssignable, Category = "Combat|Events")
	FCullingMeleeStateChanged OnMeleeStateChanged;

	UFUNCTION(BlueprintCallable, Category = "Combat")
	bool TryLightAttack();

	UFUNCTION(BlueprintCallable, Category = "Combat")
	bool TryStartHeavy();

	UFUNCTION(BlueprintCallable, Category = "Combat")
	void ReleaseHeavy(); // optional early release policy later

	UFUNCTION(BlueprintCallable, Category = "Combat")
	bool TrySetBlocking(bool bBlock);

	UFUNCTION(BlueprintCallable, Category = "Combat")
	bool TryShove();

	UFUNCTION(BlueprintCallable, Category = "Combat")
	void ApplyDamage(float Amount, AActor* InstigatorActor, bool bFromHeavy);

	UFUNCTION(BlueprintPure, Category = "Combat")
	bool IsAlive() const { return MeleeState != ECullingMeleeState::Dead && Health > 0.f; }

	/** Training dummy / round reset — restores vitals and Idle. */
	UFUNCTION(BlueprintCallable, Category = "Combat")
	void ForceRevive();

protected:
	void SetMeleeState(ECullingMeleeState NewState);
	bool CanAct() const;
	bool ConsumeStamina(float Cost);
	void PerformHitTrace(bool bHeavy);
	void AdvanceStateTimer(float DeltaTime);

	float StateTimeRemaining = 0.f;
	float TimeSinceStaminaSpend = 0.f;
	bool bHeavyHeld = false;
	TSet<TWeakObjectPtr<AActor>> HitActorsThisSwing;
};
