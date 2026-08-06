#include "Combat/CullingImpactFlash.h"
#include "Perf/CullingPerfBudgets.h"
#include "Components/StaticMeshComponent.h"
#include "Components/PointLightComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"

ACullingImpactFlash::ACullingImpactFlash()
{
	PrimaryActorTick.bCanEverTick = true;
	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
	Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Mesh->SetCastShadow(false);

	Light = CreateDefaultSubobject<UPointLightComponent>(TEXT("Light"));
	Light->SetupAttachment(Mesh);
	Light->SetIntensity(0.f);
	Light->SetAttenuationRadius(250.f);
	Light->SetCastShadows(false);
}

void ACullingImpactFlash::Configure(float Radius, const FLinearColor& Color, float LifetimeSeconds, bool bHeavy)
{
	Lifetime = CullingPerfBudgets::ClampedFlashTime(LifetimeSeconds);
	FlashColor = Color;
	StartScale = (Radius / 100.f) * (bHeavy ? 0.35f : 0.22f);
	EndScale = (Radius / 100.f) * (bHeavy ? 1.1f : 0.7f);
	SetActorScale3D(FVector(StartScale));

	if (!Mesh->GetStaticMesh())
	{
		if (UStaticMesh* Sphere = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere")))
		{
			Mesh->SetStaticMesh(Sphere);
		}
	}
	if (UMaterialInterface* BaseMat = LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")))
	{
		if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMat, this))
		{
			MID->SetVectorParameterValue(TEXT("Color"), FlashColor);
			MID->SetVectorParameterValue(TEXT("BaseColor"), FlashColor);
			Mesh->SetMaterial(0, MID);
		}
	}
	if (Light)
	{
		Light->SetLightColor(Color);
		Light->SetIntensity(bHeavy ? 8000.f : 4000.f);
		StartLightIntensity = bHeavy ? 8000.f : 4000.f;
	}
}

void ACullingImpactFlash::BeginPlay()
{
	Super::BeginPlay();
	// Configure may run after SpawnActor BeginPlay — ensure mesh if Configure not yet called
	if (Mesh && !Mesh->GetStaticMesh())
	{
		if (UStaticMesh* Sphere = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere")))
		{
			Mesh->SetStaticMesh(Sphere);
		}
	}
}

void ACullingImpactFlash::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	Age += DeltaSeconds;
	const float T = FMath::Clamp(Age / Lifetime, 0.f, 1.f);
	const float S = FMath::Lerp(StartScale, EndScale, T);
	SetActorScale3D(FVector(S));
	if (Light)
	{
		Light->SetIntensity(FMath::Lerp(StartLightIntensity, 0.f, T));
	}
	if (Age >= Lifetime)
	{
		Destroy();
	}
}
