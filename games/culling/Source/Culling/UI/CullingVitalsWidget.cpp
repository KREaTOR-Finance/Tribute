#include "UI/CullingVitalsWidget.h"
#include "Combat/CullingCombatComponent.h"
#include "Combat/CullingWeaponProfile.h"
#include "AI/CullingDummyCharacter.h"
#include "Loadout/CullingLoadoutComponent.h"
#include "Loadout/CullingPerkDefinition.h"
#include "Meta/CullingMatchStats.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/ProgressBar.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Blueprint/WidgetTree.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"

TSharedRef<SWidget> UCullingVitalsWidget::RebuildWidget()
{
	EnsureTree();
	return Super::RebuildWidget();
}

void UCullingVitalsWidget::EnsureTree()
{
	if (!WidgetTree)
	{
		return;
	}
	if (RootCanvas)
	{
		return;
	}

	RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	UVerticalBox* LeftStack = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("LeftStack"));
	if (UCanvasPanelSlot* Slot = RootCanvas->AddChildToCanvas(LeftStack))
	{
		Slot->SetAnchors(FAnchors(0.f, 1.f, 0.f, 1.f));
		Slot->SetAlignment(FVector2D(0.f, 1.f));
		Slot->SetPosition(FVector2D(48.f, -48.f));
		Slot->SetAutoSize(true);
	}

	HealthText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("HealthText"));
	HealthText->SetText(FText::FromString(TEXT("HP")));
	HealthText->SetColorAndOpacity(FSlateColor(FLinearColor::White));
	LeftStack->AddChildToVerticalBox(HealthText);

	HealthBar = WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(), TEXT("HealthBar"));
	HealthBar->SetFillColorAndOpacity(FLinearColor(0.85f, 0.1f, 0.1f, 1.f));
	HealthBar->SetPercent(1.f);
	if (UVerticalBoxSlot* VS = Cast<UVerticalBoxSlot>(LeftStack->AddChild(HealthBar)))
	{
		VS->SetPadding(FMargin(0.f, 2.f, 0.f, 8.f));
		VS->SetSize(FSlateChildSize(ESlateSizeRule::Automatic));
	}
	HealthBar->SetDesiredSizeScale(FVector2D(2.2f, 1.2f));

	StaminaText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("StaminaText"));
	StaminaText->SetText(FText::FromString(TEXT("STA")));
	LeftStack->AddChildToVerticalBox(StaminaText);

	StaminaBar = WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(), TEXT("StaminaBar"));
	StaminaBar->SetFillColorAndOpacity(FLinearColor(0.12f, 0.55f, 0.9f, 1.f));
	StaminaBar->SetPercent(1.f);
	LeftStack->AddChildToVerticalBox(StaminaBar);
	StaminaBar->SetDesiredSizeScale(FVector2D(2.2f, 1.0f));

	WeaponText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("WeaponText"));
	WeaponText->SetColorAndOpacity(FSlateColor(FLinearColor(0.95f, 0.9f, 0.7f)));
	LeftStack->AddChildToVerticalBox(WeaponText);

	PerkText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PerkText"));
	PerkText->SetColorAndOpacity(FSlateColor(FLinearColor(0.7f, 0.95f, 0.75f)));
	LeftStack->AddChildToVerticalBox(PerkText);

	MetaText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("MetaText"));
	MetaText->SetColorAndOpacity(FSlateColor(FLinearColor(0.75f, 0.75f, 0.8f)));
	LeftStack->AddChildToVerticalBox(MetaText);

	// Enemy stack top-right
	UVerticalBox* RightStack = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("RightStack"));
	if (UCanvasPanelSlot* RSlot = RootCanvas->AddChildToCanvas(RightStack))
	{
		RSlot->SetAnchors(FAnchors(1.f, 0.f, 1.f, 0.f));
		RSlot->SetAlignment(FVector2D(1.f, 0.f));
		RSlot->SetPosition(FVector2D(-48.f, 48.f));
		RSlot->SetAutoSize(true);
	}
	EnemyText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("EnemyText"));
	EnemyText->SetText(FText::FromString(TEXT("ENEMY")));
	RightStack->AddChildToVerticalBox(EnemyText);
	EnemyHealthBar = WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(), TEXT("EnemyHealthBar"));
	EnemyHealthBar->SetFillColorAndOpacity(FLinearColor(0.8f, 0.2f, 0.05f, 1.f));
	EnemyHealthBar->SetPercent(1.f);
	RightStack->AddChildToVerticalBox(EnemyHealthBar);
	EnemyHealthBar->SetDesiredSizeScale(FVector2D(2.0f, 1.0f));
}

