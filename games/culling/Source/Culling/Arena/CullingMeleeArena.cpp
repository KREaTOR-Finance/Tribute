#include "Arena/CullingMeleeArena.h"
#include "AI/CullingDummyCharacter.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Perf/CullingPerfBudgets.h"
#include "Culling.h"

ACullingMeleeArena::ACullingMeleeArena()
{
	PrimaryActorTick.bCanEverTick = false;
	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	SetRootComponent(Root);
}

void ACullingMeleeArena::OnConstruction(const FTransform& Transform)
{
	Super::OnConstruction(Transform);
	BuildGeometry();
}

void ACullingMeleeArena::BeginPlay()
{
	Super::BeginPlay();
	if (!bBuilt)
	{
		BuildGeometry();
	}
	SpawnDummyIfNeeded();
}

FTransform ACullingMeleeArena::GetPlayerSpawnTransform() const
{
	return FTransform(FRotator(0.f, 90.f, 0.f), GetActorTransform().TransformPosition(PlayerSpawnLocal));
}

FTransform ACullingMeleeArena::GetDummySpawnTransform() const
{
	return FTransform(FRotator(0.f, -90.f, 0.f), GetActorTransform().TransformPosition(DummySpawnLocal));
}

UStaticMeshComponent* ACullingMeleeArena::AddBox(const FName& Name, const FVector& RelativeLoc, const FVector& Scale, const FLinearColor& Color)
{
	UStaticMeshComponent* Mesh = NewObject<UStaticMeshComponent>(this, Name);
	Mesh->SetupAttachment(Root);
	Mesh->SetRelativeLocation(RelativeLoc);
	Mesh->SetRelativeScale3D(Scale);
	Mesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	Mesh->SetCollisionObjectType(ECC_WorldStatic);
	Mesh->SetCollisionResponseToAllChannels(ECR_Block);
	Mesh->SetMobility(EComponentMobility::Static);
	Mesh->RegisterComponent();

	if (UStaticMesh* Cube = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube")))
	{
		Mesh->SetStaticMesh(Cube);
	}

	if (UMaterialInterface* BaseMat = LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")))
	{
		if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMat, this))
		{
			MID->SetVectorParameterValue(TEXT("Color"), Color);
			// Some engine materials use different param names; set both common ones
			MID->SetVectorParameterValue(TEXT("BaseColor"), Color);
			Mesh->SetMaterial(0, MID);
		}
	}

	Pieces.Add(Mesh);
	return Mesh;
}

void ACullingMeleeArena::BuildGeometry()
{
	// Clear previous runtime pieces if rebuilding
	for (UStaticMeshComponent* P : Pieces)
	{
		if (P)
		{
			P->DestroyComponent();
		}
	}
	Pieces.Reset();

	const float Half = FloorSizeCm * 0.5f;
	const float Thick = 20.f;
	// Engine cube is 100cm; scale so X/Y match floor
	const float FloorScaleXY = FloorSizeCm / 100.f;
	const float FloorScaleZ = 0.2f;

	// Floor
	AddBox(TEXT("Floor"), FVector(0.f, 0.f, -10.f), FVector(FloorScaleXY, FloorScaleXY, FloorScaleZ), FLinearColor(0.15f, 0.15f, 0.18f));

	// Walls (N S E W)
	const float WallScaleZ = WallHeightCm / 100.f;
	const float WallThickScale = Thick / 100.f;
	AddBox(TEXT("WallN"), FVector(0.f, Half, WallHeightCm * 0.5f), FVector(FloorScaleXY, WallThickScale, WallScaleZ), FLinearColor(0.25f, 0.22f, 0.2f));
	AddBox(TEXT("WallS"), FVector(0.f, -Half, WallHeightCm * 0.5f), FVector(FloorScaleXY, WallThickScale, WallScaleZ), FLinearColor(0.25f, 0.22f, 0.2f));
	AddBox(TEXT("WallE"), FVector(Half, 0.f, WallHeightCm * 0.5f), FVector(WallThickScale, FloorScaleXY, WallScaleZ), FLinearColor(0.22f, 0.22f, 0.25f));
	AddBox(TEXT("WallW"), FVector(-Half, 0.f, WallHeightCm * 0.5f), FVector(WallThickScale, FloorScaleXY, WallScaleZ), FLinearColor(0.22f, 0.22f, 0.25f));

	// Cover crates — spacing decisions
	const FLinearColor CrateColor(0.4f, 0.28f, 0.12f);
	AddBox(TEXT("Crate1"), FVector(-400.f, -200.f, 50.f), FVector(1.2f, 1.2f, 1.0f), CrateColor);
	AddBox(TEXT("Crate2"), FVector(450.f, 150.f, 50.f), FVector(1.0f, 1.5f, 1.0f), CrateColor);
	AddBox(TEXT("Crate3"), FVector(-150.f, 500.f, 75.f), FVector(1.5f, 1.0f, 1.5f), CrateColor);
	AddBox(TEXT("Crate4"), FVector(200.f, -550.f, 50.f), FVector(1.0f, 1.0f, 1.0f), CrateColor);
	AddBox(TEXT("Crate5"), FVector(600.f, -300.f, 40.f), FVector(0.8f, 2.0f, 0.8f), CrateColor);
	AddBox(TEXT("Crate6"), FVector(-600.f, 250.f, 40.f), FVector(2.0f, 0.8f, 0.8f), CrateColor);

	// Center pillar for orbit fights
	AddBox(TEXT("Pillar"), FVector(0.f, 0.f, 120.f), FVector(0.8f, 0.8f, 2.4f), FLinearColor(0.3f, 0.3f, 0.32f));

	bBuilt = true;
	if (Pieces.Num() > CullingPerfBudgets::MaxArenaStaticPieces)
	{
		UE_LOG(LogCulling, Warning, TEXT("MeleeArena pieces %d exceed budget %d"), Pieces.Num(), CullingPerfBudgets::MaxArenaStaticPieces);
	}
	UE_LOG(LogCulling, Log, TEXT("MeleeArena built: floor=%.0fcm walls=%.0fcm pieces=%d | %s"),
		FloorSizeCm, WallHeightCm, Pieces.Num(), *CullingPerfBudgets::BudgetSummary());
}

void ACullingMeleeArena::SpawnDummyIfNeeded()
{
	if (!bSpawnDummy || SpawnedDummy || !GetWorld())
	{
		return;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
	SpawnedDummy = GetWorld()->SpawnActor<ACullingDummyCharacter>(ACullingDummyCharacter::StaticClass(), GetDummySpawnTransform(), Params);
	if (SpawnedDummy)
	{
		UE_LOG(LogCulling, Log, TEXT("MeleeArena spawned training dummy"));
	}
}
