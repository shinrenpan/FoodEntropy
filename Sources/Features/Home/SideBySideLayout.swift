import CoreGraphics

// 首頁兩欄的欄寬計算（見 home-ui〈A wide container shows settings beside the home screen〉）。
// 純值型別：輸入外層提供的空間與直向折線，輸出是否兩欄與各欄寬度，方便單元測試。
//
// - 不寬（高 ≥ 寬）：只有首頁一欄。
// - 折線啟用（半開）：兩欄停在折線兩側，讓出折線寬度。
// - 折線未啟用（平放）：分界在折線中央。不用容器寬的一半——容器扣掉了右側垂直 bar，
//   一半不等於實體折線，半開與全開切換時卡牌欄會一次跳約 60pt（實測）。
// - 沒有折線，或折線碰到容器邊緣（分割畫面時只剩一條細縫）：各占一半。
struct SideBySideLayout: Equatable {
    let isSideBySide: Bool
    let leadingWidth: CGFloat
    let gap: CGFloat
    let trailingWidth: CGFloat

    /// 是否兩欄的唯一出處。推入的設定頁在變寬時退回（SettingsHostController）用的也是
    /// 這個判斷，兩處必須一致。只看寬高、不看 size class：Duo 外螢幕橫放（678×466，
    /// compact）也算寬，目前靠直立鎖定碰不到；若解除鎖定，這裡要加上 size class。
    static func isWide(_ size: CGSize) -> Bool {
        size.width > size.height
    }

    init(size: CGSize, fold: (frame: CGRect, isActive: Bool)?) {
        guard Self.isWide(size) else {
            isSideBySide = false
            leadingWidth = 0
            gap = 0
            trailingWidth = size.width
            return
        }
        isSideBySide = true

        if let fold, fold.frame.minX > 0, fold.frame.maxX < size.width {
            if fold.isActive {
                leadingWidth = fold.frame.minX
                gap = fold.frame.width
                trailingWidth = size.width - fold.frame.maxX
            } else {
                leadingWidth = fold.frame.midX
                gap = 0
                trailingWidth = size.width - fold.frame.midX
            }
        } else {
            leadingWidth = size.width / 2
            gap = 0
            trailingWidth = size.width / 2
        }
    }
}
