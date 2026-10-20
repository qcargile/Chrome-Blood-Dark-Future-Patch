module ChromeBlood

import DarkFuture.Conditions.DFInjuryConditionSystem

@addMethod(ButtonHints)
public final func CBBDFAddButtonHintForCost(action: CName, label: CName, cost: Int32) -> Void {
    this.AddButtonHint(action, GetLocalizedTextByKey(label) + " (" + IntToString(cost) + ")€$");
}

@addMethod(RipperDocGameController)
private final func CBBDFTreatmentUnits() -> Int32 {
    let injurySystem: ref<DFInjuryConditionSystem> = DFInjuryConditionSystem.Get();
    let units: Int32 = Cast<Int32>(injurySystem.GetConditionLevel());

    if injurySystem.accumulatedPercentTowardNextLevel > 0.0 {
        return units + 1;
    }

    return units;
}

@addMethod(RipperDocGameController)
private final func CBBDFTreatmentCostPerUnit() -> Int32 {
    return 500;
}

@addMethod(RipperDocGameController)
private final func CBBDFTreatmentCost() -> Int32 {
    return this.CBBDFTreatmentUnits() * this.CBBDFTreatmentCostPerUnit();
}

@addMethod(RipperDocGameController)
private final func CBBDFTreatInjuries() -> Bool {
    let gameInstance: GameInstance = GetGameInstance();
    let injurySystem: ref<DFInjuryConditionSystem> = DFInjuryConditionSystem.Get();
    let units: Int32 = this.CBBDFTreatmentUnits();
    let cost: Int32 = this.CBBDFTreatmentCost();
    let player: wref<PlayerPuppet> = GetPlayer(gameInstance);
    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gameInstance);
    let vendor: wref<GameObject> = NotEquals(this.m_VendorDataManager.GetVendorName(), "") ? this.m_VendorDataManager.GetVendorInstance() : null;

    if units == 0 || !IsDefined(player) || !IsDefined(vendor) {
        return false;
    }

    if transactionSystem.GetItemQuantity(player, MarketSystem.Money()) < cost {
        return false;
    }

    transactionSystem.TransferItem(player, vendor, MarketSystem.Money(), cost);

    while injurySystem.GetConditionLevel() > 0u || injurySystem.accumulatedPercentTowardNextLevel > 0.0 {
        injurySystem.RestoreCondition(100.0);
    }

    let blackBoardDef: ref<UI_VendorDef> = GetAllBlackboardDefs().UI_Vendor;
    let blackBoard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gameInstance).Get(blackBoardDef);
    blackBoard.SignalVariant(blackBoardDef.VendorData);

    return true;
}

@wrapMethod(RipperDocGameController)
private final func SetButtonHints(toDefault: Bool, opt isClose: Bool) -> Void {
    wrappedMethod(toDefault, isClose);

    let injurySystem: ref<DFInjuryConditionSystem> = DFInjuryConditionSystem.Get();
    if Equals(this.m_screen, CyberwareScreenType.Ripperdoc) && injurySystem.GetSystemToggleSettingValue() && this.CBBDFTreatmentUnits() > 0 {
        this.m_buttonHintsController.CBBDFAddButtonHintForCost(n"cbb_df_treat_injuries", n"CBBDFRipperdocTreatment", this.CBBDFTreatmentCost());
    }
}

@wrapMethod(RipperDocGameController)
protected cb func OnReleaseInput(e: ref<inkPointerEvent>) -> Bool {
    let injurySystem: ref<DFInjuryConditionSystem> = DFInjuryConditionSystem.Get();
    if e.IsAction(n"cbb_df_treat_injuries") && Equals(this.m_screen, CyberwareScreenType.Ripperdoc) && injurySystem.GetSystemToggleSettingValue() && this.CBBDFTreatmentUnits() > 0 {
        if this.CBBDFTreatInjuries() {
            this.m_audioSystem.Play(n"ui_menu_onpress");
            this.m_audioSystem.Play(n"OnSell");
            this.m_buttonHintsController.RemoveButtonHint(n"cbb_df_treat_injuries");
        } else {
            let notification: ref<UIMenuNotificationEvent> = new UIMenuNotificationEvent();
            notification.m_notificationType = UIMenuNotificationType.VNotEnoughMoney;
            this.m_uiSystem.QueueEvent(notification);
        }
    }

    return wrappedMethod(e);
}
