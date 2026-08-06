#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "CullingMovementDefaults.generated.h"

/**
 * Data-driven movement/camera tuning — SYS-MOVE.
 * Apply onto CharacterMovementComponent + camera boom from Blueprint or pawn setup.
 */
UCLASS(BlueprintType)
class CULLING_API UCullingMovementDefaults : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Walk")
	float MaxWalkSpeed = 480.f; // cm/s — weighty mid-pace

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Walk")
	float MaxAcceleration = 1600.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Walk")
	float BrakingDecelerationWalking = 1400.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Walk")
	float GroundFriction = 8.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Walk")
	float RotationRateYaw = 480.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Walk")
	bool bOrientRotationToMovement = true;

	// Third-person combat camera (default for melee reads)
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Camera")
	float CameraArmLength = 280.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Camera")
	FVector CameraSocketOffset = FVector(0.f, 55.f, 55.f);

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Camera")
	float CameraLagSpeed = 12.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Camera")
	bool bEnableCameraLag = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Camera")
	float MouseSensitivityPitch = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Camera")
	float MouseSensitivityYaw = 1.0f;

	// Combat movement constraints
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "CombatMove")
	float BlockMoveSpeedMultiplier = 0.55f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "CombatMove")
	float HeavyWindupMoveSpeedMultiplier = 0.4f;
};
