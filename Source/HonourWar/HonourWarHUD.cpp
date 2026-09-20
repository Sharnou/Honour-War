#include "HonourWarHUD.h"
#include "HonourWarHUDWidget.h"

void AHonourWarHUD::BeginPlay()
{
    Super::BeginPlay();
    if (APlayerController* PC=GetOwningPlayerController())
    {
        RuntimeWidget=CreateWidget<UHonourWarHUDWidget>(PC,UHonourWarHUDWidget::StaticClass());
        if (RuntimeWidget) RuntimeWidget->AddToViewport(100);
    }
}
