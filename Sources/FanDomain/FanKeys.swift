import SMCKit

public enum FanKeys {
    public static let count = SMCKey("FNum")

    public static func actual(_ index: Int) -> SMCKey { SMCKey("F\(index)Ac") }
    public static func minRPM(_ index: Int) -> SMCKey { SMCKey("F\(index)Mn") }
    public static func maxRPM(_ index: Int) -> SMCKey { SMCKey("F\(index)Mx") }
    public static func mode(_ index: Int) -> SMCKey { SMCKey("F\(index)Md") }
    public static func target(_ index: Int) -> SMCKey { SMCKey("F\(index)Tg") }
}
