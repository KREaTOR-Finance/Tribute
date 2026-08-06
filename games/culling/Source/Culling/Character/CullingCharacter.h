#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "Combat/CullingCombatComponent.h"
#include "CullingCharacter.generated.h"

class UCullingCombatFeedback;
class UCullingMovementDefaults;
class USpringArmComponent;
class UCameraComponent;

/**
 * Hunter pawn shell — wires movement defaults + combat component.
 * Visual mesh is presentation; combat logic is independent.
 */
UCLASS()
class CULLING_API ACullingCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	ACullingCharacter();

	virtual void BeginPlay() override;
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;
	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling")
	TObjectPtr<UCullingCombatComponent> Combat;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling")
	TObjectPtr<UCullingCombatFeedback> Feedback;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling|Camera")
	TObjectPtr<USpringArmComponent> CameraBoom;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling|Camera")
	TObjectPtr<UCameraComponent> FollowCamera;

	/** Procedural weapon stick — identity by profile length/color. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling|Weapon")
	TObjectPtr<class UStaticMeshComponent> WeaponMesh;

	/** Player hunter silhouette (engine mesh). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling")
	TObjectPtr<class UStaticMeshComponent> BodyMesh;

	/** Readable heavy windup / block telegraph light. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Culling|Juice")
	TObjectPtr<class UPointLightComponent> TelegraphLight;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Culling|Data")
	TObjectPtr<UCullingMovementDefaults> MovementDefaults;

	UFUNCTION(BlueprintCallable, Category = "Culling")
	void ApplyMovementDefaults();

	UFUNCTION(BlueprintCallable, Category = "Culling|Weapon")
	void SelectWeaponSlot(int32 SlotIndex);

protected:
	void MoveForward(float Value);
	void MoveRight(float Value);
	void LookYaw(float Value);
	void LookPitch(float Value);
	void OnLightAttack();
	void OnHeavyPressed();
	void OnHeavyReleased();
	void OnBlockPressed();
	void OnBlockReleased();
	void OnShove();
	void OnWeapon1();
	void OnWeapon2();
	void OnWeapon3();

	void InitDefaultWeapons();
	void RefreshWeaponVisual();
	void UpdateCombatMovementScalars();

	UFUNCTION()
	void HandleMeleeStateChanged(ECullingMeleeState NewState);

	void ApplyStateTelegraph(ECullingMeleeState NewState);

	UPROPERTY()
	TArray<TObjectPtr<class UCullingWeaponProfile>> WeaponSlots;

	int32 ActiveWeaponSlot = 0;
};
