#include "Character/CullingCharacter.h"
#include "Combat/CullingCombatComponent.h"
#include "Combat/CullingCombatFeedback.h"
#include "Combat/CullingWeaponCatalog.h"
#include "Combat/CullingWeaponProfile.h"
#include "Movement/CullingMovementDefaults.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"
#include "Components/InputComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/PointLightComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
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

	BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
	BodyMesh->SetupAttachment(GetCapsuleComponent());
	BodyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	BodyMesh->SetRelativeLocation(FVector(0.f, 0.f, -40.f));
	BodyMesh->SetRelativeScale3D(FVector(0.65f, 0.65f, 1.55f));

	WeaponMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("WeaponMesh"));
	WeaponMesh->SetupAttachment(BodyMesh);
	WeaponMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	WeaponMesh->SetRelativeLocation(FVector(35.f, 20.f, 30.f));
	WeaponMesh->SetRelativeRotation(FRotator(0.f, 0.f, 80.f));

	TelegraphLight = CreateDefaultSubobject<UPointLightComponent>(TEXT("TelegraphLight"));
	TelegraphLight->SetupAttachment(GetCapsuleComponent());
	TelegraphLight->SetRelativeLocation(FVector(0.f, 0.f, 90.f));
	TelegraphLight->SetIntensity(0.f);
	TelegraphLight->SetAttenuationRadius(280.f);
	TelegraphLight->SetCastShadows(false);

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
	InitDefaultWeapons();
	SelectWeaponSlot(1); // default sword — Culling mid tool fantasy

	if (BodyMesh)
	{
		if (UStaticMesh* Sphere = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere")))
		{
			BodyMesh->SetStaticMesh(Sphere);
		}
		if (UMaterialInterface* BaseMat = LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")))
		{
			if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMat, this))
			{
				// Hunter blue-grey silhouette
				MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.25f, 0.4f, 0.65f));
				MID->SetVectorParameterValue(TEXT("BaseColor"), FLinearColor(0.25f, 0.4f, 0.65f));
				BodyMesh->SetMaterial(0, MID);
			}
		}
	}

	if (Combat)
	{
		Combat->OnMeleeStateChanged.AddDynamic(this, &ACullingCharacter::HandleMeleeStateChanged);
		ApplyStateTelegraph(Combat->MeleeState);
	}
}

void ACullingCharacter::HandleMeleeStateChanged(ECullingMeleeState NewState)
{
	ApplyStateTelegraph(NewState);
}

void ACullingCharacter::ApplyStateTelegraph(ECullingMeleeState NewState)
{
	if (!TelegraphLight)
	{
		return;
	}

	switch (NewState)
	{
	case ECullingMeleeState::HeavyWindup:
		// Readable commit — warm charge light (punish window)
		TelegraphLight->SetLightColor(FLinearColor(1.f, 0.45f, 0.05f));
		TelegraphLight->SetIntensity(12000.f);
		if (WeaponMesh)
		{
			WeaponMesh->SetRelativeScale3D(WeaponMesh->GetRelativeScale3D() * FVector(1.f, 1.f, 1.15f));
		}
		break;
	case ECullingMeleeState::HeavyActive:
	case ECullingMeleeState::LightActive:
		TelegraphLight->SetLightColor(FLinearColor(1.f, 0.9f, 0.4f));
		TelegraphLight->SetIntensity(6000.f);
		break;
	case ECullingMeleeState::Blocking:
		TelegraphLight->SetLightColor(FLinearColor(0.3f, 0.55f, 1.f));
		TelegraphLight->SetIntensity(4500.f);
		break;
	case ECullingMeleeState::Shoving:
		TelegraphLight->SetLightColor(FLinearColor(0.9f, 0.9f, 1.f));
		TelegraphLight->SetIntensity(5000.f);
		break;
	default:
		TelegraphLight->SetIntensity(0.f);
		RefreshWeaponVisual(); // restore weapon scale after windup boost
		break;
	}
}

void ACullingCharacter::InitDefaultWeapons()
{
	WeaponSlots.Reset();
	WeaponSlots.Add(UCullingWeaponCatalog::MakeFist(this));
	WeaponSlots.Add(UCullingWeaponCatalog::MakeSword(this));
	WeaponSlots.Add(UCullingWeaponCatalog::MakeAxe(this));
}

void ACullingCharacter::SelectWeaponSlot(int32 SlotIndex)
{
	if (!Combat || WeaponSlots.Num() == 0)
	{
		return;
	}
	const int32 Idx = FMath::Clamp(SlotIndex, 0, WeaponSlots.Num() - 1);
	ActiveWeaponSlot = Idx;
	Combat->WeaponProfile = WeaponSlots[Idx];
	RefreshWeaponVisual();
	UE_LOG(LogCulling, Log, TEXT("Weapon slot %d -> %s"), Idx,
		Combat->WeaponProfile ? *Combat->WeaponProfile->WeaponId.ToString() : TEXT("null"));
}

void ACullingCharacter::RefreshWeaponVisual()
{
	if (!WeaponMesh || !Combat || !Combat->WeaponProfile)
	{
		return;
	}
	UCullingWeaponProfile* P = Combat->WeaponProfile;
	if (!WeaponMesh->GetStaticMesh())
	{
		if (UStaticMesh* Cube = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube")))
		{
			WeaponMesh->SetStaticMesh(Cube);
		}
	}
	// Cube is 100cm; scale to stick: thin X/Y, long Z
	const float Len = FMath::Max(20.f, P->VisualLengthCm) / 100.f;
	const float Thick = FMath::Max(0.05f, P->VisualThickness);
	WeaponMesh->SetRelativeScale3D(FVector(Thick, Thick, Len));
	if (UMaterialInterface* BaseMat = LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")))
	{
		if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMat, this))
		{
			MID->SetVectorParameterValue(TEXT("Color"), P->VisualColor);
			MID->SetVectorParameterValue(TEXT("BaseColor"), P->VisualColor);
			WeaponMesh->SetMaterial(0, MID);
		}
	}
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
	PlayerInputComponent->BindAction("Weapon1", IE_Pressed, this, &ACullingCharacter::OnWeapon1);
	PlayerInputComponent->BindAction("Weapon2", IE_Pressed, this, &ACullingCharacter::OnWeapon2);
	PlayerInputComponent->BindAction("Weapon3", IE_Pressed, this, &ACullingCharacter::OnWeapon3);
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

void ACullingCharacter::OnWeapon1() { SelectWeaponSlot(0); }
void ACullingCharacter::OnWeapon2() { SelectWeaponSlot(1); }
void ACullingCharacter::OnWeapon3() { SelectWeaponSlot(2); }
