#include "Meta/CullingMatchStats.h"

UCullingMatchStats::UCullingMatchStats()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void UCullingMatchStats::TickComponent(float DeltaTime, ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	MatchTimeSeconds += DeltaTime;
}

void UCullingMatchStats::RecordDamageDealt(float Amount)
{
	DamageDealt += Amount;
	OnStatChanged.Broadcast(FName(TEXT("DamageDealt")));
}

void UCullingMatchStats::RecordDamageTaken(float Amount)
{
	DamageTaken += Amount;
	OnStatChanged.Broadcast(FName(TEXT("DamageTaken")));
}

void UCullingMatchStats::RecordKill()
{
	Kills += 1;
	OnStatChanged.Broadcast(FName(TEXT("Kills")));
}

void UCullingMatchStats::RecordDeath()
{
	Deaths += 1;
	OnStatChanged.Broadcast(FName(TEXT("Deaths")));
}

void UCullingMatchStats::RecordHit()
{
	HitsLanded += 1;
	OnStatChanged.Broadcast(FName(TEXT("Hits")));
}

FString UCullingMatchStats::BuildSummaryLine() const
{
	return FString::Printf(
		TEXT("TIME %.0fs | KILLS %d | DEATHS %d | HITS %d | DMG %.0f/%.0f"),
		MatchTimeSeconds, Kills, Deaths, HitsLanded, DamageDealt, DamageTaken);
}
