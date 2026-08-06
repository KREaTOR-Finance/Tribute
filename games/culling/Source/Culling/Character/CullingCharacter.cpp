#include "Character/CullingCharacter.h"
#include "Combat/CullingCombatComponent.h"
#include "Combat/CullingCombatFeedback.h"
#include "Movement/CullingMovementDefaults.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"
#include "Components/InputComponent.h"
#include "Culling.h"

ACullingCharacter::ACullingCharacter()
{
	PrimaryActorTick.bCanEverTick = true;

	bUseControllerRotationPitch = false;
	bUseControllerRotationYaw = false;
	bUseControllerRotationRoll = false;

	GetCharacterMovement()->bOrientRotationToMovement = true;
	GetCharacterMovement()->RotationRate = FRotator(0.f, 480.f, 0.f);

	CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
	CameraBoom->SetupAttachment(RootComponent);
	CameraBoom->TargetArmLength = 280.f;
	CameraBoom->bUsePawnControlRotation = true;
	CameraBoom->SocketOffset = FVector(0.f, 55.f, 55.f);
	CameraBoom->bEnableCameraLag = true;
	CameraBoom->CameraLagSpeed = 12.f;

	FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
	FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
	FollowCamera->bUsePawnControlRotation = false;

	Combat = CreateDefaultSubobject<UCullingCombatComponent>(TEXT("Combat"));
	Feedback = CreateDefaultSubobject<UCullingCombatFeedback>(TEXT("Feedback"));

	// CDO defaults: weighty move/camera even before data asset assignment
	GetCharacterMovement()->MaxWalkSpeed = 480.f;
	GetCharacterMovement()->MaxAcceleration = 1600.f;
	GetCharacterMovement()->BrakingDecelerationWalking = 1400.f;
	GetCharacterMovement()->GroundFriction = 8.f;
	GetCharacterMovement()->MaxStepHeight = 45.f;
}

// Note: Combat->Feedback is resolved in Combat BeginPlay via FindComponentByClass.

void ACullingCharacter::BeginPlay()
{
	Super::BeginPlay();
	ApplyMovementDefaults();
}

void ACullingCharacter::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	UpdateCombatMovementScalars();

	if (Feedback && CameraBoom && Feedback->CameraTrauma > 0.f)
	{
		const float T = Feedback->CameraTrauma;
		const float Shake = T * T * 6.f; // square for punchier peaks
		const float YawOff = FMath::Sin(GetWorld()->GetTimeSeconds() * 55.f) * Shake;
		const float PitchOff = FMath::Cos(GetWorld()->GetTimeSeconds() * 47.f) * Shake * 0.6f;
		CameraBoom->SetRelativeRotation(FRotator(PitchOff, YawOff, 0.f));
	}
	else if (CameraBoom)
	{
		CameraBoom->SetRelativeRotation(FRotator::ZeroRotator);
	}
}

void ACullingCharacter::ApplyMovementDefaults()
{
	// Built-in fallbacks so an unassigned data asset still yields a playable weighty feel (SYS-MOVE gap fix).
	float MaxWalk = 480.f;
	float Accel = 1600.f;
	float Brake = 1400.f;
	float Friction = 8.f;
	float RotYaw = 480.f;
	bool bOrient = true;
	float Arm = 280.f;
	FVector Socket(0.f, 55.f, 55.f);
	bool bLag = true;
	float LagSpeed = 12.f;

	if (MovementDefaults)
	{
		MaxWalk = MovementDefaults->MaxWalkSpeed;
		Accel = MovementDefaults->MaxAcceleration;
		Brake = MovementDefaults->BrakingDecelerationWalking;
		Friction = MovementDefaults->GroundFriction;
		RotYaw = MovementDefaults->RotationRateYaw;
		bOrient = MovementDefaults->bOrientRotationToMovement;
		Arm = MovementDefaults->CameraArmLength;
		Socket = MovementDefaults->CameraSocketOffset;
		bLag = MovementDefaults->bEnableCameraLag;
		LagSpeed = MovementDefaults->CameraLagSpeed;
	}

	UCharacterMovementComponent* Move = GetCharacterMovement();
	Move->MaxWalkSpeed = MaxWalk;
	Move->MaxAcceleration = Accel;
	Move->BrakingDecelerationWalking = Brake;
	Move->GroundFriction = Friction;
	Move->RotationRate = FRotator(0.f, RotYaw, 0.f);
	Move->bOrientRotationToMovement = bOrient;
	Move->NavAgentProps.bCanJump = false; // melee slice: no floaty jump-meta
	Move->SetWalkableFloorAngle(45.f);
	Move->MaxStepHeight = 45.f;

	CameraBoom->TargetArmLength = Arm;
	CameraBoom->SocketOffset = Socket;
	CameraBoom->bEnableCameraLag = bLag;
	CameraBoom->CameraLagSpeed = LagSpeed;
	CameraBoom->bDoCollisionTest = true;
}

