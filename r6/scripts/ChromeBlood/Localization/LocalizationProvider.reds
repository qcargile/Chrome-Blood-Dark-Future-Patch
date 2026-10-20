module ChromeBlood.Localization

import Codeware.Localization.*

public class CBBDFLocalizationProvider extends ModLocalizationProvider {
    public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
        switch language {
            case n"en-us": return new CBBDFEnglish();
            default: return null;
        }
    }

    public func GetFallback() -> CName {
        return n"en-us";
    }
}
