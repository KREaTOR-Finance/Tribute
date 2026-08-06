#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "CullingVitalsWidget.generated.h"

class UProgressBar;
class UTextBlock;
class UCanvasPanel;
class UCullingCombatComponent;

/** SYS-UI: pure C++ UMG vitals (no widget Blueprint asset required). */
UCLASS()
class CULLING_API UCullingVitalsWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual void NativeConstruct() override;
	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;

	void EnsureTree();
	void SyncFromCombat();

	UPROPERTY()
	TObjectPtr<UCanvasPanel> RootCanvas;

	UPROPERTY()
	TObjectPtr<UProgressBar> HealthBar;

	UPROPERTY()
	TObjectPtr<UProgressBar> StaminaBar;

	UPROPERTY()
	TObjectPtr<UTextBlock> HealthText;

	UPROPERTY()
	TObjectPtr<UTextBlock> StaminaText;

	UPROPERTY()
	TObjectPtr<UTextBlock> WeaponText;

	UPROPERTY()
	TObjectPtr<UProgressBar> EnemyHealthBar;

	UPROPERTY()
	TObjectPtr<UTextBlock> EnemyText;
};
