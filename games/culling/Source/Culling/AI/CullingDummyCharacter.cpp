#include "AI/CullingDummyCharacter.h"
#include "Combat/CullingCombatComponent.h"
#include "Combat/CullingCombatFeedback.h"
#include "Combat/CullingWeaponProfile.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Culling.h"

ACullingDummyCharacter::ACullingDummyCharacter()
{
	PrimaryActorTick.bCanEverTick = true;

	GetCapsuleComponent()->InitCapsuleSize(42.f, 96.f);
	GetCharacterMovement()->MaxWalkSpeed = 0.f;
	GetCharacterMovement()->bOrientRotationToMovement = false;
	bUseControllerRotationYaw = false;

	Combat = CreateDefaultSubobject<UCullingCombatComponent>(TEXT("Combat"));
	Feedback = CreateDefaultSubobject<UCullingCombatFeedback>(TEXT("Feedback"));

	// Readable enemy body — engine sphere stack (no Content mesh required)
	BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
	BodyMesh->SetupAttachment(GetCapsuleComponent());
	BodyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	BodyMesh->SetRelativeLocation(FVector(0.f, 0.f, -40.f));
	BodyMesh->SetRelativeScale3D(FVector(0.7f, 0.7f, 1.6f));
}

void ACullingDummyCharacter::BeginPlay()
{
	Super::BeginPlay();
	SpawnLocation = GetActorLocation();
	SpawnRotation = GetActorRotation();
	SparCountdown = SparIntervalSeconds * 0.5f;
	ResetCountdown = -1.f;
	SparStep = 0;

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
				// Hostile red — enemy readability
				MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.75f, 0.08f, 0.05f));
				MID->SetVectorParameterValue(TEXT("BaseColor"), FLinearColor(0.75f, 0.08f, 0.05f));
				BodyMesh->SetMaterial(0, MID);
			}
		}
	}

	if (Combat && !Combat->WeaponProfile)
	{
		UCullingWeaponProfile* Prof = NewObject<UCullingWeaponProfile>(this, TEXT("DummyFist"));
		Prof->WeaponId = FName(TEXT("dummy_fist"));
		Prof->LightDamage = 8.f;
		Prof->HeavyDamage = 18.f;
		Prof->LightRange = 130.f;
		Prof->HeavyWindupSeconds = 0.55f;
		Prof->LightStaminaCost = 5.f;
		Prof->HeavyStaminaCost = 14.f;
		Prof->LightHitstopSeconds = 0.04f;
		Prof->HeavyHitstopSeconds = 0.08f;
		Prof->HitSphereRadius = 35.f;
		Combat->WeaponProfile = Prof;
	}

	Tags.AddUnique(FName(TEXT("Dummy")));
	Tags.AddUnique(FName(TEXT("Enemy")));

	if (Combat)
	{
		Combat->OnMeleeStateChanged.AddDynamic(this, &ACullingDummyCharacter::HandleMeleeStateChanged);
	}
}

void ACullingDummyCharacter::HandleMeleeStateChanged(ECullingMeleeState NewState)
{
	ApplyStateTelegraph(NewState);
}

void ACullingDummyCharacter::ApplyStateTelegraph(ECullingMeleeState NewState)
{
	if (!BodyMesh)
	{
		return;
	}
	// Scale + recolor body so heavy windup is readable even with MaxWalkSpeed 0
	switch (NewState)
	{
	case ECullingMeleeState::HeavyWindup:
		BodyMesh->SetRelativeScale3D(BodyBaseScale * FVector(1.25f, 1.25f, 1.05f));
		if (UMaterialInstanceDynamic* MID = Cast<UMaterialInstanceDynamic>(BodyMesh->GetMaterial(0)))
		{
			MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(1.f, 0.4f, 0.05f));
			MID->SetVectorParameterValue(TEXT("BaseColor"), FLinearColor(1.f, 0.4f, 0.05f));
		}
		break;
	case ECullingMeleeState::HeavyActive:
	case ECullingMeleeState::LightActive:
		BodyMesh->SetRelativeScale3D(BodyBaseScale * FVector(1.1f, 1.1f, 1.f));
		if (UMaterialInstanceDynamic* MID = Cast<UMaterialInstanceDynamic>(BodyMesh->GetMaterial(0)))
		{
			MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(1.f, 0.2f, 0.05f));
			MID->SetVectorParameterValue(TEXT("BaseColor"), FLinearColor(1.f, 0.2f, 0.05f));
		}
		break;
	default:
		BodyMesh->SetRelativeScale3D(BodyBaseScale);
		if (UMaterialInstanceDynamic* MID = Cast<UMaterialInstanceDynamic>(BodyMesh->GetMaterial(0)))
		{
			MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.75f, 0.08f, 0.05f));
			MID->SetVectorParameterValue(TEXT("BaseColor"), FLinearColor(0.75f, 0.08f, 0.05f));
		}
		break;
	}
}

void ACullingDummyCharacter::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (!Combat)
	{
		return;
	}

	if (!Combat->IsAlive())
	{
		if (bResetOnDeath)
		{
			if (ResetCountdown < 0.f)
			{
				ResetCountdown = ResetDelaySeconds;
			}
			ResetCountdown -= DeltaSeconds;
			if (ResetCountdown <= 0.f)
			{
				ResetDummy();
			}
		}
		return;
	}

	ResetCountdown = -1.f;

	if (bAutoSpar)
	{
		SparCountdown -= DeltaSeconds;
		if (SparCountdown <= 0.f)
		{
			if (UWorld* World = GetWorld())
			{
				if (APlayerController* PC = World->GetFirstPlayerController())
				{
					if (APawn* P = PC->GetPawn())
					{
						const FVector To = P->GetActorLocation() - GetActorLocation();
						SetActorRotation(FRotator(0.f, To.Rotation().Yaw, 0.f));
					}
				}
			}

			if ((SparStep++ % 3) == 2)
			{
				Combat->TryStartHeavy();
			}
			else
			{
				Combat->TryLightAttack();
			}
			SparCountdown = SparIntervalSeconds;
		}
	}
}

void ACullingDummyCharacter::ResetDummy()
{
	if (!Combat)
	{
		return;
	}
	SetActorLocationAndRotation(SpawnLocation, SpawnRotation, false, nullptr, ETeleportType::ResetPhysics);
	Combat->ForceRevive();
	ResetCountdown = -1.f;
	SparCountdown = SparIntervalSeconds;
	UE_LOG(LogCulling, Log, TEXT("Dummy reset"));
}