void UCullingVitalsWidget::NativeConstruct()
{
	Super::NativeConstruct();
	EnsureTree();
	SetIsFocusable(false);
}

void UCullingVitalsWidget::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTick(MyGeometry, InDeltaTime);
	SyncFromCombat();
}

void UCullingVitalsWidget::SyncFromCombat()
{
	APlayerController* PC = GetOwningPlayer();
	APawn* Pawn = PC ? PC->GetPawn() : nullptr;
	UCullingCombatComponent* Combat = Pawn ? Pawn->FindComponentByClass<UCullingCombatComponent>() : nullptr;
	if (Combat)
	{
		const float Hp = Combat->MaxHealth > 0.f ? Combat->Health / Combat->MaxHealth : 0.f;
		const float St = Combat->MaxStamina > 0.f ? Combat->Stamina / Combat->MaxStamina : 0.f;
		if (HealthBar) { HealthBar->SetPercent(Hp); }
		if (StaminaBar) { StaminaBar->SetPercent(St); }
		if (HealthText)
		{
			HealthText->SetText(FText::FromString(FString::Printf(TEXT("HP  %.0f / %.0f"), Combat->Health, Combat->MaxHealth)));
		}
		if (StaminaText)
		{
			StaminaText->SetText(FText::FromString(FString::Printf(TEXT("STA %.0f / %.0f"), Combat->Stamina, Combat->MaxStamina)));
		}
		if (WeaponText && Combat->WeaponProfile)
		{
			const FString Name = Combat->WeaponProfile->DisplayName.IsEmpty()
				? Combat->WeaponProfile->WeaponId.ToString()
				: Combat->WeaponProfile->DisplayName.ToString();
			WeaponText->SetText(FText::FromString(Name));
		}
		if (UCullingLoadoutComponent* Loadout = Pawn->FindComponentByClass<UCullingLoadoutComponent>())
		{
			if (PerkText)
			{
				const FString Perk = (Loadout->ActivePerk)
					? Loadout->ActivePerk->DisplayName.ToString()
					: TEXT("—");
				PerkText->SetText(FText::FromString(FString::Printf(TEXT("PERK %s  (4/5/6)"), *Perk)));
			}
		}
		if (UCullingMatchStats* Stats = Pawn->FindComponentByClass<UCullingMatchStats>())
		{
			if (MetaText)
			{
				MetaText->SetText(FText::FromString(Stats->BuildSummaryLine()));
			}
		}
	}

	if (UWorld* World = GetWorld())
	{
		float Best = -1.f;
		float BestMax = 100.f;
		for (TActorIterator<ACullingDummyCharacter> It(World); It; ++It)
		{
			if (It->Combat && It->Combat->MaxHealth > 0.f)
			{
				Best = It->Combat->Health;
				BestMax = It->Combat->MaxHealth;
				break;
			}
		}
		if (Best >= 0.f)
		{
			if (EnemyHealthBar) { EnemyHealthBar->SetPercent(Best / BestMax); }
			if (EnemyText)
			{
				EnemyText->SetText(FText::FromString(FString::Printf(TEXT("ENEMY  %.0f"), Best)));
			}
		}
	}
}
