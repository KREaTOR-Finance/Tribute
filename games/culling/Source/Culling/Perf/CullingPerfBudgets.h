#pragma once

#include "CoreMinimal.h"

/**
 * SYS-PERF: code truth dual of Content/Assets/Specs/CONSOLE_BUDGETS.md
 */
namespace CullingPerfBudgets
{
	// Frame — targets
	constexpr float TargetFps = 60.f;
	constexpr float MaxGpuMs = 16.6f;
	constexpr float MaxGameThreadMs = 8.f;
	constexpr int32 PreferredMaxDrawCalls = 2000;

	// Frame — hard floors (console)
	constexpr float HardMinFps = 45.f;
	constexpr float HardMaxGpuMs = 22.f;
	constexpr float HardMaxGameThreadMs = 12.f;
	constexpr int32 HardMaxDrawCalls = 3500;

	// Memory (MB)
	constexpr int32 MaxWorkingSetMb = 6144;
	constexpr int32 HardWorkingSetMb = 8192;

	// Art
	constexpr int32 MaxPlayerTrisLod0 = 50000;
	constexpr int32 MaxWeaponTrisLod0 = 8000;
	constexpr int32 MaxPropTrisLod0 = 5000;
	constexpr int32 MaxEnvModularTris = 15000;
	constexpr int32 MaxHeroTexture = 2048;
	constexpr int32 MaxPropTexture = 1024;

	// Slice runtime limits
	constexpr int32 MaxArenaStaticPieces = 24;
	constexpr float MaxImpactFlashLifetime = 0.2f;
	constexpr float DefaultLightFlashLife = 0.1f;
	constexpr float DefaultHeavyFlashLife = 0.14f;
	constexpr int32 MaxConcurrentImpactFlashes = 8;

	// Scalability (sg.*) values for Medium console floor
	constexpr int32 ScalabilityViewDistance = 2; // Medium
	constexpr int32 ScalabilityAntiAliasing = 2;
	constexpr int32 ScalabilityShadow = 2;
	constexpr int32 ScalabilityPostProcess = 2;
	constexpr int32 ScalabilityTexture = 2;
	constexpr int32 ScalabilityEffects = 2;
	constexpr int32 ScalabilityFoliage = 2;
	constexpr int32 ScalabilityShading = 2;

	inline float ClampedFlashLifetime(float Requested)
	{
		return FMath::Clamp(Requested, 0.05f, MaxImpactFlashLifetime);
	}

	inline FString BudgetSummary()
	{
		return FString::Printf(
			TEXT("Tribune budgets: target %gfps (hard>=%g) GT<=%gms/%gms draw<%d/%d RAM<%dMB/%dMB arena<%d flash<%.2fs x%d"),
			TargetFps, HardMinFps, MaxGameThreadMs, HardMaxGameThreadMs,
			PreferredMaxDrawCalls, HardMaxDrawCalls, MaxWorkingSetMb, HardWorkingSetMb,
			MaxArenaStaticPieces, MaxImpactFlashLifetime, MaxConcurrentImpactFlashes);
	}
}