void ACullingCharacter::UpdateCombatMovementScalars()
{
	if (!Combat)
	{
		return;
	}

	const float Base = MovementDefaults ? MovementDefaults->MaxWalkSpeed : 480.f;
	const float BlockMult = MovementDefaults ? MovementDefaults->BlockMoveSpeedMultiplier : 0.55f;
	const float HeavyMult = MovementDefaults ? MovementDefaults->HeavyWindupMoveSpeedMultiplier : 0.4f;

	float Mult = 1.f;
	switch (Combat->MeleeState)
	{
	case ECullingMeleeState::Blocking:
		Mult = BlockMult;
		break;
	case ECullingMeleeState::HeavyWindup:
	case ECullingMeleeState::HeavyActive:
		Mult = HeavyMult;
		break;
	default:
		break;
	}

	GetCharacterMovement()->MaxWalkSpeed = Base * Mult;
}

// Camera micro-shake from combat trauma (SYS-MOVE + SYS-JUICE bridge)
// Applied each tick after super.

void ACullingCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	// Axis/action names must exist in project Input config / Enhanced Input mapping
	PlayerInputComponent->BindAxis("MoveForward", this, &ACullingCharacter::MoveForward);
	PlayerInputComponent->BindAxis("MoveRight", this, &ACullingCharacter::MoveRight);
	PlayerInputComponent->BindAxis("LookYaw", this, &ACullingCharacter::LookYaw);
	PlayerInputComponent->BindAxis("LookPitch", this, &ACullingCharacter::LookPitch);

	PlayerInputComponent->BindAction("LightAttack", IE_Pressed, this, &ACullingCharacter::OnLightAttack);
	PlayerInputComponent->BindAction("HeavyAttack", IE_Pressed, this, &ACullingCharacter::OnHeavyPressed);
	PlayerInputComponent->BindAction("HeavyAttack", IE_Released, this, &ACullingCharacter::OnHeavyReleased);
	PlayerInputComponent->BindAction("Block", IE_Pressed, this, &ACullingCharacter::OnBlockPressed);
	PlayerInputComponent->BindAction("Block", IE_Released, this, &ACullingCharacter::OnBlockReleased);
	PlayerInputComponent->BindAction("Shove", IE_Pressed, this, &ACullingCharacter::OnShove);
}

void ACullingCharacter::MoveForward(float Value)
{
	if (Controller && Value != 0.f)
	{
		const FRotator Yaw(0.f, Controller->GetControlRotation().Yaw, 0.f);
		AddMovementInput(FRotationMatrix(Yaw).GetUnitAxis(EAxis::X), Value);
	}
}

void ACullingCharacter::MoveRight(float Value)
{
	if (Controller && Value != 0.f)
	{
		const FRotator Yaw(0.f, Controller->GetControlRotation().Yaw, 0.f);
		AddMovementInput(FRotationMatrix(Yaw).GetUnitAxis(EAxis::Y), Value);
	}
}

void ACullingCharacter::LookYaw(float Value)
{
	float Sens = MovementDefaults ? MovementDefaults->MouseSensitivityYaw : 1.f;
	AddControllerYawInput(Value * Sens);
}

void ACullingCharacter::LookPitch(float Value)
{
	float Sens = MovementDefaults ? MovementDefaults->MouseSensitivityPitch : 1.f;
	AddControllerPitchInput(Value * Sens);
}

void ACullingCharacter::OnLightAttack()
{
	if (Combat)
	{
		Combat->TryLightAttack();
	}
}

void ACullingCharacter::OnHeavyPressed()
{
	if (Combat)
	{
		Combat->TryStartHeavy();
	}
}

void ACullingCharacter::OnHeavyReleased()
{
	if (Combat)
	{
		Combat->ReleaseHeavy();
	}
}

void ACullingCharacter::OnBlockPressed()
{
	if (Combat)
	{
		Combat->TrySetBlocking(true);
	}
}

void ACullingCharacter::OnBlockReleased()
{
	if (Combat)
	{
		Combat->TrySetBlocking(false);
	}
}

void ACullingCharacter::OnShove()
{
	if (Combat)
	{
		Combat->TryShove();
	}
}
