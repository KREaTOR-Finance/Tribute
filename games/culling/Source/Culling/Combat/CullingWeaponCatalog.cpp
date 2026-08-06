#include "Combat/CullingWeaponCatalog.h"
#include "Combat/CullingWeaponProfile.h"

UCullingWeaponProfile* UCullingWeaponCatalog::MakeFist(UObject* Outer)
{
	UCullingWeaponProfile* P = NewObject<UCullingWeaponProfile>(Outer, TEXT("WPN_Fist"));
	P->WeaponId = FName(TEXT("fist"));
	P->DisplayName = FText::FromString(TEXT("Fist"));
	P->LightDamage = 10.f;
	P->HeavyDamage = 24.f;
	P->LightRange = 130.f;
	P->HeavyRange = 140.f;
	P->LightActiveSeconds = 0.10f;
	P->LightRecoverySeconds = 0.22f;
	P->HeavyWindupSeconds = 0.38f;
	P->HeavyActiveSeconds = 0.12f;
	P->HeavyRecoverySeconds = 0.42f;
	P->LightStaminaCost = 6.f;
	P->HeavyStaminaCost = 16.f;
	P->LightHitstopSeconds = 0.04f;
	P->HeavyHitstopSeconds = 0.08f;
	P->LightCameraTrauma = 0.18f;
	P->HeavyCameraTrauma = 0.38f;
	P->HitSphereRadius = 32.f;
	P->VisualLengthCm = 35.f;
	P->VisualThickness = 0.18f;
	P->VisualColor = FLinearColor(0.85f, 0.75f, 0.55f);
	return P;
}

UCullingWeaponProfile* UCullingWeaponCatalog::MakeSword(UObject* Outer)
{
	UCullingWeaponProfile* P = NewObject<UCullingWeaponProfile>(Outer, TEXT("WPN_Sword"));
	P->WeaponId = FName(TEXT("sword"));
	P->DisplayName = FText::FromString(TEXT("Sword"));
	P->LightDamage = 14.f;
	P->HeavyDamage = 34.f;
	P->LightRange = 175.f;
	P->HeavyRange = 190.f;
	P->LightActiveSeconds = 0.12f;
	P->LightRecoverySeconds = 0.28f;
	P->HeavyWindupSeconds = 0.48f;
	P->HeavyActiveSeconds = 0.14f;
	P->HeavyRecoverySeconds = 0.55f;
	P->LightStaminaCost = 9.f;
	P->HeavyStaminaCost = 24.f;
	P->LightHitstopSeconds = 0.05f;
	P->HeavyHitstopSeconds = 0.10f;
	P->LightCameraTrauma = 0.24f;
	P->HeavyCameraTrauma = 0.5f;
	P->HitSphereRadius = 38.f;
	P->VisualLengthCm = 95.f;
	P->VisualThickness = 0.1f;
	P->VisualColor = FLinearColor(0.65f, 0.68f, 0.75f);
	return P;
}

UCullingWeaponProfile* UCullingWeaponCatalog::MakeAxe(UObject* Outer)
{
	UCullingWeaponProfile* P = NewObject<UCullingWeaponProfile>(Outer, TEXT("WPN_Axe"));
	P->WeaponId = FName(TEXT("axe"));
	P->DisplayName = FText::FromString(TEXT("Axe"));
	P->LightDamage = 16.f;
	P->HeavyDamage = 42.f;
	P->LightRange = 155.f;
	P->HeavyRange = 165.f;
	P->LightActiveSeconds = 0.14f;
	P->LightRecoverySeconds = 0.35f;
	P->HeavyWindupSeconds = 0.62f;
	P->HeavyActiveSeconds = 0.16f;
	P->HeavyRecoverySeconds = 0.72f;
	P->LightStaminaCost = 12.f;
	P->HeavyStaminaCost = 30.f;
	P->ShoveImpulse = 700.f;
	P->LightHitstopSeconds = 0.055f;
	P->HeavyHitstopSeconds = 0.12f;
	P->LightCameraTrauma = 0.28f;
	P->HeavyCameraTrauma = 0.6f;
	P->HitSphereRadius = 48.f;
	P->VisualLengthCm = 70.f;
	P->VisualThickness = 0.22f;
	P->VisualColor = FLinearColor(0.45f, 0.35f, 0.28f);
	return P;
}
