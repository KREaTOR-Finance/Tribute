#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "CullingWeaponCatalog.generated.h"

class UCullingWeaponProfile;

/** SYS-WEAPON: builds distinct runtime profiles when Content DAs are absent. */
UCLASS()
class CULLING_API UCullingWeaponCatalog : public UObject
{
	GENERATED_BODY()

public:
	static UCullingWeaponProfile* MakeFist(UObject* Outer);
	static UCullingWeaponProfile* MakeSword(UObject* Outer);
	static UCullingWeaponProfile* MakeAxe(UObject* Outer);
};
