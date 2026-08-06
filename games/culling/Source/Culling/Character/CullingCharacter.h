#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "CullingCharacter.generated.h"

class UCullingCombatComponent;
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

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Culling|Data")
	TObjectPtr<UCullingMovementDefaults> MovementDefaults;

	UFUNCTION(BlueprintCallable, Category = "Culling")
	void ApplyMovementDefaults();

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

	void UpdateCombatMovementScalars();
};
